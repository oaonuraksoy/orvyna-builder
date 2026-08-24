import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/app_config.dart';

/// Webview içindeki reklam, pop-up ve izleyicileri engelleyen servis
class AdBlockService {
  final AdblockSettingsConfig config;
  final List<String> _blockedDomains = [];
  final List<String> _blockedSelectors = [];
  final List<RegExp> _blockedRegexPatterns = [];
  bool _isInitialized = false;

  AdBlockService({required this.config});

  /// Kuralları ve regex desenlerini yükler
  Future<void> initialize() async {
    if (!config.enabled) return;

    // 1. Config'deki selector ve pattern'leri ekle
    _blockedSelectors.addAll(config.blockedSelectors);
    for (final pattern in config.blockedUrlPatterns) {
      try {
        _blockedRegexPatterns.add(RegExp(pattern, caseSensitive: false));
      } catch (e) {
        // Hatalı regex deseni atlanır
      }
    }

    // 2. Dahili adblock_rules.json dosyasını yükle
    try {
      final jsonString = await rootBundle.loadString('assets/rules/adblock_rules.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final domains = (data['domains'] as List<dynamic>?)?.map((e) => e.toString()) ?? [];
      _blockedDomains.addAll(domains);

      final selectors = (data['selectors'] as List<dynamic>?)?.map((e) => e.toString()) ?? [];
      _blockedSelectors.addAll(selectors);
    } catch (_) {
      // Rule dosyası bulunamazsa config ile devam et
    }

    _isInitialized = true;
  }

  /// Verilen URL'nin engellenip engellenmeyeceğini denetler
  bool isUrlBlocked(WebUri? uri) {
    if (!config.enabled || uri == null) return false;

    final urlString = uri.toString();
    final host = uri.host.toLowerCase();

    // 1. Alan adı kontrolü
    if (config.blockKnownAdHosts) {
      for (final domain in _blockedDomains) {
        if (host == domain || host.endsWith('.$domain')) {
          return true;
        }
      }
    }

    // 2. Regex desen kontrolü
    for (final regex in _blockedRegexPatterns) {
      if (regex.hasMatch(urlString)) {
        return true;
      }
    }

    return false;
  }

  /// Sayfaya enjekte edilecek kozmetik engelleme CSS kodunu üretir
  String generateCosmeticCss() {
    if (!config.enabled || _blockedSelectors.isEmpty) return '';

    final uniqueSelectors = _blockedSelectors.toSet().toList();
    final joined = uniqueSelectors.join(', ');
    return '''
      $joined {
        display: none !important;
        visibility: hidden !important;
        height: 0 !important;
        opacity: 0 !important;
        pointer-events: none !important;
      }
    ''';
  }

  /// Sayfaya CSS ve DOM temizleyici script enjekte eder
  Future<void> injectCosmeticFilter(InAppWebViewController controller) async {
    if (!config.enabled) return;

    final css = generateCosmeticCss();
    if (css.isNotEmpty) {
      final js = '''
        (function() {
          var styleId = 'web2app-adblock-styles';
          var existingStyle = document.getElementById(styleId);
          if (!existingStyle) {
            var style = document.createElement('style');
            style.id = styleId;
            style.type = 'text/css';
            style.innerHTML = `$css`;
            document.head.appendChild(style);
          }
        })();
      ''';
      await controller.evaluateJavascript(source: js);
    }
  }

  bool get isInitialized => _isInitialized;
}
