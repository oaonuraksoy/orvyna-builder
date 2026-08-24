import 'dart:convert';
import 'package:flutter/material.dart';

/// Mobil motor için merkezi tip güvenli konfigürasyon modeli
class AppConfig {
  final String version;
  final AppInfoConfig appInfo;
  final ThemeConfig theme;
  final NavigationConfig navigation;
  final WebViewSettingsConfig webviewSettings;
  final AdblockSettingsConfig adblockSettings;
  final MonetizationConfig monetization;
  final NotificationsConfig notifications;
  final PermissionsConfig permissions;
  final OfflineSettingsConfig offlineSettings;

  const AppConfig({
    required this.version,
    required this.appInfo,
    required this.theme,
    this.navigation = const NavigationConfig.defaultConfig(),
    required this.webviewSettings,
    required this.adblockSettings,
    required this.monetization,
    required this.notifications,
    required this.permissions,
    required this.offlineSettings,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      version: json['version'] as String? ?? '1.0.0',
      appInfo: AppInfoConfig.fromJson(json['app_info'] as Map<String, dynamic>? ?? {}),
      theme: ThemeConfig.fromJson(json['theme'] as Map<String, dynamic>? ?? {}),
      navigation: NavigationConfig.fromJson(json['navigation'] as Map<String, dynamic>? ?? {}),
      webviewSettings: WebViewSettingsConfig.fromJson(json['webview_settings'] as Map<String, dynamic>? ?? {}),
      adblockSettings: AdblockSettingsConfig.fromJson(json['adblock_settings'] as Map<String, dynamic>? ?? {}),
      monetization: MonetizationConfig.fromJson(json['monetization'] as Map<String, dynamic>? ?? {}),
      notifications: NotificationsConfig.fromJson(json['notifications'] as Map<String, dynamic>? ?? {}),
      permissions: PermissionsConfig.fromJson(json['permissions'] as Map<String, dynamic>? ?? {}),
      offlineSettings: OfflineSettingsConfig.fromJson(json['offline_settings'] as Map<String, dynamic>? ?? {}),
    );
  }

  static AppConfig fromJsonString(String jsonString) {
    final Map<String, dynamic> decoded = json.decode(jsonString) as Map<String, dynamic>;
    return AppConfig.fromJson(decoded);
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'app_info': appInfo.toJson(),
      'theme': theme.toJson(),
      'navigation': navigation.toJson(),
      'webview_settings': webviewSettings.toJson(),
      'adblock_settings': adblockSettings.toJson(),
      'monetization': monetization.toJson(),
      'notifications': notifications.toJson(),
      'permissions': permissions.toJson(),
      'offline_settings': offlineSettings.toJson(),
    };
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  AppConfig copyWith({
    String? version,
    AppInfoConfig? appInfo,
    ThemeConfig? theme,
    NavigationConfig? navigation,
    WebViewSettingsConfig? webviewSettings,
    AdblockSettingsConfig? adblockSettings,
    MonetizationConfig? monetization,
    NotificationsConfig? notifications,
    PermissionsConfig? permissions,
    OfflineSettingsConfig? offlineSettings,
  }) {
    return AppConfig(
      version: version ?? this.version,
      appInfo: appInfo ?? this.appInfo,
      theme: theme ?? this.theme,
      navigation: navigation ?? this.navigation,
      webviewSettings: webviewSettings ?? this.webviewSettings,
      adblockSettings: adblockSettings ?? this.adblockSettings,
      monetization: monetization ?? this.monetization,
      notifications: notifications ?? this.notifications,
      permissions: permissions ?? this.permissions,
      offlineSettings: offlineSettings ?? this.offlineSettings,
    );
  }
}

class NavigationItemConfig {
  final String id;
  final String title;
  final String url;
  final String icon;
  final bool enabled;

  const NavigationItemConfig({
    required this.id,
    required this.title,
    required this.url,
    required this.icon,
    this.enabled = true,
  });

  factory NavigationItemConfig.fromJson(Map<String, dynamic> json) {
    return NavigationItemConfig(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'home',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'icon': icon,
    'enabled': enabled,
  };
}

class NavigationConfig {
  final bool enabled;
  final String style; // 'bottomNavBar', 'drawer', 'none'
  final List<NavigationItemConfig> items;

  const NavigationConfig({
    required this.enabled,
    required this.style,
    required this.items,
  });

  const NavigationConfig.defaultConfig()
      : enabled = false,
        style = 'none',
        items = const [];

  factory NavigationConfig.fromJson(Map<String, dynamic> json) {
    return NavigationConfig(
      enabled: json['enabled'] as bool? ?? false,
      style: json['style'] as String? ?? 'none',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => NavigationItemConfig.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'style': style,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class AppInfoConfig {
  final String appName;
  final String packageName;
  final String webUrl;
  final String userAgent;

  const AppInfoConfig({
    required this.appName,
    required this.packageName,
    required this.webUrl,
    required this.userAgent,
  });

  factory AppInfoConfig.fromJson(Map<String, dynamic> json) {
    return AppInfoConfig(
      appName: json['app_name'] as String? ?? 'Web2App',
      packageName: json['package_name'] as String? ?? 'com.web2app.app',
      webUrl: json['web_url'] as String? ?? 'https://flutter.dev',
      userAgent: json['user_agent'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'app_name': appName,
    'package_name': packageName,
    'web_url': webUrl,
    'user_agent': userAgent,
  };
}

class ThemeConfig {
  final String primaryColorHex;
  final String accentColorHex;
  final String backgroundColorHex;
  final String statusBarColorHex;
  final bool statusBarDarkIcons;
  final String splashBackgroundColorHex;
  final String themeTemplate;

  const ThemeConfig({
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.backgroundColorHex,
    required this.statusBarColorHex,
    required this.statusBarDarkIcons,
    required this.splashBackgroundColorHex,
    required this.themeTemplate,
  });

  Color get primaryColor => _hexToColor(primaryColorHex, const Color(0xFF2563EB));
  Color get accentColor => _hexToColor(accentColorHex, const Color(0xFF3B82F6));
  Color get backgroundColor => _hexToColor(backgroundColorHex, Colors.white);
  Color get statusBarColor => _hexToColor(statusBarColorHex, const Color(0xFF1D4ED8));
  Color get splashBackgroundColor => _hexToColor(splashBackgroundColorHex, const Color(0xFF2563EB));

  static Color _hexToColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      primaryColorHex: json['primary_color'] as String? ?? '#2563EB',
      accentColorHex: json['accent_color'] as String? ?? '#3B82F6',
      backgroundColorHex: json['background_color'] as String? ?? '#FFFFFF',
      statusBarColorHex: json['status_bar_color'] as String? ?? '#1D4ED8',
      statusBarDarkIcons: json['status_bar_dark_icons'] as bool? ?? false,
      splashBackgroundColorHex: json['splash_background_color'] as String? ?? '#2563EB',
      themeTemplate: json['theme_template'] as String? ?? 'minimalist',
    );
  }

  Map<String, dynamic> toJson() => {
    'primary_color': primaryColorHex,
    'accent_color': accentColorHex,
    'background_color': backgroundColorHex,
    'status_bar_color': statusBarColorHex,
    'status_bar_dark_icons': statusBarDarkIcons,
    'splash_background_color': splashBackgroundColorHex,
    'theme_template': themeTemplate,
  };
}

class WebViewSettingsConfig {
  final bool showAppBar;
  final bool pullToRefresh;
  final bool showProgressBar;
  final String progressBarColorHex;
  final bool enableJavascript;
  final bool enableDomStorage;
  final bool enableGeolocation;
  final bool enableCameraMicrophone;
  final bool clearCacheOnLaunch;
  final bool openExternalUrlsInBrowser;
  final List<String> hiddenSelectors;
  final String injectedCss;
  final String customCss;
  final String customJavascript;

  const WebViewSettingsConfig({
    this.showAppBar = true,
    required this.pullToRefresh,
    required this.showProgressBar,
    required this.progressBarColorHex,
    required this.enableJavascript,
    required this.enableDomStorage,
    required this.enableGeolocation,
    required this.enableCameraMicrophone,
    required this.clearCacheOnLaunch,
    required this.openExternalUrlsInBrowser,
    this.hiddenSelectors = const [],
    this.injectedCss = '',
    required this.customCss,
    required this.customJavascript,
  });

  factory WebViewSettingsConfig.fromJson(Map<String, dynamic> json) {
    return WebViewSettingsConfig(
      showAppBar: json['show_app_bar'] as bool? ?? true,
      pullToRefresh: json['pull_to_refresh'] as bool? ?? true,
      showProgressBar: json['show_progress_bar'] as bool? ?? true,
      progressBarColorHex: json['progress_bar_color'] as String? ?? '#3B82F6',
      enableJavascript: json['enable_javascript'] as bool? ?? true,
      enableDomStorage: json['enable_dom_storage'] as bool? ?? true,
      enableGeolocation: json['enable_geolocation'] as bool? ?? true,
      enableCameraMicrophone: json['enable_camera_microphone'] as bool? ?? true,
      clearCacheOnLaunch: json['clear_cache_on_launch'] as bool? ?? false,
      openExternalUrlsInBrowser: json['open_external_urls_in_browser'] as bool? ?? true,
      hiddenSelectors: (json['hidden_selectors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      injectedCss: json['injected_css'] as String? ?? '',
      customCss: json['custom_css'] as String? ?? '',
      customJavascript: json['custom_javascript'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'show_app_bar': showAppBar,
    'pull_to_refresh': pullToRefresh,
    'show_progress_bar': showProgressBar,
    'progress_bar_color': progressBarColorHex,
    'enable_javascript': enableJavascript,
    'enable_dom_storage': enableDomStorage,
    'enable_geolocation': enableGeolocation,
    'enable_camera_microphone': enableCameraMicrophone,
    'clear_cache_on_launch': clearCacheOnLaunch,
    'open_external_urls_in_browser': openExternalUrlsInBrowser,
    'hidden_selectors': hiddenSelectors,
    'injected_css': injectedCss,
    'custom_css': customCss,
    'custom_javascript': customJavascript,
  };
}

class AdblockSettingsConfig {
  final bool enabled;
  final bool blockKnownAdHosts;
  final List<String> blockedSelectors;
  final List<String> blockedUrlPatterns;

  const AdblockSettingsConfig({
    required this.enabled,
    required this.blockKnownAdHosts,
    required this.blockedSelectors,
    required this.blockedUrlPatterns,
  });

  factory AdblockSettingsConfig.fromJson(Map<String, dynamic> json) {
    return AdblockSettingsConfig(
      enabled: json['enabled'] as bool? ?? true,
      blockKnownAdHosts: json['block_known_ad_hosts'] as bool? ?? true,
      blockedSelectors: (json['blocked_selectors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      blockedUrlPatterns: (json['blocked_url_patterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'block_known_ad_hosts': blockKnownAdHosts,
    'blocked_selectors': blockedSelectors,
    'blocked_url_patterns': blockedUrlPatterns,
  };
}

class MonetizationConfig {
  final bool admobEnabled;
  final bool bannerEnabled;
  final String bannerIdAndroid;
  final String bannerIdIos;
  final bool interstitialEnabled;
  final String interstitialIdAndroid;
  final String interstitialIdIos;
  final int interstitialPageInterval;
  final int interstitialTimeIntervalSeconds;
  final bool appOpenEnabled;
  final String appOpenIdAndroid;
  final String appOpenIdIos;

  const MonetizationConfig({
    required this.admobEnabled,
    required this.bannerEnabled,
    required this.bannerIdAndroid,
    required this.bannerIdIos,
    required this.interstitialEnabled,
    required this.interstitialIdAndroid,
    required this.interstitialIdIos,
    required this.interstitialPageInterval,
    required this.interstitialTimeIntervalSeconds,
    required this.appOpenEnabled,
    required this.appOpenIdAndroid,
    required this.appOpenIdIos,
  });

  factory MonetizationConfig.fromJson(Map<String, dynamic> json) {
    return MonetizationConfig(
      admobEnabled: json['admob_enabled'] as bool? ?? false,
      bannerEnabled: json['banner_enabled'] as bool? ?? false,
      bannerIdAndroid: json['banner_id_android'] as String? ?? '',
      bannerIdIos: json['banner_id_ios'] as String? ?? '',
      interstitialEnabled: json['interstitial_enabled'] as bool? ?? false,
      interstitialIdAndroid: json['interstitial_id_android'] as String? ?? '',
      interstitialIdIos: json['interstitial_id_ios'] as String? ?? '',
      interstitialPageInterval: json['interstitial_page_interval'] as int? ?? 5,
      interstitialTimeIntervalSeconds: json['interstitial_time_interval_seconds'] as int? ?? 120,
      appOpenEnabled: json['app_open_enabled'] as bool? ?? false,
      appOpenIdAndroid: json['app_open_id_android'] as String? ?? '',
      appOpenIdIos: json['app_open_id_ios'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'admob_enabled': admobEnabled,
    'banner_enabled': bannerEnabled,
    'banner_id_android': bannerIdAndroid,
    'banner_id_ios': bannerIdIos,
    'interstitial_enabled': interstitialEnabled,
    'interstitial_id_android': interstitialIdAndroid,
    'interstitial_id_ios': interstitialIdIos,
    'interstitial_page_interval': interstitialPageInterval,
    'interstitial_time_interval_seconds': interstitialTimeIntervalSeconds,
    'app_open_enabled': appOpenEnabled,
    'app_open_id_android': appOpenIdAndroid,
    'app_open_id_ios': appOpenIdIos,
  };
}

class NotificationsConfig {
  final bool onesignalEnabled;
  final String onesignalAppId;
  final bool promptPermissionOnLaunch;

  const NotificationsConfig({
    required this.onesignalEnabled,
    required this.onesignalAppId,
    required this.promptPermissionOnLaunch,
  });

  factory NotificationsConfig.fromJson(Map<String, dynamic> json) {
    return NotificationsConfig(
      onesignalEnabled: json['onesignal_enabled'] as bool? ?? false,
      onesignalAppId: json['onesignal_app_id'] as String? ?? '',
      promptPermissionOnLaunch: json['prompt_permission_on_launch'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'onesignal_enabled': onesignalEnabled,
    'onesignal_app_id': onesignalAppId,
    'prompt_permission_on_launch': promptPermissionOnLaunch,
  };
}

class PermissionsConfig {
  final bool camera;
  final bool microphone;
  final bool location;
  final bool storage;
  final bool notifications;

  const PermissionsConfig({
    required this.camera,
    required this.microphone,
    required this.location,
    required this.storage,
    required this.notifications,
  });

  factory PermissionsConfig.fromJson(Map<String, dynamic> json) {
    return PermissionsConfig(
      camera: json['camera'] as bool? ?? true,
      microphone: json['microphone'] as bool? ?? true,
      location: json['location'] as bool? ?? true,
      storage: json['storage'] as bool? ?? true,
      notifications: json['notifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'camera': camera,
    'microphone': microphone,
    'location': location,
    'storage': storage,
    'notifications': notifications,
  };
}

class OfflineSettingsConfig {
  final String offlineTitle;
  final String offlineMessage;
  final String retryButtonText;

  const OfflineSettingsConfig({
    required this.offlineTitle,
    required this.offlineMessage,
    required this.retryButtonText,
  });

  factory OfflineSettingsConfig.fromJson(Map<String, dynamic> json) {
    return OfflineSettingsConfig(
      offlineTitle: json['offline_title'] as String? ?? 'İnternet Bağlantısı Yok',
      offlineMessage: json['offline_message'] as String? ?? 'Lütfen ağ bağlantınızı kontrol edip tekrar deneyiniz.',
      retryButtonText: json['retry_button_text'] as String? ?? 'Tekrar Dene',
    );
  }

  Map<String, dynamic> toJson() => {
    'offline_title': offlineTitle,
    'offline_message': offlineMessage,
    'retry_button_text': retryButtonText,
  };
}
