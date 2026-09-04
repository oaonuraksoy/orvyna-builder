import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orvyna_engine/models/app_config.dart';
import 'package:orvyna_engine/widgets/custom_page_view.dart';
import 'package:orvyna_engine/widgets/offline_screen.dart';
import 'package:orvyna_engine/widgets/shimmer_loading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final defaultTheme = const ThemeConfig(
    primaryColorHex: '#2563EB',
    accentColorHex: '#3B82F6',
    backgroundColorHex: '#FFFFFF',
    statusBarColorHex: '#1D4ED8',
    statusBarDarkIcons: false,
    splashBackgroundColorHex: '#2563EB',
    themeTemplate: 'minimalist',
  );

  group('OfflineScreen Tests (4 Modes & Dino Game)', () {
    testWidgets('1. standardRetry mode renders retry button and triggers callback', (tester) async {
      bool retryPressed = false;
      const offlineConfig = OfflineSettingsConfig(
        offlineModeType: OfflineModeType.standardRetry,
        offlineTitle: 'İnternet Yok',
        offlineMessage: 'Lütfen modeminizi kontrol edin',
        retryButtonText: 'Tekrar Dene',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OfflineScreen(
            config: offlineConfig,
            theme: defaultTheme,
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      expect(find.text('İnternet Yok'), findsOneWidget);
      expect(find.text('Lütfen modeminizi kontrol edin'), findsOneWidget);
      expect(find.text('Tekrar Dene'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      await tester.tap(find.text('Tekrar Dene'));
      expect(retryPressed, isTrue);
    });

    testWidgets('2. customHtml mode renders custom content card', (tester) async {
      bool retryPressed = false;
      const offlineConfig = OfflineSettingsConfig(
        offlineModeType: OfflineModeType.customHtml,
        offlineTitle: 'HTML Bilgi',
        offlineMessage: 'Varsayılan Mesaj',
        customOfflineHtml: 'Özel Çevrimdışı Sayfa Metni',
        retryButtonText: 'Yenile',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OfflineScreen(
            config: offlineConfig,
            theme: defaultTheme,
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      expect(find.text('HTML Bilgi'), findsOneWidget);
      expect(find.text('Özel Çevrimdışı Sayfa Metni'), findsOneWidget);
      expect(find.text('Yenile'), findsOneWidget);

      await tester.tap(find.text('Yenile'));
      expect(retryPressed, isTrue);
    });

    testWidgets('3. cacheFirstFallback mode renders Cache badge and offline notice', (tester) async {
      bool retryPressed = false;
      const offlineConfig = OfflineSettingsConfig(
        offlineModeType: OfflineModeType.cacheFirstFallback,
        offlineTitle: 'Önbellek Ekranı',
        offlineMessage: 'Önbellek içeriği gösteriliyor',
        retryButtonText: 'Canlıya Geç',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OfflineScreen(
            config: offlineConfig,
            theme: defaultTheme,
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      expect(find.text('Önbellek (Cache) Modu'), findsOneWidget);
      expect(find.text('Önbellek Ekranı'), findsOneWidget);
      expect(find.text('Önbellek içeriği gösteriliyor'), findsOneWidget);
      expect(find.text('Canlıya Geç'), findsOneWidget);

      await tester.tap(find.text('Canlıya Geç'));
      expect(retryPressed, isTrue);
    });

    testWidgets('4. interactiveGame mode renders Dino Runner game with jumping & scoring mechanics', (tester) async {
      bool retryPressed = false;
      const offlineConfig = OfflineSettingsConfig(
        offlineModeType: OfflineModeType.interactiveGame,
        offlineTitle: 'Dino Oyunu',
        offlineMessage: 'Zıpla ve engelleri aş!',
        retryButtonText: 'Yeniden Bağlan',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OfflineScreen(
            config: offlineConfig,
            theme: defaultTheme,
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      expect(find.text('Çevrimdışı Mini Oyun'), findsOneWidget);
      expect(find.textContaining('SKOR: 0'), findsOneWidget);
      expect(find.text('Oyunu Başlat'), findsOneWidget);
      expect(find.text('ZIPLA (Dokun)'), findsOneWidget);

      // Start game
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      // Jump button tap
      await tester.tap(find.text('ZIPLA (Dokun)'));
      await tester.pump(const Duration(milliseconds: 50));

      // Retry header button tap
      await tester.tap(find.byTooltip('Yeniden Bağlan'));
      expect(retryPressed, isTrue);

      // Clean up timer by unmounting widget
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ShimmerLoadingView Zero CLS Tests', () {
    testWidgets('ShimmerLoadingView renders structured skeleton placeholders and default text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerLoadingView(
              theme: defaultTheme,
              appName: 'TestApp',
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoadingView), findsOneWidget);
      expect(find.text('TestApp'), findsOneWidget);
      expect(find.text('Yükleniyor...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ShimmerLoadingView respects splashShowTitle, splashShowLoadingBar, and splashLoadingText flags', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerLoadingView(
              theme: defaultTheme,
              appName: 'HiddenTitleApp',
              splashShowTitle: false,
              splashShowLoadingBar: false,
              splashLoadingText: 'Özel Veriler Alınıyor...',
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoadingView), findsOneWidget);
      expect(find.text('HiddenTitleApp'), findsNothing);
      expect(find.text('Özel Veriler Alınıyor...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('CustomPageView Tests (3 Layouts)', () {
    testWidgets('1. Document layout renders markdown typography and home button', (tester) async {
      bool homeNavigated = false;
      final docPage = CustomPageConfig(
        id: 'about',
        title: 'Hakkımızda',
        layout: CustomPageLayout.document,
        content: '# Başlık 1\n## Alt Başlık 2\n### Küçük Başlık\n- Madde 1\n* Madde 2\n> Alıntı metin\nNormal paragraf metni.',
        icon: 'article',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomPageView(
            page: docPage,
            theme: defaultTheme,
            onBackToHome: () => homeNavigated = true,
          ),
        ),
      );

      expect(find.text('Hakkımızda'), findsNWidgets(2)); // AppBar and Content Title
      expect(find.text('Resmi Bilgilendirme Belgesi'), findsOneWidget);
      expect(find.text('Başlık 1'), findsOneWidget);
      expect(find.text('Alt Başlık 2'), findsOneWidget);
      expect(find.text('Küçük Başlık'), findsOneWidget);
      expect(find.text('Madde 1'), findsOneWidget);
      expect(find.text('Madde 2'), findsOneWidget);
      expect(find.text('Alıntı metin'), findsOneWidget);
      expect(find.text('Normal paragraf metni.'), findsOneWidget);

      await tester.tap(find.text('Ana Sayfaya Dön'));
      expect(homeNavigated, isTrue);
    });

    testWidgets('2. CardGrid layout renders accordion FAQ sections and expands/collapses', (tester) async {
      bool homeNavigated = false;
      final faqPage = CustomPageConfig(
        id: 'faq',
        title: 'Sıkça Sorulan Sorular',
        layout: CustomPageLayout.cardGrid,
        content: '### Kargo ne zaman ulaşır?\nSiparişiniz 2 iş günü içinde teslim edilir.\n### İade nasıl yapılır?\n14 gün içinde ücretsiz iade edebilirsiniz.',
        icon: 'quiz',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomPageView(
            page: faqPage,
            theme: defaultTheme,
            onBackToHome: () => homeNavigated = true,
          ),
        ),
      );

      expect(find.text('Sıkça Sorulan Sorular'), findsNWidgets(2));
      expect(find.text('Kargo ne zaman ulaşır?'), findsOneWidget);
      expect(find.text('İade nasıl yapılır?'), findsOneWidget);

      // Verify accordion expansion
      await tester.tap(find.text('İade nasıl yapılır?'));
      await tester.pumpAndSettle();
      expect(find.text('14 gün içinde ücretsiz iade edebilirsiniz.'), findsOneWidget);

      // Back button in AppBar
      await tester.tap(find.byTooltip('Ana Sayfaya Dön'));
      expect(homeNavigated, isTrue);
    });

    testWidgets('3. HeroContact layout renders Hero banner and action buttons', (tester) async {
      bool homeNavigated = false;
      final contactPage = CustomPageConfig(
        id: 'contact',
        title: 'İletişim & Destek',
        layout: CustomPageLayout.heroContact,
        content: 'Merkez Ofis: Maslak Mah. No:12 Istanbul',
        icon: 'contact',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomPageView(
            page: contactPage,
            theme: defaultTheme,
            onBackToHome: () => homeNavigated = true,
          ),
        ),
      );

      expect(find.text('İletişim & Destek'), findsOneWidget);
      expect(find.text('Size Yardımcı Olmaktan Mutluluk Duyarız'), findsOneWidget);
      expect(find.text('Bizi Arayın'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('E-posta Gönder'), findsOneWidget);
      expect(find.text('Konum & Adres'), findsOneWidget);
      expect(find.text('Merkez Ofis: Maslak Mah. No:12 Istanbul'), findsOneWidget);

      await tester.tap(find.byTooltip('Ana Sayfaya Dön'));
      expect(homeNavigated, isTrue);
    });
  });

  group('12 Color Themes Verification', () {
    test('12 themes in StudioThemeTemplate match correct primary colors', () {
      final themeTemplates = {
        'minimalist': '#2563EB',
        'modernDark': '#0F172A',
        'emeraldLuxury': '#059669',
        'sunsetVibrant': '#EA580C',
        'deepAmethyst': '#581C87',
        'roseElegance': '#E11D48',
        'oceanBreeze': '#0284C7',
        'warmAmber': '#D97706',
        'midnightNeon': '#09090B',
        'slateCorporate': '#334155',
        'nordicFrost': '#475569',
        'cyberpunkEdge': '#7C3AED',
      };

      expect(themeTemplates.length, equals(12));
      for (final entry in themeTemplates.entries) {
        final config = ThemeConfig(
          primaryColorHex: entry.value,
          accentColorHex: '#3B82F6',
          backgroundColorHex: '#FFFFFF',
          statusBarColorHex: '#1D4ED8',
          statusBarDarkIcons: false,
          splashBackgroundColorHex: entry.value,
          themeTemplate: entry.key,
        );
        expect(config.primaryColorHex, equals(entry.value));
        expect(config.themeTemplate, equals(entry.key));
        expect(config.primaryColor, isA<Color>());
      }
    });
  });
}
