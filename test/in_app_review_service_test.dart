import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_engine/models/app_config.dart';
import 'package:mobile_engine/services/in_app_review_service.dart';

void main() {
  group('InAppReviewService Unit Tests', () {
    test('InAppReviewService launch and action trigger thresholds', () {
      final config = InAppReviewConfig(
        enabled: true,
        launchCountTrigger: 3,
        daysUntilPrompt: 0,
        minActionsTrigger: 2,
        customReviewUrl: 'https://play.google.com/store/apps/details?id=com.example.app',
      );

      final service = InAppReviewService(
        config: config,
        packageName: 'com.example.app',
      );

      expect(service.isEnabled, isTrue);
      // Before reaching launch count (0 launches), should not prompt
      expect(service.shouldPromptReview(), isFalse);

      // Launch 1
      service.recordAppLaunch();
      expect(service.shouldPromptReview(), isFalse);

      // Launch 2
      service.recordAppLaunch();
      expect(service.shouldPromptReview(), isFalse);

      // Launch 3
      service.recordAppLaunch();
      // Needs minActionsTrigger (2 actions)
      expect(service.shouldPromptReview(), isFalse);

      service.recordUserAction();
      service.recordUserAction();

      // Now launch count is 3 and action count is 2 -> shouldPromptReview == true
      expect(service.shouldPromptReview(), isTrue);

      // Simulate review requested -> hasPrompted becomes true
      service.recordPromptShown();
      expect(service.shouldPromptReview(), isFalse);
    });

    test('InAppReviewConfig fromJson and toJson round-trip', () {
      final jsonMap = {
        'enabled': true,
        'launch_count_trigger': 4,
        'days_until_prompt': 5,
        'custom_review_url': 'https://custom.url/review',
        'min_actions_trigger': 8,
      };

      final config = InAppReviewConfig.fromJson(jsonMap);
      expect(config.enabled, isTrue);
      expect(config.launchCountTrigger, equals(4));
      expect(config.daysUntilPrompt, equals(5));
      expect(config.customReviewUrl, equals('https://custom.url/review'));
      expect(config.minActionsTrigger, equals(8));

      final output = config.toJson();
      expect(output['enabled'], isTrue);
      expect(output['launch_count_trigger'], equals(4));
      expect(output['days_until_prompt'], equals(5));
      expect(output['custom_review_url'], equals('https://custom.url/review'));
      expect(output['min_actions_trigger'], equals(8));
    });
  });
}
