import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_config.dart';
import 'services/adblock_service.dart';
import 'services/biometric_service.dart';
import 'services/deeplink_service.dart';
import 'services/in_app_review_service.dart';
import 'services/notification_service.dart';
import 'services/admob_service.dart';
import 'services/permission_service.dart';
import 'widgets/custom_page_view.dart';
import 'widgets/custom_webview.dart';
import 'widgets/floating_support_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Konfigürasyon dosyasını yükle
  AppConfig config;
  try {
    final jsonString = await rootBundle.loadString('assets/config/app_config.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    config = AppConfig.fromJson(jsonMap);
  } catch (e) {
    debugPrint('[MobileEngine] Konfigürasyon yükleme hatası: $e');
    config = AppConfig.fromJson({});
  }

  // 2. Sistem Ayarlarını Uygula (Ekran Yönü Kilidi & Tam Ekran Modu)
  _applySystemSettings(config.systemSettings);

  // 3. Servisleri Başlat
  final adBlockService = AdBlockService(config: config.adblockSettings);
  await adBlockService.initialize();

  final deepLinkService = DeepLinkService(config: config);

  final permissionService = PermissionService(config: config.permissions);
  await permissionService.requestAppPermissions();

  final admobService = AdMobService(config: config.monetization);
  await admobService.initialize();

  final notificationService = NotificationService(config: config.notifications);

  final biometricService = BiometricService(config: config.biometric);

  final inAppReviewService = InAppReviewService(
    config: config.inAppReview,
    packageName: config.appInfo.packageName,
  );
  inAppReviewService.recordAppLaunch();

  runApp(Web2AppEngineApp(
    config: config,
    adBlockService: adBlockService,
    deepLinkService: deepLinkService,
    permissionService: permissionService,
    admobService: admobService,
    notificationService: notificationService,
    biometricService: biometricService,
    inAppReviewService: inAppReviewService,
  ));
}

/// Ekran yön kilidi ve tam ekran ayarlarını uygular
void _applySystemSettings(SystemSettingsConfig systemSettings) {
  switch (systemSettings.orientationLock) {
    case 'portrait':
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      break;
    case 'landscape':
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      break;
    case 'auto':
    default:
      SystemChrome.setPreferredOrientations([]);
      break;
  }

  if (systemSettings.immersiveFullscreen) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

class Web2AppEngineApp extends StatelessWidget {
  final AppConfig config;
  final AdBlockService adBlockService;
  final DeepLinkService deepLinkService;
  final PermissionService permissionService;
  final AdMobService admobService;
  final NotificationService notificationService;
  final BiometricService biometricService;
  final InAppReviewService inAppReviewService;

  const Web2AppEngineApp({
    super.key,
    required this.config,
    required this.adBlockService,
    required this.deepLinkService,
    required this.permissionService,
    required this.admobService,
    required this.notificationService,
    required this.biometricService,
    required this.inAppReviewService,
  });

  @override
  Widget build(BuildContext context) {
    // Sistem durum çubuğu ve navigasyon barı renklerini ayarla
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: config.theme.statusBarColor,
        statusBarIconBrightness:
            config.theme.statusBarDarkIcons ? Brightness.dark : Brightness.light,
        statusBarBrightness:
            config.theme.statusBarDarkIcons ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: config.theme.backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: config.appInfo.appName.isNotEmpty ? config.appInfo.appName : 'Web2App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: config.theme.backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: config.theme.primaryColor,
          primary: config.theme.primaryColor,
          secondary: config.theme.accentColor,
          surface: config.theme.backgroundColor,
        ),
      ),
      home: MainEngineScreen(
        config: config,
        adBlockService: adBlockService,
        deepLinkService: deepLinkService,
        permissionService: permissionService,
        admobService: admobService,
        notificationService: notificationService,
        biometricService: biometricService,
        inAppReviewService: inAppReviewService,
      ),
    );
  }
}

class MainEngineScreen extends StatefulWidget {
  final AppConfig config;
  final AdBlockService adBlockService;
  final DeepLinkService deepLinkService;
  final PermissionService permissionService;
  final AdMobService admobService;
  final NotificationService notificationService;
  final BiometricService biometricService;
  final InAppReviewService inAppReviewService;

  const MainEngineScreen({
    super.key,
    required this.config,
    required this.adBlockService,
    required this.deepLinkService,
    required this.permissionService,
    required this.admobService,
    required this.notificationService,
    required this.biometricService,
    required this.inAppReviewService,
  });

  @override
  State<MainEngineScreen> createState() => _MainEngineScreenState();
}

class _MainEngineScreenState extends State<MainEngineScreen> with WidgetsBindingObserver {
  final GlobalKey<CustomWebViewState> _webViewKey = GlobalKey<CustomWebViewState>();
  int _selectedNavIndex = 0;
  bool _isBiometricLocked = false;
  CustomPageConfig? _activeCustomPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Biyometrik Kilit Kontrolü
    if (widget.biometricService.isEnabled) {
      _isBiometricLocked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerBiometricAuth();
      });
    }

    // OneSignal bildirim tıklandığında URL yönlendirme dinleyicisi
    widget.notificationService.initialize(
      onUrlCallback: (targetUrl) {
        _handleIncomingUrl(targetUrl);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.admobService.showAppOpenAdIfAvailable();
      if (widget.biometricService.isEnabled && widget.biometricService.isAuthRequired) {
        setState(() => _isBiometricLocked = true);
        _triggerBiometricAuth();
      }
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final success = await widget.biometricService.authenticate(context: context);
    if (mounted) {
      setState(() {
        _isBiometricLocked = !success;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.admobService.dispose();
    super.dispose();
  }

  String? _startupPendingUrl;

  void _handleIncomingUrl(String url) {
    if (url.startsWith('custom://')) {
      final pageId = url.replaceFirst('custom://', '').trim();
      final page = widget.config.customPages.cast<CustomPageConfig?>().firstWhere(
            (p) => p?.id == pageId,
            orElse: () => null,
          );
      if (page != null) {
        setState(() {
          _activeCustomPage = page;
        });
        return;
      }
    }

    setState(() {
      _activeCustomPage = null;
    });
    
    if (_webViewKey.currentState != null) {
      _webViewKey.currentState?.loadUrl(url);
    } else {
      _startupPendingUrl = url;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_startupPendingUrl != null && _webViewKey.currentState != null) {
          _webViewKey.currentState?.loadUrl(_startupPendingUrl!);
          _startupPendingUrl = null;
        }
      });
    }
  }

  void _navigateToHome() {
    setState(() {
      _activeCustomPage = null;
      _selectedNavIndex = 0;
    });
    final homeUrl = widget.config.appInfo.webUrl.isNotEmpty
        ? widget.config.appInfo.webUrl
        : 'https://flutter.dev';
    _webViewKey.currentState?.loadUrl(homeUrl);
  }

  IconData _resolveIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'shop':
        return Icons.shopping_bag_rounded;
      case 'cart':
        return Icons.shopping_cart_rounded;
      case 'user':
        return Icons.person_rounded;
      case 'search':
        return Icons.search_rounded;
      case 'settings':
        return Icons.settings_rounded;
      case 'blog':
      case 'article':
        return Icons.article_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      case 'faq':
      case 'quiz':
        return Icons.quiz_rounded;
      case 'contact':
        return Icons.headset_mic_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Widget _buildNavIconWithBadge(NavigationItemConfig item) {
    final baseIcon = Icon(_resolveIcon(item.icon));
    if (item.badgeCount <= 0) return baseIcon;

    return Badge(
      label: Text(
        item.badgeCount > 99 ? '99+' : item.badgeCount.toString(),
        style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold),
      ),
      child: baseIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final navConfig = widget.config.navigation;
    final activeNavItems = navConfig.items.where((i) => i.enabled).toList();
    final hasDrawer = navConfig.enabled && navConfig.style == 'drawer' && activeNavItems.isNotEmpty;
    final hasBottomBar = navConfig.enabled && navConfig.style == 'bottomNavBar' && activeNavItems.isNotEmpty;

    // Aktif Custom Page (Markdown) Varsa Onu Göster
    if (_activeCustomPage != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          setState(() {
            _activeCustomPage = null;
          });
        },
        child: CustomPageView(
          page: _activeCustomPage!,
          theme: widget.config.theme,
          onBackToHome: () => setState(() => _activeCustomPage = null),
          onNavigateCustomPage: _handleIncomingUrl,
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final customWebState = _webViewKey.currentState;
        if (customWebState != null && await customWebState.canGoBack()) {
          await customWebState.goBack();
        } else {
          // WebView geçmişinde sayfa yoksa uygulamadan çık
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: widget.config.theme.backgroundColor,
        appBar: widget.config.webviewSettings.showAppBar
            ? AppBar(
                backgroundColor: widget.config.theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0.5,
                title: InkWell(
                  onTap: _navigateToHome,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.public_rounded, size: 20.0),
                        const SizedBox(width: 8.0),
                        Text(
                          widget.config.appInfo.appName.isNotEmpty
                              ? widget.config.appInfo.appName
                              : 'Web2App',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0),
                        ),
                      ],
                    ),
                  ),
                ),
                centerTitle: widget.config.webviewSettings.appBarCenterTitle,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 22.0),
                    tooltip: 'Yenile',
                    onPressed: () {
                      try {
                        _webViewKey.currentState?.webViewController?.reload();
                      } catch (e) {
                        debugPrint('reload error: $e');
                      }
                    },
                  ),
                ],
              )
            : null,
        drawer: hasDrawer
            ? Drawer(
                backgroundColor: widget.config.theme.backgroundColor,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: widget.config.theme.primaryColor,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToHome();
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Icon(Icons.apps_rounded, color: widget.config.theme.primaryColor, size: 28.0),
                            ),
                            const SizedBox(height: 10.0),
                            Text(
                              widget.config.appInfo.appName.isNotEmpty
                                  ? widget.config.appInfo.appName
                                  : 'Web2App',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...activeNavItems.map((item) {
                      return ListTile(
                        leading: _buildNavIconWithBadge(item),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: item.badgeCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Text(
                                  item.badgeCount.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _handleIncomingUrl(item.url);
                        },
                      );
                    }),
                    // Özel Statik Sayfalar Menü Öğeleri
                    if (widget.config.customPages.isNotEmpty) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Text(
                          'BİLGİ & YARDIM SAYFALARI',
                          style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                        ),
                      ),
                      ...widget.config.customPages.where((p) => p.showInNavigation).map((page) {
                        return ListTile(
                          leading: Icon(_resolveIcon(page.icon), color: widget.config.theme.primaryColor),
                          title: Text(page.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _activeCustomPage = page;
                            });
                          },
                        );
                      }),
                    ],
                  ],
                ),
              )
            : null,
        body: SafeArea(
          top: !widget.config.webviewSettings.showAppBar,
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  // WebView Ana Gövdesi
                  Expanded(
                    child: CustomWebView(
                      key: _webViewKey,
                      config: widget.config,
                      adBlockService: widget.adBlockService,
                      deepLinkService: widget.deepLinkService,
                      permissionService: widget.permissionService,
                      onCustomPageRequested: (url) => _handleIncomingUrl(url),
                      onPageNavigated: () {
                        widget.admobService.onPageNavigated();
                        widget.inAppReviewService.recordUserAction();
                        if (widget.inAppReviewService.shouldPromptReview()) {
                          widget.inAppReviewService.requestReview(context: context);
                        }
                      },
                    ),
                  ),

                  // Alt Banner Reklam (Aktifse)
                  if (widget.config.monetization.admobEnabled &&
                      widget.config.monetization.bannerEnabled)
                    widget.admobService.buildBannerWidget(),
                ],
              ),

              // Yüzen Destek / WhatsApp Butonu
              if (widget.config.floatingButton.enabled)
                FloatingSupportButton(config: widget.config.floatingButton),

              // Biyometrik Kilit Karartma Katmanı
              if (_isBiometricLocked)
                Container(
                  color: Colors.black.withValues(alpha: 0.95),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fingerprint_rounded, size: 64.0, color: Color(0xFF38BDF8)),
                        const SizedBox(height: 16.0),
                        const Text(
                          'Uygulama Kilitli',
                          style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _triggerBiometricAuth,
                          child: const Text('Kilidi Aç'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: hasBottomBar
            ? NavigationBar(
                selectedIndex: _selectedNavIndex.clamp(0, activeNavItems.length - 1),
                backgroundColor: widget.config.theme.backgroundColor,
                indicatorColor: widget.config.theme.primaryColor.withValues(alpha: 0.2),
                destinations: activeNavItems.map((item) {
                  return NavigationDestination(
                    icon: _buildNavIconWithBadge(item),
                    label: item.title,
                  );
                }).toList(),
                onDestinationSelected: (index) {
                  setState(() => _selectedNavIndex = index);
                  final item = activeNavItems[index];
                  _handleIncomingUrl(item.url);
                },
              )
            : null,
      ),
    );
  }
}


