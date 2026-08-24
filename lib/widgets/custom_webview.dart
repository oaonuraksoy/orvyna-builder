import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/app_config.dart';
import '../services/adblock_service.dart';
import '../services/deeplink_service.dart';
import '../services/permission_service.dart';
import 'shimmer_loading.dart';
import 'offline_screen.dart';

/// Dinamik Shimmer, AdBlock, DeepLink, Zero CLS & FOUC Önleme ve İzin destekli gelişmiş WebView bileşeni
class CustomWebView extends StatefulWidget {
  final AppConfig config;
  final AdBlockService adBlockService;
  final DeepLinkService deepLinkService;
  final PermissionService permissionService;
  final VoidCallback? onPageNavigated;
  final ValueChanged<String>? onCustomPageRequested;

  const CustomWebView({
    super.key,
    required this.config,
    required this.adBlockService,
    required this.deepLinkService,
    required this.permissionService,
    this.onPageNavigated,
    this.onCustomPageRequested,
  });

  @override
  State<CustomWebView> createState() => CustomWebViewState();
}

class CustomWebViewState extends State<CustomWebView> {
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;

  double _loadingProgress = 0.0;
  bool _isContentReady = false; // Zero CLS & FOUC: DOM ve CSS tam yüklenene kadar opaklık 0
  bool _hasError = false;
  Timer? _foucSafetyTimer;

  static const String _viewportJsScript = r'''
  (function() {
    if (!document.querySelector('meta[name="viewport"]')) {
      var meta = document.createElement('meta');
      meta.name = 'viewport';
      meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
      var target = document.head || document.getElementsByTagName('head')[0] || document.documentElement || document.body;
      if (target) target.appendChild(meta);
    }
  })();
  ''';

  @override
  void initState() {
    super.initState();
    _initializePullToRefresh();
  }

  @override
  void dispose() {
    _foucSafetyTimer?.cancel();
    super.dispose();
  }

  void _initializePullToRefresh() {
    if (widget.config.webviewSettings.pullToRefresh &&
        (Platform.isAndroid || Platform.isIOS)) {
      pullToRefreshController = PullToRefreshController(
        settings: PullToRefreshSettings(
          color: widget.config.theme.primaryColor,
          backgroundColor: widget.config.theme.backgroundColor,
        ),
        onRefresh: () async {
          try {
            if (Platform.isAndroid) {
              await webViewController?.reload();
            } else if (Platform.isIOS) {
              final currentUrl = await webViewController?.getUrl();
              if (currentUrl != null) {
                await webViewController?.loadUrl(
                  urlRequest: URLRequest(url: currentUrl),
                );
              }
            }
          } catch (e) {
            debugPrint('[CustomWebView] onRefresh error: $e');
          }
        },
      );
    }
  }

  /// Harici URL yükleme metodu (Örn: OneSignal bildiriminden tetiklenen)
  Future<void> loadUrl(String urlString) async {
    try {
      if (urlString.startsWith('custom://')) {
        widget.onCustomPageRequested?.call(urlString);
        return;
      }
      final uri = WebUri(urlString);
      await webViewController?.loadUrl(urlRequest: URLRequest(url: uri));
    } catch (e) {
      debugPrint('[CustomWebView] loadUrl error: $e');
    }
  }

  /// Geri navigasyon kontrolü
  Future<bool> canGoBack() async {
    try {
      return (await webViewController?.canGoBack()) ?? false;
    } catch (e) {
      debugPrint('[CustomWebView] canGoBack error: $e');
      return false;
    }
  }

  Future<void> goBack() async {
    try {
      await webViewController?.goBack();
    } catch (e) {
      debugPrint('[CustomWebView] goBack error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return OfflineScreen(
        config: widget.config.offlineSettings,
        theme: widget.config.theme,
        onRetry: () {
          setState(() {
            _hasError = false;
            _isContentReady = false;
          });
          try {
            webViewController?.reload();
          } catch (e) {
            debugPrint('[CustomWebView] reload error: $e');
          }
        },
      );
    }

    final effectiveUserAgent = widget.config.appInfo.userAgent.isNotEmpty
        ? widget.config.appInfo.userAgent
        : AppInfoConfig.defaultMobileUserAgent;

    final initialUrl = widget.config.appInfo.webUrl.isNotEmpty
        ? widget.config.appInfo.webUrl
        : 'https://flutter.dev';

    return Stack(
      children: [
        // 1. Ana InAppWebView (Sıfır CLS ve FOUC için DOM ve CSS enjeksiyonu tamamlanana kadar 0 opaklık)
        AnimatedOpacity(
          opacity: _isContentReady ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(initialUrl),
            ),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              useShouldInterceptRequest: widget.config.adblockSettings.enabled,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              javaScriptEnabled: widget.config.webviewSettings.enableJavascript,
              domStorageEnabled: widget.config.webviewSettings.enableDomStorage,
              geolocationEnabled: widget.config.webviewSettings.enableGeolocation,
              clearCache: widget.config.webviewSettings.clearCacheOnLaunch,
              userAgent: effectiveUserAgent,
              supportMultipleWindows: false,
              transparentBackground: true,
              disallowOverScroll: widget.config.webviewSettings.disallowOverScroll,
              supportZoom: widget.config.webviewSettings.supportZoom,
              disableHorizontalScroll: false,
              allowsBackForwardNavigationGestures: true,
            ),
            gestureRecognizers: {
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
              Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            },
            pullToRefreshController: pullToRefreshController,
            onWebViewCreated: (controller) {
              webViewController = controller;
              _setupJavaScriptHandlers(controller);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;
              if (uri != null && uri.scheme == 'custom') {
                widget.onCustomPageRequested?.call(uri.toString());
                return NavigationActionPolicy.CANCEL;
              }
              final handled = await widget.deepLinkService.handleNavigationRequest(navigationAction);
              if (handled) {
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            shouldInterceptRequest: (controller, request) async {
              if (widget.adBlockService.isUrlBlocked(request.url)) {
                // Reklam veya izleyici isteğini sıfır bayt ile engelle
                return WebResourceResponse(
                  contentType: 'text/plain',
                  data: Uint8List(0),
                  statusCode: 200,
                  reasonPhrase: 'OK',
                );
              }
              return null;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isContentReady = false;
              });
              widget.onPageNavigated?.call();

              // FOUC Güvenlik Zamanlayıcısı: 4.5 saniye sonra içerik takılırsa zorla göster
              _foucSafetyTimer?.cancel();
              _foucSafetyTimer = Timer(const Duration(milliseconds: 4500), () {
                if (mounted && !_isContentReady) {
                  setState(() {
                    _isContentReady = true;
                  });
                }
              });
            },
            onProgressChanged: (controller, progress) {
              final progressNormalized = progress / 100.0;
              setState(() {
                _loadingProgress = progressNormalized;
                if (progress >= 85 && !_isContentReady) {
                  _isContentReady = true;
                }
              });

              pullToRefreshController?.endRefreshing();

              // Kozmetik filtreyi sayfa yüklenirken erken enjekte et
              try {
                widget.adBlockService.injectCosmeticFilter(controller);
              } catch (e) {
                debugPrint('[CustomWebView] injectCosmeticFilter error: $e');
              }
            },
            onLoadStop: (controller, url) async {
              pullToRefreshController?.endRefreshing();
              _foucSafetyTimer?.cancel();

              try {
                // Kozmetik CSS & Özel Script enjeksiyonu
                await widget.adBlockService.injectCosmeticFilter(controller);
                await _injectCustomAssets(controller);
              } catch (e) {
                debugPrint('[CustomWebView] onLoadStop error: $e');
              }

              if (mounted) {
                setState(() {
                  _isContentReady = true;
                  _loadingProgress = 1.0;
                });
              }
            },
            onReceivedError: (controller, request, error) {
              pullToRefreshController?.endRefreshing();
              _foucSafetyTimer?.cancel();
              // Ana sayfa yüklenemiyorsa offline ekranını tetikle
              if (request.isForMainFrame ?? true) {
                setState(() {
                  _hasError = true;
                });
                debugPrint('[CustomWebView] Sayfa yükleme hatası: ${error.description}');
              }
            },
            onPermissionRequest: (controller, permissionRequest) async {
              return await widget.permissionService.handleWebPermissionRequest(permissionRequest);
            },
            onGeolocationPermissionsShowPrompt: (controller, origin) async {
              return await widget.permissionService.handleGeolocationPrompt(origin);
            },
          ),
        ),

        // 2. Shimmer Skeleton Yükleme Ekranı (Zero CLS: 300ms Smooth Cross-Fade)
        IgnorePointer(
          ignoring: _isContentReady,
          child: AnimatedOpacity(
            opacity: _isContentReady ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: ShimmerLoadingView(theme: widget.config.theme),
          ),
        ),

        // 3. Üst İlerleme Çubuğu (Progress Indicator)
        if (widget.config.webviewSettings.showProgressBar && _loadingProgress < 1.0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadingProgress,
              minHeight: 3.0,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.config.theme.accentColor,
              ),
            ),
          ),
      ],
    );
  }

  /// JS Köprüsü ve Native İletişim Kanalları (Web2App JS API)
  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    // 1. Ana FlutterBridge İşleyicisi
    controller.addJavaScriptHandler(
      handlerName: 'FlutterBridge',
      callback: (args) async {
        debugPrint('[JSBridge] Webden çağrı alındı: $args');
        if (args.isNotEmpty && args[0] is Map) {
          final data = args[0] as Map<dynamic, dynamic>;
          final action = data['action']?.toString();

          if (action == 'reload') {
            try {
              await controller.reload();
              return {'status': 'success', 'action': 'reload'};
            } catch (e) {
              debugPrint('[JSBridge] reload error: $e');
            }
          } else if (action == 'logEvent') {
            final eventName = data['eventName']?.toString() ?? data['name']?.toString() ?? 'custom_event';
            final params = data['params'] ?? data['data'] ?? {};
            debugPrint('[JSBridge - Analytics Event] Event: $eventName, Data: $params');
            return {'status': 'success', 'action': 'logEvent', 'event': eventName};
          } else if (action == 'setBadge') {
            final count = (data['count'] as num?)?.toInt() ?? 0;
            final targetId = data['id']?.toString();
            debugPrint('[JSBridge - SetBadge] Target: $targetId, Count: $count');
            return {'status': 'success', 'action': 'setBadge', 'count': count};
          } else if (action == 'requestReview') {
            debugPrint('[JSBridge - RequestReview] In-App Review tetiklendi');
            return {'status': 'success', 'action': 'requestReview'};
          } else if (action == 'share') {
            final title = data['title']?.toString() ?? '';
            final text = data['text']?.toString() ?? '';
            final url = data['url']?.toString() ?? '';
            debugPrint('[JSBridge - Share] Title: $title, Text: $text, Url: $url');
            return {'status': 'success', 'action': 'share'};
          }
        }
        return {'status': 'success', 'timestamp': DateTime.now().millisecondsSinceEpoch};
      },
    );

    // 2. Özel 'Web2App' JS Handlerları (Doğrudan çağrılar için)
    controller.addJavaScriptHandler(
      handlerName: 'Web2App_logEvent',
      callback: (args) {
        final eventName = args.isNotEmpty ? args[0]?.toString() ?? 'web_event' : 'web_event';
        final params = args.length > 1 ? args[1] : {};
        debugPrint('[Web2App JS API] logEvent: $eventName -> $params');
        return {'success': true, 'event': eventName};
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'Web2App_setBadge',
      callback: (args) {
        final count = (args.isNotEmpty && args[0] is num) ? (args[0] as num).toInt() : 0;
        debugPrint('[Web2App JS API] setBadge: $count');
        return {'success': true, 'badgeCount': count};
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'Web2App_requestReview',
      callback: (args) {
        debugPrint('[Web2App JS API] requestReview requested');
        return {'success': true};
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'Web2App_share',
      callback: (args) {
        final shareData = args.isNotEmpty && args[0] is Map ? args[0] : {'text': args.toString()};
        debugPrint('[Web2App JS API] share: $shareData');
        return {'success': true, 'data': shareData};
      },
    );
  }

  /// Kullanıcı tarafından tanımlanan özel CSS, JavaScript ve Viewport kurallarını sayfaya uygular
  Future<void> _injectCustomAssets(InAppWebViewController controller) async {
    // 0. Web2App Client JS Helper SDK Enjeksiyonu
    const clientHelperJs = r'''
    (function() {
      if (!window.Web2App) {
        window.Web2App = {
          isNativeApp: true,
          platform: 'flutter',
          logEvent: function(eventName, params) {
            if (window.flutter_inappwebview) {
              return window.flutter_inappwebview.callHandler('Web2App_logEvent', eventName, params || {});
            }
          },
          setBadge: function(count) {
            if (window.flutter_inappwebview) {
              return window.flutter_inappwebview.callHandler('Web2App_setBadge', count);
            }
          },
          requestReview: function() {
            if (window.flutter_inappwebview) {
              return window.flutter_inappwebview.callHandler('Web2App_requestReview');
            }
          },
          share: function(data) {
            if (window.flutter_inappwebview) {
              return window.flutter_inappwebview.callHandler('Web2App_share', data);
            }
          },
          postMessage: function(action, payload) {
            if (window.flutter_inappwebview) {
              return window.flutter_inappwebview.callHandler('FlutterBridge', Object.assign({ action: action }, payload || {}));
            }
          }
        };
      }
    })();
    ''';

    try {
      await controller.evaluateJavascript(source: clientHelperJs);
    } catch (e) {
      debugPrint('[CustomWebView] Client JS Helper injection error: $e');
    }

    // 1. Mobil Viewport Zorlama Enjeksiyonu
    if (widget.config.webviewSettings.forceMobileViewport) {
      try {
        await controller.evaluateJavascript(source: _viewportJsScript);
      } catch (e) {
        debugPrint('[CustomWebView] Viewport injection error: $e');
      }
    }

    // 2. Özel CSS Enjeksiyonu
    if (widget.config.webviewSettings.customCss.isNotEmpty) {
      try {
        final css = widget.config.webviewSettings.customCss;
        final js = """
(function() {
  var style = document.getElementById('__web2app_custom_css');
  if (!style) {
    style = document.createElement('style');
    style.id = '__web2app_custom_css';
    var target = document.head || document.getElementsByTagName('head')[0] || document.documentElement || document.body;
    if (target) target.appendChild(style);
  }
  style.textContent = ${jsonEncode(css)};
})();
""";
        await controller.evaluateJavascript(source: js);
      } catch (e) {
        debugPrint('[CustomWebView] Custom CSS injection error: $e');
      }
    }

    // 3. Özel JS Enjeksiyonu
    if (widget.config.webviewSettings.customJavascript.isNotEmpty) {
      try {
        await controller.evaluateJavascript(
          source: widget.config.webviewSettings.customJavascript,
        );
      } catch (e) {
        debugPrint('[CustomWebView] Custom JS injection error: $e');
      }
    }
  }
}
