import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_config.dart';
import 'services/adblock_service.dart';
import 'services/deeplink_service.dart';
import 'services/notification_service.dart';
import 'services/admob_service.dart';
import 'services/permission_service.dart';
import 'widgets/custom_webview.dart';

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

  // 2. Servisleri Başlat
  final adBlockService = AdBlockService(config: config.adblockSettings);
  await adBlockService.initialize();

  final deepLinkService = DeepLinkService(config: config);

  final permissionService = PermissionService(config: config.permissions);
  await permissionService.requestAppPermissions();

  final admobService = AdMobService(config: config.monetization);
  await admobService.initialize();

  final notificationService = NotificationService(config: config.notifications);

  runApp(Web2AppEngineApp(
    config: config,
    adBlockService: adBlockService,
    deepLinkService: deepLinkService,
    permissionService: permissionService,
    admobService: admobService,
    notificationService: notificationService,
  ));
}

class Web2AppEngineApp extends StatelessWidget {
  final AppConfig config;
  final AdBlockService adBlockService;
  final DeepLinkService deepLinkService;
  final PermissionService permissionService;
  final AdMobService admobService;
  final NotificationService notificationService;

  const Web2AppEngineApp({
    super.key,
    required this.config,
    required this.adBlockService,
    required this.deepLinkService,
    required this.permissionService,
    required this.admobService,
    required this.notificationService,
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
      title: config.appInfo.appName,
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

  const MainEngineScreen({
    super.key,
    required this.config,
    required this.adBlockService,
    required this.deepLinkService,
    required this.permissionService,
    required this.admobService,
    required this.notificationService,
  });

  @override
  State<MainEngineScreen> createState() => _MainEngineScreenState();
}

class _MainEngineScreenState extends State<MainEngineScreen> {
  final GlobalKey<CustomWebViewState> _webViewKey = GlobalKey<CustomWebViewState>();

  @override
  void initState() {
    super.initState();
    // OneSignal bildirim tıklandığında URL yönlendirme dinleyicisi
    widget.notificationService.initialize(
      onUrlCallback: (targetUrl) {
        _webViewKey.currentState?.loadUrl(targetUrl);
      },
    );
  }

  @override
  void dispose() {
    widget.admobService.dispose();
    super.dispose();
  }

  int _selectedNavIndex = 0;

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
        return Icons.article_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navConfig = widget.config.navigation;
    final activeNavItems = navConfig.items.where((i) => i.enabled).toList();
    final hasDrawer = navConfig.enabled && navConfig.style == 'drawer' && activeNavItems.isNotEmpty;
    final hasBottomBar = navConfig.enabled && navConfig.style == 'bottomNavBar' && activeNavItems.isNotEmpty;

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
                title: Text(
                  widget.config.appInfo.appName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 22.0),
                    tooltip: 'Yenile',
                    onPressed: () {
                      _webViewKey.currentState?.webViewController?.reload();
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
                            widget.config.appInfo.appName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...activeNavItems.map((item) {
                      return ListTile(
                        leading: Icon(_resolveIcon(item.icon), color: widget.config.theme.primaryColor),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(context);
                          _webViewKey.currentState?.loadUrl(item.url);
                        },
                      );
                    }),
                  ],
                ),
              )
            : null,
        body: SafeArea(
          top: !widget.config.webviewSettings.showAppBar,
          bottom: false,
          child: Column(
            children: [
              // WebView Ana Gövdesi
              Expanded(
                child: CustomWebView(
                  key: _webViewKey,
                  config: widget.config,
                  adBlockService: widget.adBlockService,
                  deepLinkService: widget.deepLinkService,
                  permissionService: widget.permissionService,
                  onPageNavigated: () {
                    widget.admobService.onPageNavigated();
                  },
                ),
              ),

              // Alt Banner Reklam (Aktifse)
              if (widget.config.monetization.admobEnabled &&
                  widget.config.monetization.bannerEnabled)
                widget.admobService.buildBannerWidget(),
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
                    icon: Icon(_resolveIcon(item.icon)),
                    label: item.title,
                  );
                }).toList(),
                onDestinationSelected: (index) {
                  setState(() => _selectedNavIndex = index);
                  final item = activeNavItems[index];
                  _webViewKey.currentState?.loadUrl(item.url);
                },
              )
            : null,
      ),
    );
  }
}
