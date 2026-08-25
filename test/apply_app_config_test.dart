import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import '../tool/apply_app_config.dart';

void main() {
  group('apply_app_config.dart Script Tests', () {
    late Directory tempDir;
    late File testConfigFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('apply_app_config_test_');

      // Setup minimal test config
      testConfigFile = File('${tempDir.path}/app_config.json');
      final configMap = {
        'version': '1.0.0',
        'app_info': {
          'app_name': 'My Super App',
          'package_name': 'com.mysuper.app',
          'web_url': 'https://mysuperapp.com',
          'app_version': '3.2.1',
          'build_number': 99,
        },
        'theme': {
          'primary_color': '#2563EB',
          'accent_color': '#3B82F6',
          'background_color': '#FFFFFF',
          'status_bar_color': '#1D4ED8',
        },
        'assets': {
          'icon_base64': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
          'splash_base64': 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        },
        'signing': {
          'keystore_base64': 'RFVNTVlfS0VZU1RPUkVfQkFTRTY0',
          'keystore_password': 'storePassword123',
          'key_alias': 'mySuperAlias',
          'key_password': 'keyPassword123',
        },
        'app_store_connect': {
          'issuer_id': '69a6de70-ba49-47e5-e053-5b8c7c11a4d1',
          'key_id': 'D383X7Y27K',
          'p8_base64': 'TUlJRUV2Z0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktnd2dnU2tBZ0VBQW9JQkFRQzRk',
        },
      };
      testConfigFile.writeAsStringSync(json.encode(configMap));

      // Create fake android structure
      final manifest = File('${tempDir.path}/android/app/src/main/AndroidManifest.xml');
      manifest.parent.createSync(recursive: true);
      manifest.writeAsStringSync('''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.old.app">
    <application
        android:label="Old App Name"
        android:name="\${applicationName}">
    </application>
</manifest>
''');

      final buildGradle = File('${tempDir.path}/android/app/build.gradle');
      buildGradle.parent.createSync(recursive: true);
      buildGradle.writeAsStringSync('''android {
    namespace = "com.old.app"
    defaultConfig {
        applicationId = "com.old.app"
    }
}
''');

      // Create fake iOS structure
      final infoPlist = File('${tempDir.path}/ios/Runner/Info.plist');
      infoPlist.parent.createSync(recursive: true);
      infoPlist.writeAsStringSync('''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key>
	<string>Old App Name</string>
	<key>CFBundleName</key>
	<string>Old App Name</string>
</dict>
</plist>
''');

      final pbxproj = File('${tempDir.path}/ios/Runner.xcodeproj/project.pbxproj');
      pbxproj.parent.createSync(recursive: true);
      pbxproj.writeAsStringSync('''PRODUCT_BUNDLE_IDENTIFIER = com.old.app;''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('applyAppConfig successfully transforms Android and iOS projects in disk', () {
      applyAppConfig(
        configPath: testConfigFile.path,
        platform: 'all',
        baseDir: tempDir,
      );

      // 1. Android Manifest Verification
      final manifest = File('${tempDir.path}/android/app/src/main/AndroidManifest.xml');
      final manifestContent = manifest.readAsStringSync(encoding: utf8);
      expect(manifestContent, contains('android:label="@string/app_name"'));
      expect(manifestContent, contains('package="com.mysuper.app"'));
      expect(manifestContent, contains('com.google.android.gms.ads.APPLICATION_ID'));
      expect(manifestContent, contains('ca-app-pub-3940256099942544~3347511713'));

      // Android strings.xml Verification
      final stringsFile = File('${tempDir.path}/android/app/src/main/res/values/strings.xml');
      expect(stringsFile.existsSync(), isTrue);
      final stringsContent = stringsFile.readAsStringSync(encoding: utf8);
      expect(stringsContent, contains('<string name="app_name">My Super App</string>'));

      // 2. Android build.gradle Verification
      final buildGradle = File('${tempDir.path}/android/app/build.gradle');
      final gradleContent = buildGradle.readAsStringSync(encoding: utf8);
      expect(gradleContent, contains('applicationId = "com.mysuper.app"'));
      expect(gradleContent, contains('namespace = "com.mysuper.app"'));

      // 3. Android Mipmap Icons & Adaptive Icon Verification
      final mipmapHdpi = File('${tempDir.path}/android/app/src/main/res/mipmap-hdpi/ic_launcher.png');
      expect(mipmapHdpi.existsSync(), isTrue);
      expect(mipmapHdpi.lengthSync(), greaterThan(0));

      final mipmapFgHdpi = File('${tempDir.path}/android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png');
      expect(mipmapFgHdpi.existsSync(), isTrue);
      expect(mipmapFgHdpi.lengthSync(), greaterThan(0));

      final adaptiveXml = File('${tempDir.path}/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml');
      expect(adaptiveXml.existsSync(), isTrue);
      expect(adaptiveXml.readAsStringSync(encoding: utf8), contains('@mipmap/ic_launcher_foreground'));

      // Android Styles & Themes Verification
      final stylesXml = File('${tempDir.path}/android/app/src/main/res/values/styles.xml');
      expect(stylesXml.existsSync(), isTrue);
      expect(stylesXml.readAsStringSync(encoding: utf8), contains('name="LaunchTheme"'));

      final nightStylesXml = File('${tempDir.path}/android/app/src/main/res/values-night/styles.xml');
      expect(nightStylesXml.existsSync(), isTrue);
      expect(nightStylesXml.readAsStringSync(encoding: utf8), contains('Theme.Black.NoTitleBar'));

      final launchBgXml = File('${tempDir.path}/android/app/src/main/res/drawable/launch_background.xml');
      expect(launchBgXml.existsSync(), isTrue);
      expect(launchBgXml.readAsStringSync(encoding: utf8), contains('@android:color/white'));

      // 4. Android Keystore and key.properties Verification
      final keystore = File('${tempDir.path}/android/upload.keystore');
      expect(keystore.existsSync(), isTrue);
      expect(keystore.readAsStringSync(encoding: utf8), equals('DUMMY_KEYSTORE_BASE64'));

      final keyProps = File('${tempDir.path}/android/key.properties');
      expect(keyProps.existsSync(), isTrue);
      final keyPropsContent = keyProps.readAsStringSync(encoding: utf8);
      expect(keyPropsContent, contains('storePassword=storePassword123'));
      expect(keyPropsContent, contains('keyAlias=mySuperAlias'));
      expect(keyPropsContent, contains('keyPassword=keyPassword123'));

      // 5. iOS Info.plist Verification
      final infoPlist = File('${tempDir.path}/ios/Runner/Info.plist');
      final plistContent = infoPlist.readAsStringSync(encoding: utf8);
      expect(plistContent, contains('<string>My Super App</string>'));

      // 6. iOS project.pbxproj Verification
      final pbxproj = File('${tempDir.path}/ios/Runner.xcodeproj/project.pbxproj');
      final pbxContent = pbxproj.readAsStringSync(encoding: utf8);
      expect(pbxContent, contains('PRODUCT_BUNDLE_IDENTIFIER = com.mysuper.app;'));

      // 7. iOS AppIcon Verification
      final appIcon1024 = File('${tempDir.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png');
      expect(appIcon1024.existsSync(), isTrue);
      expect(appIcon1024.lengthSync(), greaterThan(0));

      // 8. iOS Fastlane & AuthKey Verification
      final p8Key = File('${tempDir.path}/ios/fastlane/AuthKey_D383X7Y27K.p8');
      expect(p8Key.existsSync(), isTrue);

      final fastfile = File('${tempDir.path}/ios/fastlane/Fastfile');
      expect(fastfile.existsSync(), isTrue);
      expect(fastfile.readAsStringSync(encoding: utf8), contains('D383X7Y27K'));
    });

    test('applyAppConfig falls back to default Android icons when icon_base64 is empty', () {
      final noIconConfigFile = File('${tempDir.path}/app_config_no_icon.json');
      final configMap = {
        'version': '1.0.0',
        'app_info': {
          'app_name': 'Default Icon App',
          'package_name': 'com.defaulticon.app',
        },
        'assets': {
          'icon_base64': '',
        },
      };
      noIconConfigFile.writeAsStringSync(json.encode(configMap), encoding: utf8);

      applyAppConfig(
        configPath: noIconConfigFile.path,
        platform: 'android',
        baseDir: tempDir,
      );

      final mipmapDirs = [
        'mipmap-mdpi',
        'mipmap-hdpi',
        'mipmap-xhdpi',
        'mipmap-xxhdpi',
        'mipmap-xxxhdpi',
      ];

      for (final dir in mipmapDirs) {
        final iconFile = File('${tempDir.path}/android/app/src/main/res/$dir/ic_launcher.png');
        expect(iconFile.existsSync(), isTrue);
        expect(iconFile.lengthSync(), greaterThan(0));
      }
    });

    test('applyAppConfig correctly handles custom AdMob ID and Turkish UTF-8 characters', () {
      final turkishConfigFile = File('${tempDir.path}/app_config_turkish.json');
      const turkishAppName = 'Türkçe Uygulama Adı ğüşöçıİ ÖĞÜŞÇİ';
      const customAdmobId = 'ca-app-pub-1234567890123456~9876543210';

      final configMap = {
        'version': '1.0.0',
        'app_info': {
          'app_name': turkishAppName,
          'package_name': 'com.turkish.app',
        },
        'monetization': {
          'admob_app_id_android': customAdmobId,
        },
      };
      turkishConfigFile.writeAsStringSync(json.encode(configMap), encoding: utf8);

      applyAppConfig(
        configPath: turkishConfigFile.path,
        platform: 'android',
        baseDir: tempDir,
      );

      // Verify strings.xml contains exact Turkish characters
      final stringsFile = File('${tempDir.path}/android/app/src/main/res/values/strings.xml');
      expect(stringsFile.existsSync(), isTrue);
      final stringsContent = stringsFile.readAsStringSync(encoding: utf8);
      expect(stringsContent, contains('<string name="app_name">$turkishAppName</string>'));

      // Verify AndroidManifest.xml contains custom AdMob ID and @string/app_name
      final manifest = File('${tempDir.path}/android/app/src/main/AndroidManifest.xml');
      final manifestContent = manifest.readAsStringSync(encoding: utf8);
      expect(manifestContent, contains('android:label="@string/app_name"'));
      expect(manifestContent, contains(customAdmobId));
    });

    test('applyAppConfig center crops rectangular icons and generates all mipmap & adaptive resolutions', () {
      // Create a 800x400 rectangular image (portrait or landscape)
      final rectImage = img.Image(width: 800, height: 400);
      img.fill(rectImage, color: img.ColorRgb8(0, 128, 255));
      final rawPng = img.encodePng(rectImage);
      final rawBase64 = base64Encode(rawPng);

      final rectConfigFile = File('${tempDir.path}/app_config_rect.json');
      final configMap = {
        'version': '1.0.0',
        'app_info': {
          'app_name': 'Crop Test App',
          'package_name': 'com.crop.app',
        },
        'assets': {
          'icon_base64': rawBase64,
        },
      };
      rectConfigFile.writeAsStringSync(json.encode(configMap), encoding: utf8);

      applyAppConfig(
        configPath: rectConfigFile.path,
        platform: 'all',
        baseDir: tempDir,
      );

      final expectedLauncherSizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
      };

      final expectedFgSizes = {
        'mipmap-mdpi': 108,
        'mipmap-hdpi': 162,
        'mipmap-xhdpi': 216,
        'mipmap-xxhdpi': 324,
        'mipmap-xxxhdpi': 432,
      };

      for (final entry in expectedLauncherSizes.entries) {
        final iconFile = File('${tempDir.path}/android/app/src/main/res/${entry.key}/ic_launcher.png');
        expect(iconFile.existsSync(), isTrue);
        final decoded = img.decodeImage(iconFile.readAsBytesSync());
        expect(decoded, isNotNull);
        expect(decoded!.width, equals(entry.value));
        expect(decoded.height, equals(entry.value));
      }

      for (final entry in expectedFgSizes.entries) {
        final fgFile = File('${tempDir.path}/android/app/src/main/res/${entry.key}/ic_launcher_foreground.png');
        expect(fgFile.existsSync(), isTrue);
        final decoded = img.decodeImage(fgFile.readAsBytesSync());
        expect(decoded, isNotNull);
        expect(decoded!.width, equals(entry.value));
        expect(decoded.height, equals(entry.value));
      }

      // Verify iOS AppIcon is square 1024x1024
      final iosIcon = File('${tempDir.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png');
      expect(iosIcon.existsSync(), isTrue);
      final decodedIos = img.decodeImage(iosIcon.readAsBytesSync());
      expect(decodedIos, isNotNull);
      expect(decodedIos!.width, equals(1024));
      expect(decodedIos.height, equals(1024));
    });
  });
}
