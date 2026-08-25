import 'dart:convert';
import 'package:flutter/material.dart';

/// 4 Gelişmiş Çevrimdışı Mod Seçeneği
enum OfflineModeType {
  standardRetry('Standart Yenile Butonlu Hata Ekranı'),
  customHtml('Özel HTML / Markdown Çevrimdışı Sayfası'),
  cacheFirstFallback('Önbellek Odaklı Çevrimdışı Sunum'),
  interactiveGame('İnteraktif Eğlenceli Dinozor Oyunu');

  final String label;
  const OfflineModeType(this.label);
}

/// Custom Page 3 Farklı Layout Şablonu
enum CustomPageLayout {
  document('Belge / Tipografik Makale'),
  cardGrid('Kart & Akordeon SSS'),
  heroContact('Hero Banner & İletişim Formu');

  final String label;
  const CustomPageLayout(this.label);
}

/// Statik Markdown Sayfa Modeli
class CustomPageConfig {
  final String id;
  final String title;
  final String content;
  final CustomPageLayout layout;
  final String icon;
  final bool showInNavigation;

  const CustomPageConfig({
    required this.id,
    required this.title,
    required this.content,
    this.layout = CustomPageLayout.document,
    this.icon = 'article',
    this.showInNavigation = true,
  });

  factory CustomPageConfig.fromJson(Map<String, dynamic> json) {
    final layoutStr = json['layout']?.toString() ?? 'document';
    final layoutEnum = CustomPageLayout.values.firstWhere(
      (l) => l.name == layoutStr,
      orElse: () => CustomPageLayout.document,
    );

    return CustomPageConfig(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      layout: layoutEnum,
      icon: json['icon']?.toString() ?? 'article',
      showInNavigation: json['show_in_navigation'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'layout': layout.name,
    'icon': icon,
    'show_in_navigation': showInNavigation,
  };
}

/// Uygulama Hızlı Kısayol (App Shortcut / Quick Action) Modeli
class AppShortcutConfig {
  final String id;
  final String title;
  final String shortLabel;
  final String icon;
  final String url;

  const AppShortcutConfig({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.icon,
    required this.url,
  });

  factory AppShortcutConfig.fromJson(Map<String, dynamic> json) {
    return AppShortcutConfig(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      shortLabel: json['short_label']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'home',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'short_label': shortLabel,
    'icon': icon,
    'url': url,
  };
}

/// Sistem Ayarları (Ekran Yönü Kilidi, Tam Ekran, Kısayollar)
class SystemSettingsConfig {
  final String orientationLock; // 'auto', 'portrait', 'landscape'
  final bool immersiveFullscreen;
  final List<AppShortcutConfig> appShortcuts;

  const SystemSettingsConfig({
    this.orientationLock = 'auto',
    this.immersiveFullscreen = false,
    this.appShortcuts = const [],
  });

  const SystemSettingsConfig.defaultConfig()
      : orientationLock = 'auto',
        immersiveFullscreen = false,
        appShortcuts = const [];

  factory SystemSettingsConfig.fromJson(Map<String, dynamic> json) {
    return SystemSettingsConfig(
      orientationLock: json['orientation_lock']?.toString() ?? 'auto',
      immersiveFullscreen: json['immersive_fullscreen'] as bool? ?? false,
      appShortcuts: (json['app_shortcuts'] as List<dynamic>?)
              ?.map((s) => AppShortcutConfig.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'orientation_lock': orientationLock,
    'immersive_fullscreen': immersiveFullscreen,
    'app_shortcuts': appShortcuts.map((s) => s.toJson()).toList(),
  };
}

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
  final BiometricConfig biometric;
  final FloatingButtonConfig floatingButton;
  final InAppReviewConfig inAppReview;
  final StoreMetadataConfig storeMetadata;
  final List<CustomPageConfig> customPages;
  final SystemSettingsConfig systemSettings;
  final AssetsConfig assets;
  final SigningConfig signing;
  final AppStoreConnectConfig appStoreConnect;

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
    this.biometric = const BiometricConfig.defaultConfig(),
    this.floatingButton = const FloatingButtonConfig.defaultConfig(),
    this.inAppReview = const InAppReviewConfig.defaultConfig(),
    this.storeMetadata = const StoreMetadataConfig.defaultConfig(),
    this.customPages = const [],
    this.systemSettings = const SystemSettingsConfig.defaultConfig(),
    this.assets = const AssetsConfig.defaultConfig(),
    this.signing = const SigningConfig.defaultConfig(),
    this.appStoreConnect = const AppStoreConnectConfig.defaultConfig(),
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
      biometric: BiometricConfig.fromJson(json['biometric_auth'] as Map<String, dynamic>? ?? json['biometric'] as Map<String, dynamic>? ?? {}),
      floatingButton: FloatingButtonConfig.fromJson(json['floating_button'] as Map<String, dynamic>? ?? {}),
      inAppReview: InAppReviewConfig.fromJson(json['in_app_review'] as Map<String, dynamic>? ?? {}),
      storeMetadata: StoreMetadataConfig.fromJson(json['store_metadata'] as Map<String, dynamic>? ?? {}),
      customPages: (json['custom_pages'] as List<dynamic>?)
              ?.map((p) => CustomPageConfig.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      systemSettings: SystemSettingsConfig.fromJson(json['system_settings'] as Map<String, dynamic>? ?? {}),
      assets: AssetsConfig.fromJson(json['assets'] as Map<String, dynamic>? ?? {}),
      signing: SigningConfig.fromJson(json['signing'] as Map<String, dynamic>? ?? {}),
      appStoreConnect: AppStoreConnectConfig.fromJson(json['app_store_connect'] as Map<String, dynamic>? ?? {}),
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
      'biometric_auth': biometric.toJson(),
      'floating_button': floatingButton.toJson(),
      'in_app_review': inAppReview.toJson(),
      'store_metadata': storeMetadata.toJson(),
      'custom_pages': customPages.map((p) => p.toJson()).toList(),
      'system_settings': systemSettings.toJson(),
      'assets': assets.toJson(),
      'signing': signing.toJson(),
      'app_store_connect': appStoreConnect.toJson(),
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
    BiometricConfig? biometric,
    FloatingButtonConfig? floatingButton,
    InAppReviewConfig? inAppReview,
    StoreMetadataConfig? storeMetadata,
    List<CustomPageConfig>? customPages,
    SystemSettingsConfig? systemSettings,
    AssetsConfig? assets,
    SigningConfig? signing,
    AppStoreConnectConfig? appStoreConnect,
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
      biometric: biometric ?? this.biometric,
      floatingButton: floatingButton ?? this.floatingButton,
      inAppReview: inAppReview ?? this.inAppReview,
      storeMetadata: storeMetadata ?? this.storeMetadata,
      customPages: customPages ?? this.customPages,
      systemSettings: systemSettings ?? this.systemSettings,
      assets: assets ?? this.assets,
      signing: signing ?? this.signing,
      appStoreConnect: appStoreConnect ?? this.appStoreConnect,
    );
  }
}

class NavigationItemConfig {
  final String id;
  final String title;
  final String url;
  final String icon;
  final bool enabled;
  final int badgeCount;

  const NavigationItemConfig({
    required this.id,
    required this.title,
    required this.url,
    required this.icon,
    this.enabled = true,
    this.badgeCount = 0,
  });

  factory NavigationItemConfig.fromJson(Map<String, dynamic> json) {
    return NavigationItemConfig(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'home',
      enabled: json['enabled'] as bool? ?? true,
      badgeCount: (json['badge_count'] as num?)?.toInt() ?? (json['badgeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'icon': icon,
    'enabled': enabled,
    'badge_count': badgeCount,
  };

  NavigationItemConfig copyWith({
    String? id,
    String? title,
    String? url,
    String? icon,
    bool? enabled,
    int? badgeCount,
  }) {
    return NavigationItemConfig(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
      badgeCount: badgeCount ?? this.badgeCount,
    );
  }
}

class NavigationConfig {
  final bool enabled;
  final String style; // 'bottomNavBar', 'drawer', 'none'
  final List<NavigationItemConfig> items;
  final List<String> internalDomains;
  final List<String> externalUrlPatterns;
  final bool openExternalInBrowser;
  final bool enableDeepLinks;
  final bool blockExternalUrls;

  const NavigationConfig({
    required this.enabled,
    required this.style,
    required this.items,
    this.internalDomains = const [],
    this.externalUrlPatterns = const [],
    this.openExternalInBrowser = true,
    this.enableDeepLinks = true,
    this.blockExternalUrls = false,
  });

  const NavigationConfig.defaultConfig()
      : enabled = false,
        style = 'none',
        items = const [],
        internalDomains = const [],
        externalUrlPatterns = const [],
        openExternalInBrowser = true,
        enableDeepLinks = true,
        blockExternalUrls = false;

  factory NavigationConfig.fromJson(Map<String, dynamic> json) {
    return NavigationConfig(
      enabled: json['enabled'] as bool? ?? false,
      style: json['style'] as String? ?? 'none',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => NavigationItemConfig.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      internalDomains: (json['internal_domains'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      externalUrlPatterns: (json['external_url_patterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      openExternalInBrowser: json['open_external_in_browser'] as bool? ?? true,
      enableDeepLinks: json['enable_deep_links'] as bool? ?? true,
      blockExternalUrls: json['block_external_urls'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'style': style,
    'items': items.map((e) => e.toJson()).toList(),
    'internal_domains': internalDomains,
    'external_url_patterns': externalUrlPatterns,
    'open_external_in_browser': openExternalInBrowser,
    'enable_deep_links': enableDeepLinks,
    'block_external_urls': blockExternalUrls,
  };
}

class AppInfoConfig {
  static const String defaultMobileUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1';

  final String appName;
  final String packageName;
  final String webUrl;
  final String userAgent;
  final String appVersion;
  final int buildNumber;

  const AppInfoConfig({
    required this.appName,
    required this.packageName,
    required this.webUrl,
    required this.userAgent,
    this.appVersion = '1.0.0',
    this.buildNumber = 1,
  });

  factory AppInfoConfig.fromJson(Map<String, dynamic> json) {
    return AppInfoConfig(
      appName: json['app_name'] as String? ?? '',
      packageName: json['package_name'] as String? ?? '',
      webUrl: json['web_url'] as String? ?? '',
      userAgent: json['user_agent'] as String? ?? '',
      appVersion: json['app_version'] as String? ?? '1.0.0',
      buildNumber: (json['build_number'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'app_name': appName,
    'package_name': packageName,
    'web_url': webUrl,
    'user_agent': userAgent,
    'app_version': appVersion,
    'build_number': buildNumber,
  };
}

class ThemeConfig {
  final String primaryColorHex;
  final String accentColorHex;
  final String backgroundColorHex;
  final String statusBarColorHex;
  final bool statusBarDarkIcons;
  final String splashBackgroundColorHex;
  final bool splashShowTitle;
  final bool splashShowLoadingBar;
  final String splashLoadingText;
  final String themeTemplate;

  const ThemeConfig({
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.backgroundColorHex,
    required this.statusBarColorHex,
    required this.statusBarDarkIcons,
    required this.splashBackgroundColorHex,
    this.splashShowTitle = true,
    this.splashShowLoadingBar = true,
    this.splashLoadingText = 'Yükleniyor...',
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
      splashShowTitle: json['splash_show_title'] as bool? ?? true,
      splashShowLoadingBar: json['splash_show_loading_bar'] as bool? ?? true,
      splashLoadingText: json['splash_loading_text'] as String? ?? 'Yükleniyor...',
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
    'splash_show_title': splashShowTitle,
    'splash_show_loading_bar': splashShowLoadingBar,
    'splash_loading_text': splashLoadingText,
    'theme_template': themeTemplate,
  };
}

class WebViewSettingsConfig {
  final bool showAppBar;
  final bool appBarCenterTitle;
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
  final bool forceMobileViewport;
  final bool disallowOverScroll;
  final bool supportZoom;

  const WebViewSettingsConfig({
    this.showAppBar = true,
    this.appBarCenterTitle = true,
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
    this.forceMobileViewport = true,
    this.disallowOverScroll = false,
    this.supportZoom = true,
  });

  factory WebViewSettingsConfig.fromJson(Map<String, dynamic> json) {
    return WebViewSettingsConfig(
      showAppBar: json['show_app_bar'] as bool? ?? true,
      appBarCenterTitle: json['app_bar_center_title'] as bool? ?? true,
      pullToRefresh: json['pull_to_refresh'] as bool? ?? true,
      showProgressBar: json['show_progress_bar'] as bool? ?? true,
      progressBarColorHex: json['progress_bar_color'] as String? ?? '#3B82F6',
      enableJavascript: json['enable_javascript'] as bool? ?? true,
      enableDomStorage: json['enable_dom_storage'] as bool? ?? true,
      enableGeolocation: json['enable_geolocation'] as bool? ?? false,
      enableCameraMicrophone: json['enable_camera_microphone'] as bool? ?? false,
      clearCacheOnLaunch: json['clear_cache_on_launch'] as bool? ?? false,
      openExternalUrlsInBrowser: json['open_external_urls_in_browser'] as bool? ?? true,
      hiddenSelectors: (json['hidden_selectors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      injectedCss: json['injected_css'] as String? ?? '',
      customCss: json['custom_css'] as String? ?? '',
      customJavascript: json['custom_javascript'] as String? ?? '',
      forceMobileViewport: json['force_mobile_viewport'] as bool? ?? true,
      disallowOverScroll: json['disallow_over_scroll'] as bool? ?? false,
      supportZoom: json['support_zoom'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'show_app_bar': showAppBar,
    'app_bar_center_title': appBarCenterTitle,
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
    'force_mobile_viewport': forceMobileViewport,
    'disallow_over_scroll': disallowOverScroll,
    'support_zoom': supportZoom,
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

  const PermissionsConfig.defaultConfig()
      : camera = false,
        microphone = false,
        location = false,
        storage = false,
        notifications = false;

  factory PermissionsConfig.fromJson(Map<String, dynamic> json) {
    return PermissionsConfig(
      camera: json['camera'] as bool? ?? false,
      microphone: json['microphone'] as bool? ?? false,
      location: json['location'] as bool? ?? false,
      storage: json['storage'] as bool? ?? false,
      notifications: json['notifications'] as bool? ?? false,
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
  final OfflineModeType offlineModeType;
  final String customOfflineHtml;
  final String offlineTitle;
  final String offlineMessage;
  final String retryButtonText;

  const OfflineSettingsConfig({
    this.offlineModeType = OfflineModeType.standardRetry,
    this.customOfflineHtml = '',
    required this.offlineTitle,
    required this.offlineMessage,
    required this.retryButtonText,
  });

  factory OfflineSettingsConfig.fromJson(Map<String, dynamic> json) {
    final modeStr = json['offline_mode_type']?.toString() ?? 'standardRetry';
    final modeEnum = OfflineModeType.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => OfflineModeType.standardRetry,
    );

    return OfflineSettingsConfig(
      offlineModeType: modeEnum,
      customOfflineHtml: json['custom_offline_html'] as String? ?? '',
      offlineTitle: json['offline_title'] as String? ?? 'İnternet Bağlantısı Yok',
      offlineMessage: json['offline_message'] as String? ?? 'Lütfen ağ bağlantınızı kontrol edip tekrar deneyiniz.',
      retryButtonText: json['retry_button_text'] as String? ?? 'Tekrar Dene',
    );
  }

  Map<String, dynamic> toJson() => {
    'offline_mode_type': offlineModeType.name,
    'custom_offline_html': customOfflineHtml,
    'offline_title': offlineTitle,
    'offline_message': offlineMessage,
    'retry_button_text': retryButtonText,
  };
}

/// Biyometrik Kilit (Face ID / Fingerprint) Yapılandırması
class BiometricConfig {
  final bool enabled;
  final String promptTitle;
  final String promptSubtitle;
  final bool allowFallback;
  final int timeoutSeconds;

  const BiometricConfig({
    required this.enabled,
    this.promptTitle = 'Biyometrik Kimlik Doğrulama',
    this.promptSubtitle = 'Uygulamaya güvenle erişmek için parmak izinizi veya yüzünüzü okutun',
    this.allowFallback = true,
    this.timeoutSeconds = 0,
  });

  const BiometricConfig.defaultConfig()
      : enabled = false,
        promptTitle = 'Biyometrik Kimlik Doğrulama',
        promptSubtitle = 'Uygulamaya güvenle erişmek için parmak izinizi veya yüzünüzü okutun',
        allowFallback = true,
        timeoutSeconds = 0;

  factory BiometricConfig.fromJson(Map<String, dynamic> json) {
    return BiometricConfig(
      enabled: json['enabled'] as bool? ?? false,
      promptTitle: json['prompt_title'] as String? ?? 'Biyometrik Kimlik Doğrulama',
      promptSubtitle: json['prompt_subtitle'] as String? ??
          'Uygulamaya güvenle erişmek için parmak izinizi veya yüzünüzü okutun',
      allowFallback: json['allow_fallback'] as bool? ?? true,
      timeoutSeconds: (json['timeout_seconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'prompt_title': promptTitle,
    'prompt_subtitle': promptSubtitle,
    'allow_fallback': allowFallback,
    'timeout_seconds': timeoutSeconds,
  };

  BiometricConfig copyWith({
    bool? enabled,
    String? promptTitle,
    String? promptSubtitle,
    bool? allowFallback,
    int? timeoutSeconds,
  }) {
    return BiometricConfig(
      enabled: enabled ?? this.enabled,
      promptTitle: promptTitle ?? this.promptTitle,
      promptSubtitle: promptSubtitle ?? this.promptSubtitle,
      allowFallback: allowFallback ?? this.allowFallback,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }
}

/// Yüzen Canlı Destek & WhatsApp Hızlı İletişim Butonu Yapılandırması
class FloatingButtonConfig {
  final bool enabled;
  final String type; // 'whatsapp', 'live_chat', 'phone', 'custom_url'
  final String target;
  final String icon; // 'whatsapp', 'chat', 'support', 'phone', 'help'
  final String position; // 'bottomRight', 'bottomLeft', 'topRight', 'topLeft'
  final String backgroundColorHex;
  final String label;
  final String tooltip;
  final bool showBadge;

  const FloatingButtonConfig({
    required this.enabled,
    this.type = 'whatsapp',
    this.target = '',
    this.icon = 'whatsapp',
    this.position = 'bottomRight',
    this.backgroundColorHex = '#25D366',
    this.label = 'Canlı Destek',
    this.tooltip = 'Destek Hattı',
    this.showBadge = true,
  });

  const FloatingButtonConfig.defaultConfig()
      : enabled = false,
        type = 'whatsapp',
        target = '',
        icon = 'whatsapp',
        position = 'bottomRight',
        backgroundColorHex = '#25D366',
        label = 'Canlı Destek',
        tooltip = 'Destek Hattı',
        showBadge = true;

  Color get backgroundColor => ThemeConfig._hexToColor(backgroundColorHex, const Color(0xFF25D366));

  factory FloatingButtonConfig.fromJson(Map<String, dynamic> json) {
    return FloatingButtonConfig(
      enabled: json['enabled'] as bool? ?? false,
      type: json['type'] as String? ?? 'whatsapp',
      target: json['target'] as String? ?? '',
      icon: json['icon'] as String? ?? 'whatsapp',
      position: json['position'] as String? ?? 'bottomRight',
      backgroundColorHex: json['background_color'] as String? ?? '#25D366',
      label: json['label'] as String? ?? 'Canlı Destek',
      tooltip: json['tooltip'] as String? ?? 'Destek Hattı',
      showBadge: json['show_badge'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'type': type,
    'target': target,
    'icon': icon,
    'position': position,
    'background_color': backgroundColorHex,
    'label': label,
    'tooltip': tooltip,
    'show_badge': showBadge,
  };

  FloatingButtonConfig copyWith({
    bool? enabled,
    String? type,
    String? target,
    String? icon,
    String? position,
    String? backgroundColorHex,
    String? label,
    String? tooltip,
    bool? showBadge,
  }) {
    return FloatingButtonConfig(
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,
      target: target ?? this.target,
      icon: icon ?? this.icon,
      position: position ?? this.position,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      label: label ?? this.label,
      tooltip: tooltip ?? this.tooltip,
      showBadge: showBadge ?? this.showBadge,
    );
  }
}

/// Akıllı Mağaza İçi Puanlama Sayacı & Değerlendirme Yapılandırması
class InAppReviewConfig {
  final bool enabled;
  final int launchCountTrigger;
  final int daysUntilPrompt;
  final String customReviewUrl;
  final int minActionsTrigger;

  const InAppReviewConfig({
    required this.enabled,
    this.launchCountTrigger = 3,
    this.daysUntilPrompt = 2,
    this.customReviewUrl = '',
    this.minActionsTrigger = 5,
  });

  const InAppReviewConfig.defaultConfig()
      : enabled = true,
        launchCountTrigger = 3,
        daysUntilPrompt = 2,
        customReviewUrl = '',
        minActionsTrigger = 5;

  factory InAppReviewConfig.fromJson(Map<String, dynamic> json) {
    return InAppReviewConfig(
      enabled: json['enabled'] as bool? ?? true,
      launchCountTrigger: (json['launch_count_trigger'] as num?)?.toInt() ?? 3,
      daysUntilPrompt: (json['days_until_prompt'] as num?)?.toInt() ?? 2,
      customReviewUrl: json['custom_review_url'] as String? ?? '',
      minActionsTrigger: (json['min_actions_trigger'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'launch_count_trigger': launchCountTrigger,
    'days_until_prompt': daysUntilPrompt,
    'custom_review_url': customReviewUrl,
    'min_actions_trigger': minActionsTrigger,
  };

  InAppReviewConfig copyWith({
    bool? enabled,
    int? launchCountTrigger,
    int? daysUntilPrompt,
    String? customReviewUrl,
    int? minActionsTrigger,
  }) {
    return InAppReviewConfig(
      enabled: enabled ?? this.enabled,
      launchCountTrigger: launchCountTrigger ?? this.launchCountTrigger,
      daysUntilPrompt: daysUntilPrompt ?? this.daysUntilPrompt,
      customReviewUrl: customReviewUrl ?? this.customReviewUrl,
      minActionsTrigger: minActionsTrigger ?? this.minActionsTrigger,
    );
  }
}

/// Google Play Store ve Apple App Store Yayın Meta Verileri & ASO Modeli
class StoreMetadataConfig {
  final String appTitle;
  final String shortDescription;
  final String fullDescription;
  final List<String> keywords;
  final String supportUrl;
  final String privacyPolicyUrl;
  final String category;
  final String contentRating;
  final String copyright;

  const StoreMetadataConfig({
    this.appTitle = '',
    this.shortDescription = '',
    this.fullDescription = '',
    this.keywords = const [],
    this.supportUrl = '',
    this.privacyPolicyUrl = '',
    this.category = 'Shopping',
    this.contentRating = 'everyone',
    this.copyright = '',
  });

  const StoreMetadataConfig.defaultConfig()
      : appTitle = '',
        shortDescription = '',
        fullDescription = '',
        keywords = const [],
        supportUrl = '',
        privacyPolicyUrl = '',
        category = 'Shopping',
        contentRating = 'everyone',
        copyright = '';

  factory StoreMetadataConfig.fromJson(Map<String, dynamic> json) {
    return StoreMetadataConfig(
      appTitle: json['app_title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      fullDescription: json['full_description'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      supportUrl: json['support_url'] as String? ?? '',
      privacyPolicyUrl: json['privacy_policy_url'] as String? ?? '',
      category: json['category'] as String? ?? 'Shopping',
      contentRating: json['content_rating'] as String? ?? 'everyone',
      copyright: json['copyright'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'app_title': appTitle,
    'short_description': shortDescription,
    'full_description': fullDescription,
    'keywords': keywords,
    'support_url': supportUrl,
    'privacy_policy_url': privacyPolicyUrl,
    'category': category,
    'content_rating': contentRating,
    'copyright': copyright,
  };

  StoreMetadataConfig copyWith({
    String? appTitle,
    String? shortDescription,
    String? fullDescription,
    List<String>? keywords,
    String? supportUrl,
    String? privacyPolicyUrl,
    String? category,
    String? contentRating,
    String? copyright,
  }) {
    return StoreMetadataConfig(
      appTitle: appTitle ?? this.appTitle,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      keywords: keywords ?? this.keywords,
      supportUrl: supportUrl ?? this.supportUrl,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      category: category ?? this.category,
      contentRating: contentRating ?? this.contentRating,
      copyright: copyright ?? this.copyright,
    );
  }
}

/// Uygulama Varlıkları (İkon & Splash Base64) Yapılandırması
class AssetsConfig {
  final String iconBase64;
  final String splashBase64;

  const AssetsConfig({
    this.iconBase64 = '',
    this.splashBase64 = '',
  });

  const AssetsConfig.defaultConfig()
      : iconBase64 = '',
        splashBase64 = '';

  factory AssetsConfig.fromJson(Map<String, dynamic> json) {
    return AssetsConfig(
      iconBase64: json['icon_base64'] as String? ?? json['icon'] as String? ?? '',
      splashBase64: json['splash_base64'] as String? ?? json['splash'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'icon_base64': iconBase64,
    'splash_base64': splashBase64,
  };

  AssetsConfig copyWith({
    String? iconBase64,
    String? splashBase64,
  }) {
    return AssetsConfig(
      iconBase64: iconBase64 ?? this.iconBase64,
      splashBase64: splashBase64 ?? this.splashBase64,
    );
  }
}

/// Android Keystore İmzalama Yapılandırması
class SigningConfig {
  final String keystoreBase64;
  final String keystorePassword;
  final String keyAlias;
  final String keyPassword;

  const SigningConfig({
    this.keystoreBase64 = '',
    this.keystorePassword = '',
    this.keyAlias = 'upload',
    this.keyPassword = '',
  });

  const SigningConfig.defaultConfig()
      : keystoreBase64 = '',
        keystorePassword = '',
        keyAlias = 'upload',
        keyPassword = '';

  String get effectiveAlias => keyAlias.trim().isNotEmpty ? keyAlias.trim() : 'upload';
  String get effectiveKeyPassword =>
      keyPassword.trim().isNotEmpty ? keyPassword.trim() : keystorePassword.trim();

  factory SigningConfig.fromJson(Map<String, dynamic> json) {
    final rawAlias = json['key_alias'] as String? ?? '';
    return SigningConfig(
      keystoreBase64: json['keystore_base64'] as String? ?? '',
      keystorePassword: json['keystore_password'] as String? ?? '',
      keyAlias: rawAlias.trim().isNotEmpty ? rawAlias.trim() : 'upload',
      keyPassword: json['key_password'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'keystore_base64': keystoreBase64,
    'keystore_password': keystorePassword,
    'key_alias': effectiveAlias,
    'key_password': keyPassword,
  };

  SigningConfig copyWith({
    String? keystoreBase64,
    String? keystorePassword,
    String? keyAlias,
    String? keyPassword,
  }) {
    return SigningConfig(
      keystoreBase64: keystoreBase64 ?? this.keystoreBase64,
      keystorePassword: keystorePassword ?? this.keystorePassword,
      keyAlias: keyAlias ?? this.keyAlias,
      keyPassword: keyPassword ?? this.keyPassword,
    );
  }
}

/// iOS App Store Connect & TestFlight API Anahtarı Yapılandırması
class AppStoreConnectConfig {
  final String issuerId;
  final String keyId;
  final String p8Base64;

  const AppStoreConnectConfig({
    this.issuerId = '',
    this.keyId = '',
    this.p8Base64 = '',
  });

  const AppStoreConnectConfig.defaultConfig()
      : issuerId = '',
        keyId = '',
        p8Base64 = '';

  factory AppStoreConnectConfig.fromJson(Map<String, dynamic> json) {
    return AppStoreConnectConfig(
      issuerId: json['issuer_id'] as String? ?? '',
      keyId: json['key_id'] as String? ?? '',
      p8Base64: json['p8_base64'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'issuer_id': issuerId,
    'key_id': keyId,
    'p8_base64': p8Base64,
  };

  AppStoreConnectConfig copyWith({
    String? issuerId,
    String? keyId,
    String? p8Base64,
  }) {
    return AppStoreConnectConfig(
      issuerId: issuerId ?? this.issuerId,
      keyId: keyId ?? this.keyId,
      p8Base64: p8Base64 ?? this.p8Base64,
    );
  }
}



