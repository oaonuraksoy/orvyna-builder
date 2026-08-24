import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mobile_engine/models/app_config.dart';
import 'package:mobile_engine/services/deeplink_service.dart';

void main() {
  group('AppConfig Tests', () {
    test('fromJson and toJson round-trip integrity with Navigation, Versioning, and DOM Hider', () {
      final jsonMap = {
        'version': '1.0.0',
        'app_info': {
          'app_name': 'Test Web App',
          'package_name': 'com.example.testapp',
          'web_url': 'https://example.com',
          'user_agent': 'CustomUA',
          'app_version': '1.2.3',
          'build_number': 42,
        },
        'theme': {
          'primary_color': '#2563EB',
          'accent_color': '#3B82F6',
          'background_color': '#FFFFFF',
          'status_bar_color': '#1D4ED8',
          'status_bar_dark_icons': false,
          'splash_background_color': '#2563EB',
          'theme_template': 'minimalist',
        },
        'navigation': {
          'enabled': true,
          'style': 'bottomNavBar',
          'block_external_urls': false,
          'items': [
            {
              'id': '1',
              'title': 'Ana Sayfa',
              'url': 'https://example.com',
              'icon': 'home',
              'enabled': true,
            },
            {
              'id': '2',
              'title': 'Ürünler',
              'url': 'https://example.com/shop',
              'icon': 'shop',
              'enabled': true,
            }
          ],
        },
        'webview_settings': {
          'pull_to_refresh': true,
          'show_progress_bar': true,
          'progress_bar_color': '#3B82F6',
          'enable_javascript': true,
          'enable_dom_storage': true,
          'enable_geolocation': true,
          'enable_camera_microphone': true,
          'clear_cache_on_launch': false,
          'open_external_urls_in_browser': true,
          'hidden_selectors': ['header', 'footer'],
          'injected_css': 'header, footer { display: none !important; }',
          'custom_css': 'body { background: red; }',
          'custom_javascript': 'console.log("hello");',
        },
        'adblock_settings': {
          'enabled': true,
          'block_known_ad_hosts': true,
          'blocked_selectors': ['.adsbygoogle'],
          'blocked_url_patterns': ['.*doubleclick\\.net.*'],
        },
        'monetization': {
          'admob_enabled': true,
          'banner_enabled': true,
          'banner_id_android': 'ca-app-pub-xxx',
          'banner_id_ios': 'ca-app-pub-yyy',
          'interstitial_enabled': false,
          'interstitial_id_android': '',
          'interstitial_id_ios': '',
          'interstitial_page_interval': 5,
          'interstitial_time_interval_seconds': 120,
          'app_open_enabled': false,
          'app_open_id_android': '',
          'app_open_id_ios': '',
        },
        'notifications': {
          'onesignal_enabled': true,
          'onesignal_app_id': 'test-onesignal-id',
          'prompt_permission_on_launch': true,
        },
        'permissions': {
          'camera': true,
          'microphone': true,
          'location': true,
          'storage': true,
          'notifications': true,
        },
        'offline_settings': {
          'offline_title': 'Bağlantı Yok',
          'offline_message': 'Lütfen internetinizi kontrol edin',
          'retry_button_text': 'Yenile',
        },
      };

      final config = AppConfig.fromJson(jsonMap);
      expect(config.version, equals('1.0.0'));
      expect(config.appInfo.appName, equals('Test Web App'));
      expect(config.appInfo.packageName, equals('com.example.testapp'));
      expect(config.appInfo.webUrl, equals('https://example.com'));
      expect(config.appInfo.appVersion, equals('1.2.3'));
      expect(config.appInfo.buildNumber, equals(42));
      expect(config.navigation.enabled, isTrue);
      expect(config.navigation.style, equals('bottomNavBar'));
      expect(config.navigation.blockExternalUrls, isFalse);
      expect(config.navigation.items.length, equals(2));
      expect(config.navigation.items[0].title, equals('Ana Sayfa'));
      expect(config.webviewSettings.hiddenSelectors, contains('header'));
      expect(config.webviewSettings.injectedCss, contains('display: none !important;'));
      expect(config.webviewSettings.forceMobileViewport, isTrue);
      expect(config.webviewSettings.disallowOverScroll, isFalse);
      expect(config.webviewSettings.supportZoom, isTrue);
      expect(config.adblockSettings.enabled, isTrue);
      expect(config.adblockSettings.blockedSelectors, contains('.adsbygoogle'));
      expect(config.monetization.bannerEnabled, isTrue);
      expect(config.notifications.onesignalAppId, equals('test-onesignal-id'));

      final serialized = config.toJson();
      expect(serialized['version'], equals('1.0.0'));
      expect(serialized['app_info']['app_name'], equals('Test Web App'));
      expect(serialized['app_info']['app_version'], equals('1.2.3'));
      expect(serialized['app_info']['build_number'], equals(42));
      expect(serialized['navigation']['enabled'], isTrue);
      expect(serialized['navigation']['block_external_urls'], isFalse);
    });

    test('AppConfig Phase 3 Navigation Routing & Strict Domain Lock serialization and defaults', () {
      final jsonMap = {
        'version': '1.0.0',
        'app_info': {
          'app_name': 'Routing App',
          'package_name': 'com.example.routing',
          'web_url': 'https://mysite.com',
          'user_agent': '',
          'app_version': '2.0.0',
          'build_number': 10,
        },
        'theme': {
          'primary_color': '#2563EB',
          'accent_color': '#3B82F6',
          'background_color': '#FFFFFF',
          'status_bar_color': '#1D4ED8',
          'status_bar_dark_icons': false,
          'splash_background_color': '#2563EB',
          'theme_template': 'minimalist',
        },
        'navigation': {
          'enabled': true,
          'style': 'bottomNavBar',
          'internal_domains': ['mysite.com', 'auth.mysite.com', 'm.mysite.com'],
          'external_url_patterns': ['*.instagram.com/*', '*.twitter.com/*', '^https://.*\\.bank\\.com/.*'],
          'open_external_in_browser': true,
          'enable_deep_links': true,
          'block_external_urls': true,
          'items': [],
        },
        'webview_settings': {
          'show_app_bar': true,
          'pull_to_refresh': true,
          'show_progress_bar': true,
          'progress_bar_color': '#3B82F6',
          'enable_javascript': true,
          'enable_dom_storage': true,
          'enable_geolocation': true,
          'enable_camera_microphone': true,
          'clear_cache_on_launch': false,
          'open_external_urls_in_browser': true,
          'force_mobile_viewport': true,
          'disallow_over_scroll': false,
          'support_zoom': true,
          'hidden_selectors': [],
          'injected_css': '',
          'custom_css': '',
          'custom_javascript': '',
        },
        'adblock_settings': {
          'enabled': true,
          'block_known_ad_hosts': true,
          'blocked_selectors': [],
          'blocked_url_patterns': [],
        },
        'monetization': {
          'admob_enabled': false,
          'banner_enabled': false,
          'banner_id_android': '',
          'banner_id_ios': '',
          'interstitial_enabled': false,
          'interstitial_id_android': '',
          'interstitial_id_ios': '',
          'interstitial_page_interval': 5,
          'interstitial_time_interval_seconds': 120,
          'app_open_enabled': false,
          'app_open_id_android': '',
          'app_open_id_ios': '',
        },
        'notifications': {
          'onesignal_enabled': false,
          'onesignal_app_id': '',
          'prompt_permission_on_launch': true,
        },
        'permissions': {
          'camera': true,
          'microphone': true,
          'location': true,
          'storage': true,
          'notifications': true,
        },
        'offline_settings': {
          'offline_title': 'Bağlantı Yok',
          'offline_message': 'Hata',
          'retry_button_text': 'Yenile',
        },
      };

      final config = AppConfig.fromJson(jsonMap);
      expect(config.appInfo.appVersion, equals('2.0.0'));
      expect(config.appInfo.buildNumber, equals(10));
      expect(config.navigation.internalDomains, contains('auth.mysite.com'));
      expect(config.navigation.externalUrlPatterns.length, equals(3));
      expect(config.navigation.openExternalInBrowser, isTrue);
      expect(config.navigation.enableDeepLinks, isTrue);
      expect(config.navigation.blockExternalUrls, isTrue);
      expect(config.webviewSettings.forceMobileViewport, isTrue);
      expect(AppInfoConfig.defaultMobileUserAgent, contains('iPhone'));

      final jsonOut = config.toJson();
      expect(jsonOut['app_info']['app_version'], equals('2.0.0'));
      expect(jsonOut['app_info']['build_number'], equals(10));
      expect(jsonOut['navigation']['internal_domains'], contains('auth.mysite.com'));
      expect(jsonOut['navigation']['external_url_patterns'], contains('*.instagram.com/*'));
      expect(jsonOut['navigation']['block_external_urls'], isTrue);
      expect(jsonOut['webview_settings']['force_mobile_viewport'], isTrue);
    });

    test('DeepLinkService pattern matching and internal domain verification', () {
      expect(DeepLinkService.isNativeScheme('tel'), isTrue);
      expect(DeepLinkService.isNativeScheme('whatsapp'), isTrue);
      expect(DeepLinkService.isNativeScheme('mailto'), isTrue);
      expect(DeepLinkService.isNativeScheme('https'), isFalse);

      // Wildcard matching
      expect(DeepLinkService.matchesPattern('https://www.instagram.com/p/123', '*.instagram.com/*'), isTrue);
      expect(DeepLinkService.matchesPattern('https://instagram.com/explore', '*.instagram.com/*'), isTrue);
      expect(DeepLinkService.matchesPattern('https://facebook.com/profile', '*.instagram.com/*'), isFalse);

      // Regex matching
      expect(DeepLinkService.matchesPattern('https://auth.bank.com/login', r'/^https:\/\/.*\.bank\.com\/.*$/'), isTrue);

      // Internal domain matching
      final internalList = ['mysite.com', 'auth.mysite.com'];
      expect(DeepLinkService.isInternalDomain(Uri.parse('https://mysite.com/home'), internalList, 'https://mysite.com'), isTrue);
      expect(DeepLinkService.isInternalDomain(Uri.parse('https://shop.mysite.com/cart'), internalList, 'https://mysite.com'), isTrue);
      expect(DeepLinkService.isInternalDomain(Uri.parse('https://auth.mysite.com/sso'), internalList, 'https://mysite.com'), isTrue);
      expect(DeepLinkService.isInternalDomain(Uri.parse('https://external-hacker.com'), internalList, 'https://mysite.com'), isFalse);
    });

    test('DeepLinkService Strict Domain Lock (blockExternalUrls == true) cancels external navigation', () async {
      final config = AppConfig(
        version: '1.0.0',
        appInfo: const AppInfoConfig(
          appName: 'Locked App',
          packageName: 'com.example.lock',
          webUrl: 'https://mysite.com',
          userAgent: '',
          appVersion: '1.0.0',
          buildNumber: 1,
        ),
        theme: const ThemeConfig(
          primaryColorHex: '#2563EB',
          accentColorHex: '#3B82F6',
          backgroundColorHex: '#FFFFFF',
          statusBarColorHex: '#1D4ED8',
          statusBarDarkIcons: false,
          splashBackgroundColorHex: '#2563EB',
          themeTemplate: 'minimalist',
        ),
        navigation: const NavigationConfig(
          enabled: true,
          style: 'none',
          items: [],
          internalDomains: ['mysite.com', 'auth.mysite.com'],
          blockExternalUrls: true,
          openExternalInBrowser: true,
        ),
        webviewSettings: const WebViewSettingsConfig(
          pullToRefresh: false,
          showProgressBar: false,
          progressBarColorHex: '#3B82F6',
          enableJavascript: true,
          enableDomStorage: true,
          enableGeolocation: false,
          enableCameraMicrophone: false,
          clearCacheOnLaunch: false,
          openExternalUrlsInBrowser: true,
          customCss: '',
          customJavascript: '',
        ),
        adblockSettings: const AdblockSettingsConfig(
          enabled: false,
          blockKnownAdHosts: false,
          blockedSelectors: [],
          blockedUrlPatterns: [],
        ),
        monetization: const MonetizationConfig(
          admobEnabled: false,
          bannerEnabled: false,
          bannerIdAndroid: '',
          bannerIdIos: '',
          interstitialEnabled: false,
          interstitialIdAndroid: '',
          interstitialIdIos: '',
          interstitialPageInterval: 5,
          interstitialTimeIntervalSeconds: 120,
          appOpenEnabled: false,
          appOpenIdAndroid: '',
          appOpenIdIos: '',
        ),
        notifications: const NotificationsConfig(
          onesignalEnabled: false,
          onesignalAppId: '',
          promptPermissionOnLaunch: false,
        ),
        permissions: const PermissionsConfig(
          camera: false,
          microphone: false,
          location: false,
          storage: false,
          notifications: false,
        ),
        offlineSettings: const OfflineSettingsConfig(
          offlineTitle: 'Offline',
          offlineMessage: 'No internet',
          retryButtonText: 'Retry',
        ),
      );

      final deepLinkService = DeepLinkService(config: config);

      // 1. Internal Domain Request -> should NOT be blocked (returns false, allowed in webview)
      final internalNav = NavigationAction(
        request: URLRequest(url: WebUri('https://mysite.com/profile')),
        isForMainFrame: true,
      );
      final internalHandled = await deepLinkService.handleNavigationRequest(internalNav);
      expect(internalHandled, isFalse);

      // 2. Subdomain Request in internalDomains -> should NOT be blocked
      final subNav = NavigationAction(
        request: URLRequest(url: WebUri('https://auth.mysite.com/login')),
        isForMainFrame: true,
      );
      final subHandled = await deepLinkService.handleNavigationRequest(subNav);
      expect(subHandled, isFalse);

      // 3. External Domain Request -> SHOULD be cancelled immediately (returns true, navigation cancelled)
      final externalNav = NavigationAction(
        request: URLRequest(url: WebUri('https://google.com/search')),
        isForMainFrame: true,
      );
      final externalHandled = await deepLinkService.handleNavigationRequest(externalNav);
      expect(externalHandled, isTrue);

      // 4. External Social Media Request -> SHOULD be cancelled immediately
      final socialNav = NavigationAction(
        request: URLRequest(url: WebUri('https://instagram.com/test')),
        isForMainFrame: true,
      );
      final socialHandled = await deepLinkService.handleNavigationRequest(socialNav);
      expect(socialHandled, isTrue);
    });

    test('AppConfig 4 Offline Modes, Custom Pages, and System Settings Serialization', () {
      final jsonMap = {
        'version': '1.0.0',
        'app_info': {
          'app_name': 'Web2App Advanced',
          'package_name': 'com.web2app.adv',
          'web_url': 'https://example.com',
          'user_agent': 'CustomEngineUA',
          'app_version': '2.0.0',
          'build_number': 5,
        },
        'theme': {
          'primary_color': '#059669',
          'accent_color': '#D97706',
          'background_color': '#022C22',
          'status_bar_color': '#064E3B',
          'status_bar_dark_icons': false,
          'splash_background_color': '#059669',
          'theme_template': 'emeraldLuxury',
        },
        'navigation': {
          'enabled': true,
          'style': 'bottomNavBar',
          'items': [],
        },
        'webview_settings': {
          'pull_to_refresh': true,
          'show_progress_bar': true,
          'progress_bar_color': '#D97706',
          'enable_javascript': true,
          'enable_dom_storage': true,
          'enable_geolocation': true,
          'enable_camera_microphone': true,
          'clear_cache_on_launch': false,
          'open_external_urls_in_browser': true,
          'custom_css': '',
          'custom_javascript': '',
        },
        'adblock_settings': {
          'enabled': true,
          'block_known_ad_hosts': true,
          'blocked_selectors': [],
          'blocked_url_patterns': [],
        },
        'monetization': {
          'admob_enabled': false,
          'banner_enabled': false,
          'banner_id_android': '',
          'banner_id_ios': '',
          'interstitial_enabled': false,
          'interstitial_id_android': '',
          'interstitial_id_ios': '',
          'interstitial_page_interval': 5,
          'interstitial_time_interval_seconds': 120,
          'app_open_enabled': false,
          'app_open_id_android': '',
          'app_open_id_ios': '',
        },
        'notifications': {
          'onesignal_enabled': false,
          'onesignal_app_id': '',
          'prompt_permission_on_launch': true,
        },
        'permissions': {
          'camera': true,
          'microphone': true,
          'location': true,
          'storage': true,
          'notifications': true,
        },
        'offline_settings': {
          'offline_mode_type': 'interactiveGame',
          'custom_offline_html': '',
          'offline_title': 'İnternet Yok, Oyun Oyna!',
          'offline_message': 'Zıplayarak engelleri aşın.',
          'retry_button_text': 'Yeniden Bağlan',
        },
        'custom_pages': [
          {
            'id': 'contact',
            'title': 'İletişim & Yardım',
            'content': '# Bize Ulaşın\n\n- E-posta: support@example.com\n- Tel: +90 555 123 45 67',
            'layout': 'heroContact',
            'icon': 'contact',
            'show_in_navigation': true,
          },
          {
            'id': 'faq',
            'title': 'Sıkça Sorulanlar',
            'content': '### Soru 1\nCevap 1\n\n### Soru 2\nCevap 2',
            'layout': 'cardGrid',
            'icon': 'quiz',
            'show_in_navigation': true,
          }
        ],
        'system_settings': {
          'orientation_lock': 'landscape',
          'immersive_fullscreen': true,
          'app_shortcuts': [
            {
              'id': 'sc1',
              'title': 'Hızlı İletişim',
              'short_label': 'İletişim',
              'icon': 'contact',
              'url': 'custom://contact',
            }
          ],
        },
      };

      final config = AppConfig.fromJson(jsonMap);
      expect(config.theme.themeTemplate, equals('emeraldLuxury'));
      expect(config.offlineSettings.offlineModeType, equals(OfflineModeType.interactiveGame));
      expect(config.offlineSettings.offlineTitle, equals('İnternet Yok, Oyun Oyna!'));
      expect(config.customPages.length, equals(2));
      expect(config.customPages[0].id, equals('contact'));
      expect(config.customPages[0].layout, equals(CustomPageLayout.heroContact));
      expect(config.customPages[1].id, equals('faq'));
      expect(config.customPages[1].layout, equals(CustomPageLayout.cardGrid));
      expect(config.systemSettings.orientationLock, equals('landscape'));
      expect(config.systemSettings.immersiveFullscreen, isTrue);
      expect(config.systemSettings.appShortcuts.length, equals(1));
      expect(config.systemSettings.appShortcuts[0].url, equals('custom://contact'));

      // Round-trip toJson
      final serialized = config.toJson();
      expect(serialized['offline_settings']['offline_mode_type'], equals('interactiveGame'));
      expect(serialized['custom_pages'][0]['layout'], equals('heroContact'));
      expect(serialized['system_settings']['orientation_lock'], equals('landscape'));
      expect(serialized['system_settings']['immersive_fullscreen'], isTrue);
    });
  });
}
