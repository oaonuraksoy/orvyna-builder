import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/app_config.dart';
import '../services/adblock_service.dart';
import '../services/deeplink_service.dart';
import '../services/permission_service.dart';
import 'shimmer_loading.dart';
import 'offline_screen.dart';

/// Dinamik Shimmer, AdBlock, DeepLink ve İzin destekli gelişmiş WebView bileşeni
class CustomWebView extends StatefulWidget {
  final AppConfig config;
  final AdBlockService adBlockService;
  final DeepLinkService deepLinkService;
  final PermissionService permissionService;
  final VoidCallback? onPageNavigated;

  const CustomWebView({
    super.key,
    required this.config,
    required this.adBlockService,
    required this.deepLinkService,
    required this.permissionService,
    this.onPageNavigated,
  });

  @override
  State<CustomWebView> createState() => CustomWebViewState();
}

class CustomWebViewState extends State<CustomWebView> {
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;

  double _loadingProgress = 0.0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePullToRefresh();
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
          if (Platform.isAndroid) {
            webViewController?.reload();
          } else if (Platform.isIOS) {
            webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()),
            );
          }
        },
      );
    }
  }

  /// Harici URL yükleme metodu (Örn: OneSignal bildiriminden tetiklenen)
  Future<void> loadUrl(String urlString) async {
    final uri = WebUri(urlString);
    await webViewController?.loadUrl(urlRequest: URLRequest(url: uri));
  }

  /// Geri navigasyon kontrolü
  Future<bool> canGoBack() async {
    return (await webViewController?.canGoBack()) ?? false;
  }

  Future<void> goBack() async {
    await webViewController?.goBack();
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
            _isLoading = true;
          });
          webViewController?.reload();
        },
      );
    }

    return Stack(
      children: [
        // 1. Ana InAppWebView
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(widget.config.appInfo.webUrl),
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
            userAgent: widget.config.appInfo.userAgent.isNotEmpty
                ? widget.config.appInfo.userAgent
                : null,
            supportMultipleWindows: false,
            transparentBackground: true,
          ),
          pullToRefreshController: pullToRefreshController,
          onWebViewCreated: (controller) {
            webViewController = controller;
            _setupJavaScriptHandlers(controller);
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
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
              _isLoading = true;
            });
            widget.onPageNavigated?.call();
          },
          onProgressChanged: (controller, progress) {
            final progressNormalized = progress / 100.0;
            setState(() {
              _loadingProgress = progressNormalized;
              if (progress >= 80 && _isLoading) {
                _isLoading = false;
              }
            });

            pullToRefreshController?.endRefreshing();

            // Kozmetik filtreyi sayfa yüklenirken erken enjekte et
            widget.adBlockService.injectCosmeticFilter(controller);
          },
          onLoadStop: (controller, url) async {
            pullToRefreshController?.endRefreshing();
            setState(() {
              _isLoading = false;
              _loadingProgress = 1.0;
            });

            // Kozmetik CSS & Özel Script enjeksiyonu
            await widget.adBlockService.injectCosmeticFilter(controller);
            await _injectCustomAssets(controller);
          },
          onReceivedError: (controller, request, error) {
            pullToRefreshController?.endRefreshing();
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

        // 2. Shimmer Skeleton Yükleme Ekranı (Fade Transition)
        if (_isLoading)
          AnimatedOpacity(
            opacity: _isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 350),
            child: ShimmerLoadingView(theme: widget.config.theme),
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

  /// JS Köprüsü ve Native İletişim Kanalları
  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'FlutterBridge',
      callback: (args) {
        debugPrint('[JSBridge] Webden çağrı alındı: $args');
        if (args.isNotEmpty && args[0] is Map) {
          final data = args[0] as Map<dynamic, dynamic>;
          final action = data['action']?.toString();
          if (action == 'reload') {
            controller.reload();
          }
        }
        return {'status': 'success', 'timestamp': DateTime.now().millisecondsSinceEpoch};
      },
    );
  }

  /// Kullanıcı tarafından tanımlanan özel CSS ve JavaScript kodlarını sayfaya uygular
  Future<void> _injectCustomAssets(InAppWebViewController controller) async {
    // Özel CSS Enjeksiyonu
    if (widget.config.webviewSettings.customCss.isNotEmpty) {
      await controller.injectCSSCode(
        source: widget.config.webviewSettings.customCss,
      );
    }

    // Özel JS Enjeksiyonu
    if (widget.config.webviewSettings.customJavascript.isNotEmpty) {
      await controller.evaluateJavascript(
        source: widget.config.webviewSettings.customJavascript,
      );
    }
  }
}
