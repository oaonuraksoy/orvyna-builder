import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orvyna_engine/models/app_config.dart';
import 'package:orvyna_engine/widgets/floating_support_button.dart';

void main() {
  group('FloatingSupportButton Widget & Config Tests', () {
    test('FloatingButtonConfig fromJson and toJson round-trip', () {
      final jsonMap = {
        'enabled': true,
        'type': 'whatsapp',
        'target': '+905551234567',
        'icon': 'whatsapp',
        'position': 'bottomRight',
        'background_color': '#25D366',
        'label': 'WhatsApp',
        'tooltip': 'Canlı Destek',
        'show_badge': true,
      };

      final config = FloatingButtonConfig.fromJson(jsonMap);
      expect(config.enabled, isTrue);
      expect(config.type, equals('whatsapp'));
      expect(config.target, equals('+905551234567'));
      expect(config.position, equals('bottomRight'));
      expect(config.backgroundColor, equals(const Color(0xFF25D366)));
      expect(config.label, equals('WhatsApp'));
      expect(config.tooltip, equals('Canlı Destek'));
      expect(config.showBadge, isTrue);

      final output = config.toJson();
      expect(output['enabled'], isTrue);
      expect(output['type'], equals('whatsapp'));
      expect(output['target'], equals('+905551234567'));
      expect(output['position'], equals('bottomRight'));
      expect(output['label'], equals('WhatsApp'));
      expect(output['show_badge'], isTrue);
    });

    testWidgets('FloatingSupportButton renders correctly in widget tree', (tester) async {
      final config = FloatingButtonConfig(
        enabled: true,
        type: 'whatsapp',
        target: '+905551234567',
        icon: 'whatsapp',
        position: 'bottomRight',
        backgroundColorHex: '#25D366',
        label: 'Destek',
        tooltip: 'WhatsApp Hattı',
        showBadge: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('App Content')),
                FloatingSupportButton(config: config),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Destek'), findsOneWidget);
      expect(find.byType(FloatingSupportButton), findsOneWidget);
    });
  });
}
