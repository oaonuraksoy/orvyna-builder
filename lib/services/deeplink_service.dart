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

  /// Gelen URL isteğini analiz eder ve gerekirse native uygulamaya yönlendirir.
  /// true dönerse istek WebView içinde durdurulmalıdır (CANCELLED).
  Future<bool> handleNavigationRequest(NavigationAction action) async {
    final uri = action.request.url;
    if (uri == null) return false;

    final scheme = uri.scheme.toLowerCase();
    final urlString = uri.toString();

    // 1. Özel / Native Şemaların Yakalanması
    if (_nativeSchemes.contains(scheme) || !urlString.startsWith('http')) {
      await _launchExternalProtocol(urlString);
      return true; // WebView içi navigasyonu engelle
    }

    // 2. Harici Web Bağlantıları Kontrolü
    if (config.webviewSettings.openExternalUrlsInBrowser) {
      final baseUri = Uri.tryParse(config.appInfo.webUrl);
      if (baseUri != null && uri.host.isNotEmpty && !uri.host.endsWith(baseUri.host)) {
        // Hedef domain ana domainden farklı ise harici tarayıcıda aç
        await _launchInBrowser(urlString);
        return true; // WebView içi navigasyonu engelle
      }
    }

    return false; // Standart WebView yüklemesine devam et
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
