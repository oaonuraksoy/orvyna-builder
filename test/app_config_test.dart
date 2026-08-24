import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_engine/models/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('fromJson and toJson round-trip integrity with Navigation and DOM Hider', () {
      final jsonMap = {
        'version': '1.0.0',
        'app_info': {
          'app_name': 'Test Web App',
          'package_name': 'com.example.testapp',
          'web_url': 'https://example.com',
          'user_agent': 'CustomUA',
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
      expect(config.navigation.enabled, isTrue);
      expect(config.navigation.style, equals('bottomNavBar'));
      expect(config.navigation.items.length, equals(2));
      expect(config.navigation.items[0].title, equals('Ana Sayfa'));
      expect(config.webviewSettings.hiddenSelectors, contains('header'));
      expect(config.webviewSettings.injectedCss, contains('display: none !important;'));
      expect(config.adblockSettings.enabled, isTrue);
      expect(config.adblockSettings.blockedSelectors, contains('.adsbygoogle'));
      expect(config.monetization.bannerEnabled, isTrue);
      expect(config.notifications.onesignalAppId, equals('test-onesignal-id'));

      final serialized = config.toJson();
      expect(serialized['version'], equals('1.0.0'));
      expect(serialized['app_info']['app_name'], equals('Test Web App'));
      expect(serialized['navigation']['enabled'], isTrue);
    });
  });
}
