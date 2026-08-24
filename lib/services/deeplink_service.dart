import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_config.dart';

/// Harici şemalar (tel, mailto, whatsapp, intent vb.) ve derin bağlantıları yakalayıp yöneten servis
class DeepLinkService {
  final AppConfig config;

  static const List<String> _nativeSchemes = [
    'tel',
    'mailto',
    'sms',
    'geo',
    'maps',
    'whatsapp',
    'tg',
    'intent',
    'market',
    'itms-apps',
    'fb',
    'instagram',
    'twitter',
    'linkedin',
    'viber',
    'skype',
  ];

  DeepLinkService({required this.config});

  /// Gelen URL isteğini analiz eder ve gerekirse native uygulamaya veya harici tarayıcıya yönlendirir.
  /// true dönerse istek WebView içinde durdurulmalıdır (CANCELLED).
  Future<bool> handleNavigationRequest(NavigationAction action) async {
    final uri = action.request.url;
    if (uri == null) return false;

    final scheme = uri.scheme.toLowerCase();
    final urlString = uri.toString();

    final isInternal = isInternalDomain(uri, config.navigation.internalDomains, config.appInfo.webUrl);

    // 0. Strict Domain Lock (blockExternalUrls == true)
    // Eğer blockExternalUrls aktif ise ve URL isInternalDomain değilse;
    // hiçbir harici protokolü çalıştırma veya harici tarayıcıyı açma, navigasyonu doğrudan iptal et (true dön).
    if (config.navigation.blockExternalUrls) {
      if (isInternal) {
        return false; // WebView içinde yüklemeye izin ver
      } else {
        debugPrint('[DeepLinkService] Harici bağlantı engellendi (Strict Domain Lock): $urlString');
        return true; // Navigasyonu tamamen iptal et, harici tarayıcı açma
      }
    }

    // 1. Özel / Native Şemaların Yakalanması (tel, mailto, whatsapp, intent vb.)
    if (_nativeSchemes.contains(scheme) || !urlString.startsWith('http')) {
      await _launchExternalProtocol(urlString);
      return true; // WebView içi navigasyonu engelle
    }

    // 2. Harici URL Desenleri Kontrolü (externalUrlPatterns - örn: *.instagram.com/*)
    final externalPatterns = config.navigation.externalUrlPatterns;
    if (externalPatterns.isNotEmpty && matchesAnyPattern(urlString, externalPatterns)) {
      await _launchInBrowser(urlString);
      return true; // WebView içi navigasyonu engelle
    }

    // 3. İzin Verilen İç Domainler Kontrolü (internalDomains & ana site URL)
    if (isInternal) {
      return false; // WebView içinde yüklemeye izin ver
    }

    // 4. Genel Harici Web Bağlantıları Kontrolü (openExternalInBrowser / openExternalUrlsInBrowser)
    final openExternal = config.navigation.openExternalInBrowser ||
        config.webviewSettings.openExternalUrlsInBrowser;

    if (openExternal) {
      final baseUri = Uri.tryParse(config.appInfo.webUrl);
      if (baseUri != null && uri.host.isNotEmpty && !_isSameOrSubdomain(uri.host, baseUri.host)) {
        await _launchInBrowser(urlString);
        return true; // WebView içi navigasyonu engelle
      }
    }

    return false; // Standart WebView yüklemesine devam et
  }

  /// URL'nin verilen wildcard veya regex desenlerinden herhangi biriyle eşleşip eşleşmediğini kontrol eder
  static bool matchesAnyPattern(String url, List<String> patterns) {
    for (final pattern in patterns) {
      if (matchesPattern(url, pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Tek bir deseni (Wildcard `*` veya Regex) URL ile karşılaştırır
  static bool matchesPattern(String url, String pattern) {
    final trimmedPattern = pattern.trim();
    if (trimmedPattern.isEmpty) return false;

    try {
      if (trimmedPattern.startsWith('/') && trimmedPattern.endsWith('/') && trimmedPattern.length > 2) {
        final regexStr = trimmedPattern.substring(1, trimmedPattern.length - 1);
        final regExp = RegExp(regexStr, caseSensitive: false);
        return regExp.hasMatch(url);
      }

      // Wildcard '*' desenini esnek ve akıllı Regex'e dönüştür
      String regexStr = RegExp.escape(trimmedPattern);
      // '\*\.' desenini hem alt domainler hem kök domain ile eşleşecek şekilde ayarla (örn: *.instagram.com/* -> instagram.com ve www.instagram.com)
      regexStr = regexStr.replaceAll(r'\*\.', r'(?:.*?\.)?');
      regexStr = regexStr.replaceAll(r'\*', r'.*');

      final regExp = RegExp('^$regexStr\$', caseSensitive: false);
      if (regExp.hasMatch(url)) return true;

      // Protokol belirtilmemişse https?:// ön ekini opsiyonel destekle
      if (!trimmedPattern.contains('://')) {
        final withProto = RegExp('^(?:https?://)?$regexStr\$', caseSensitive: false);
        if (withProto.hasMatch(url)) return true;
      }

      // Kısmi eşleşme fallback
      final cleanPattern = trimmedPattern.replaceAll('*', '').trim();
      if (cleanPattern.isNotEmpty && url.toLowerCase().contains(cleanPattern.toLowerCase())) {
        return true;
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Patern eşleştirme hatası ($pattern): $e');
    }
    return false;
  }

  /// Verilen URI'nin iç domain listesinde veya ana web sitesi alan adında olup olmadığını kontrol eder
  static bool isInternalDomain(Uri uri, List<String> internalDomains, String mainWebUrl) {
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return true;

    // 1. Ana web sitesi alan adı kontrolü
    final baseUri = Uri.tryParse(mainWebUrl);
    if (baseUri != null && baseUri.host.isNotEmpty) {
      if (_isSameOrSubdomain(host, baseUri.host.toLowerCase())) {
        return true;
      }
    }

    // 2. Özel tanımlanmış iç domain listesi kontrolü
    for (final domain in internalDomains) {
      final cleanDomain = domain.trim().toLowerCase().replaceAll('https://', '').replaceAll('http://', '').split('/')[0];
      if (cleanDomain.isNotEmpty && _isSameOrSubdomain(host, cleanDomain)) {
        return true;
      }
    }

    return false;
  }

  /// Host eşleşmesi veya alt domain kontrolü (örn: auth.mysite.com <-> mysite.com)
  static bool _isSameOrSubdomain(String host, String targetDomain) {
    if (host == targetDomain) return true;
    if (host.endsWith('.$targetDomain')) return true;
    return false;
  }

  /// Harici protokollere yönlendir
  Future<void> _launchExternalProtocol(String urlString) async {
    try {
      final Uri parsedUri = Uri.parse(urlString);
      if (await canLaunchUrl(parsedUri)) {
        await launchUrl(parsedUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('[DeepLinkService] Protokol başlatılamadı: $urlString');
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Hata: $e');
    }
  }

  /// Harici tarayıcıda aç
  Future<void> _launchInBrowser(String urlString) async {
    try {
      final Uri parsedUri = Uri.parse(urlString);
      await launchUrl(parsedUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[DeepLinkService] Harici tarayıcı açma hatası: $e');
    }
  }

  /// Belirli bir scheme'in native olarak ele alınıp alınmayacağını kontrol eder
  static bool isNativeScheme(String scheme) {
    return _nativeSchemes.contains(scheme.toLowerCase());
  }
}
