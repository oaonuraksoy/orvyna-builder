import 'package:flutter_test/flutter_test.dart';
import 'package:orvyna_engine/models/app_config.dart';
import 'package:orvyna_engine/services/biometric_service.dart';

void main() {
  group('BiometricService Unit Tests', () {
    test('BiometricService disabled by default', () {
      final config = BiometricConfig.fromJson({});
      final service = BiometricService(config: config);

      expect(service.isEnabled, isFalse);
      expect(service.isAuthRequired, isFalse);
      expect(service.allowFallback, isTrue);
    });

    test('BiometricService enabled config behavior and timeout calculations', () {
      final config = BiometricConfig(
        enabled: true,
        promptTitle: 'Güvenlik Kontrolü',
        promptSubtitle: 'Parmak izinizi okutun',
        allowFallback: true,
        timeoutSeconds: 60,
      );
      final service = BiometricService(config: config);

      expect(service.isEnabled, isTrue);
      expect(service.allowFallback, isTrue);
      // Immediately, since no successful auth recorded yet, auth is required
      expect(service.isAuthRequired, isTrue);

      // Simulate lock
      service.lock();
      expect(service.isAuthRequired, isTrue);
    });

    test('BiometricConfig fromJson and toJson round-trip', () {
      final jsonMap = {
        'enabled': true,
        'prompt_title': 'Özel Kilit',
        'prompt_subtitle': 'Lütfen yüzünüzü taratın',
        'allow_fallback': false,
        'timeout_seconds': 30,
      };

      final config = BiometricConfig.fromJson(jsonMap);
      expect(config.enabled, isTrue);
      expect(config.promptTitle, equals('Özel Kilit'));
      expect(config.promptSubtitle, equals('Lütfen yüzünüzü taratın'));
      expect(config.allowFallback, isFalse);
      expect(config.timeoutSeconds, equals(30));

      final outputJson = config.toJson();
      expect(outputJson['enabled'], isTrue);
      expect(outputJson['prompt_title'], equals('Özel Kilit'));
      expect(outputJson['prompt_subtitle'], equals('Lütfen yüzünüzü taratın'));
      expect(outputJson['allow_fallback'], isFalse);
      expect(outputJson['timeout_seconds'], equals(30));
    });
  });
}
