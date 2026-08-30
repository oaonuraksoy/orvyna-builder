import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_config.dart';

/// Harici şemalar (tel, mailto, whatsapp, intent vb.), banka/POS geçitleri ve derin bağlantıları yöneten servis
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
    'x',
    'linkedin',
    'spotify',
    'vnd.youtube',
    'youtube',
    'viber',
    'skype',
  ];

  static const List<String> _nativeAppDomains = [
    'wa.me',
    'api.whatsapp.com',
    'chat.whatsapp.com',
    'instagram.com',
    'instagr.am',
    'twitter.com',
    'x.com',
    'linkedin.com',
    'lnkd.in',
    'youtube.com',
    'youtu.be',
    'music.youtube.com',
    'open.spotify.com',
    'spotify.com',
    'spotify.link',
    'maps.google.com',
    'maps.apple.com',
    'maps.app.goo.gl',
  ];

  static const List<String> _paymentAndBankingGateways = [
    'iyzipay.com',
    'iyzico.com',
    'paytr.com',
    'param.com.tr',
    'bkm.com.tr',
    'bkmexpress.com.tr',
    'stripe.com',
    'paypal.com',
    'garantibbva.com.tr',
    'garanti.com.tr',
    'isbank.com.tr',
    'yapikredi.com.tr',
    'akbank.com',
    'ziraatbank.com.tr',
    'vakifbank.com.tr',
    'halkbank.com.tr',
    'qnbfinansbank.com',
    'qnb.com.tr',
    'teb.com.tr',
    'denizbank.com',
    'kuveytturk.com.tr',
    'enpara.com',
    'papara.com',
    'mastercard.com',
    'visa.com',
    'troyodeme.com',
    'sipay.com.tr',
    'ininal.com',
    'paycell.com.tr',
    'turkiyefinans.com.tr',
    'albaraka.com.tr',
    'anadolubank.com.tr',
    'fibabanka.com.tr',
    'odeabank.com.tr',
    'sekerbank.com.tr',
    'vakifkatilim.com.tr',
    'ziraatkatilim.com.tr',
    'emlakkatilim.com.tr',
    'payguru.com',
    'moka.com',
    'ipara.com.tr',
    'birlesikodeme.com',
  ];

  static const List<String> _securityVerificationHosts = [
    'challenges.cloudflare.com',
    'hcaptcha.com',
    'geetest.com',
    'recaptcha.net',
    'arkoselabs.com',
    'funcaptcha.com',
    'cf-assets.hcaptcha.com',
    'newassets.hcaptcha.com',
    'static.geetest.com',
    'api.geetest.com',
    'cstaticdun.126.net',
  ];

  DeepLinkService({required this.config});

  /// Gelen URL isteğini analiz eder ve gerekirse native uygulamaya veya harici tarayıcıya yönlendirir.
  /// true dönerse istek WebView içinde durdurulmalıdır (CANCELLED / HANDLED).
  /// false dönerse istek WebView içinde yüklenmeye devam eder (ALLOW).
  Future<bool> handleNavigationRequest(
    NavigationAction action, {
    Future<bool> Function(Uri uri)? onConfirmExternalNavigation,
  }) async {
    final uri = action.request.url;
    if (uri == null) return false;

    final scheme = uri.scheme.toLowerCase();
    final urlString = uri.toString();

    // 1. Standart İletişim Şemaları (tel, mailto, sms)
    if (scheme == 'tel' || scheme == 'mailto' || scheme == 'sms') {
      await handleNativeAppLaunch(uri);
      return true; // WebView içi navigasyonu engelle
    }

    // 2. Sosyal Medya, Mesajlaşma, Harita & Medya Uygulamaları (WhatsApp, Instagram, X, Spotify, YouTube, Maps vb.)
    if (isNativeMediaOrMessagingApp(uri)) {
      await handleNativeAppLaunch(uri);
      return true; // Doğrudan yerel uygulamaya fırlat
    }

    // 3. Banka ve Ödeme Geçitleri (POS, 3D Secure, iyzico, PayTR, Bankalar vb.)
    // Ödeme ve 3D Secure akışının güvenle ve kopmadan WebView içinde tamamlanabilmesi için izin ver
    if (isPaymentOrBankingGateway(uri)) {
      return false; // In-App WebView içinde açılmasına izin ver
    }

    // 4. CAPTCHA & Güvenlik Doğrulama Geçitleri (Google reCAPTCHA, Cloudflare Turnstile, hCaptcha, Geetest vb.)
    if (isSecurityVerification(uri)) {
      return false; // In-App WebView içinde kesintisiz yüklenmesine izin ver
    }

    final isInternal = isInternalDomain(uri, config.navigation.internalDomains, config.appInfo.webUrl);

    // 5. Strict Domain Lock (blockExternalUrls == true)
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

    // 6. Diğer Özel / Native Şemalar (intent, market, itms-apps vb.) veya http dışı protokoller
    if (isNativeScheme(scheme) || !urlString.startsWith('http')) {
      await _launchExternalProtocol(urlString);
      return true; // WebView içi navigasyonu engelle
    }

    // 7. Harici URL Desenleri Kontrolü (externalUrlPatterns - örn: *.example-partner.com/*)
    final externalPatterns = config.navigation.externalUrlPatterns;
    if (externalPatterns.isNotEmpty && matchesAnyPattern(urlString, externalPatterns)) {
      if (onConfirmExternalNavigation != null) {
        final confirmed = await onConfirmExternalNavigation(uri);
        if (confirmed) {
          await _launchInBrowser(urlString);
        }
      } else {
        await _launchInBrowser(urlString);
      }
      return true; // WebView içi navigasyonu engelle
    }

    // 8. İzin Verilen İç Domainler Kontrolü (internalDomains & ana site URL)
    if (isInternal) {
      return false; // WebView içinde yüklemeye izin ver
    }

    // 9. Genel Harici Web Bağlantıları Kontrolü (openExternalInBrowser / openExternalUrlsInBrowser)
    final openExternal = config.navigation.openExternalInBrowser ||
        config.webviewSettings.openExternalUrlsInBrowser;

    if (openExternal) {
      final baseUri = Uri.tryParse(config.appInfo.webUrl);
      if (baseUri != null && uri.host.isNotEmpty && !_isSameOrSubdomain(uri.host, baseUri.host)) {
        if (onConfirmExternalNavigation != null) {
          final confirmed = await onConfirmExternalNavigation(uri);
          if (confirmed) {
            await _launchInBrowser(urlString);
          }
        } else {
          await _launchInBrowser(urlString);
        }
        return true; // WebView içi navigasyonu engelle
      }
    }

    return false; // Standart WebView yüklemesine devam et
  }

  /// Verilen URI'nin bir CAPTCHA veya güvenlik doğrulama geçidi (Google reCAPTCHA, Cloudflare Turnstile, hCaptcha, Geetest vb.) olup olmadığını kontrol eder
  static bool isSecurityVerification(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;

    // 1. Google reCAPTCHA & gstatic doğrulama kaynakları (google.com/recaptcha, gstatic.com/recaptcha, recaptcha.net)
    if (_isSameOrSubdomain(host, 'recaptcha.net')) return true;
    if (_isSameOrSubdomain(host, 'google.com') || _isSameOrSubdomain(host, 'gstatic.com')) {
      final path = uri.path.toLowerCase();
      final url = uri.toString().toLowerCase();
      if (path.contains('recaptcha') || url.contains('recaptcha')) {
        return true;
      }
    }

    // 2. Standart bot koruma & CAPTCHA domainleri (Cloudflare Turnstile, hCaptcha, Geetest vb.)
    for (final secHost in _securityVerificationHosts) {
      if (_isSameOrSubdomain(host, secHost)) {
        return true;
      }
    }

    return false;
  }

  /// Verilen URI'nin bir banka veya ödeme geçidi (iyzico, PayTR, Stripe, bankalar vb.) olup olmadığını kontrol eder
  static bool isPaymentOrBankingGateway(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;

    for (final gateway in _paymentAndBankingGateways) {
      if (_isSameOrSubdomain(host, gateway)) {
        return true;
      }
    }
    return false;
  }

  /// Verilen URI'nin bir yerel medya, mesajlaşma, harita veya sosyal medya uygulamasına ait olup olmadığını kontrol eder
  static bool isNativeMediaOrMessagingApp(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (isNativeScheme(scheme)) {
      return true;
    }

    final host = uri.host.toLowerCase();
    if (host.isNotEmpty) {
      for (final domain in _nativeAppDomains) {
        if (_isSameOrSubdomain(host, domain)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Yerel uygulamayı (WhatsApp, Instagram, Spotify, YouTube, Maps vb.) doğrudan harici uygulama olarak başlatır
  static Future<bool> handleNativeAppLaunch(Uri uri) async {
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('[DeepLinkService] Uygulama bulunamadı veya başlatılamıyor: $uri');
        // İsteğe bağlı olarak ilgili mağazaya yönlendirme gibi bir fallback eklenebilir.
        return false;
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Yerel uygulama başlatma hatası ($uri): $e');
      return false;
    }
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

  /// Verilen URI'nin iç domain listesinde, ana web sitesinde veya güvenlik doğrulama geçitlerinde olup olmadığını kontrol eder
  static bool isInternalDomain(Uri uri, List<String> internalDomains, String mainWebUrl) {
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return true;

    // 0. CAPTCHA ve Güvenlik Doğrulama Geçitleri Kontrolü (reCAPTCHA, Turnstile, hCaptcha vb.)
    if (isSecurityVerification(uri)) {
      return true;
    }

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
      await handleNativeAppLaunch(parsedUri);
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
