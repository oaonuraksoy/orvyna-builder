import 'dart:convert';
import 'dart:io';

/// Web2App Bulut & CI/CD Konfigürasyon Uygulayıcı (Build Preprocessor)
///
/// Bu fonksiyon / script, enjekte edilmiş `app_config.json` dosyasını okuyarak:
/// 1. AndroidManifest.xml içindeki `android:label` (@string/app_name), AdMob meta-data ve strings.xml değerlerini günceller.
/// 2. android/app/build.gradle içindeki `applicationId` ve `namespace` değerlerini günceller.
/// 3. assets.icon_base64 ve splash_base64 verilerini Android mipmap-* ve iOS AppIcon varlıklarına dönüştürür.
/// 4. signing.keystore_base64 verisinden `upload.keystore` ve `key.properties` dosyalarını üretir.
/// 5. iOS Info.plist (`CFBundleDisplayName`) ve project.pbxproj (`PRODUCT_BUNDLE_IDENTIFIER`) değerlerini günceller.
/// 6. App Store Connect p8 API anahtarını ve Fastlane yapılandırmasını oluşturur.
void applyAppConfig({
  String configPath = 'assets/config/app_config.json',
  String platform = 'all',
  Directory? baseDir,
}) {
  print('================================================================');
  print('🚀 [Web2App] Konfigürasyon Ön-Hazırlık ve Otomatik Uygulama Başladı');
  print('================================================================');

  Directory workingDir = baseDir ?? Directory.current;
  File configFile = File(configPath);

  if (!configFile.isAbsolute) {
    configFile = File('${workingDir.path}/$configPath');
    if (!configFile.existsSync()) {
      final candidateInMobileEngine = File('mobile_engine/$configPath');
      if (candidateInMobileEngine.existsSync()) {
        workingDir = Directory('mobile_engine');
        configFile = candidateInMobileEngine;
      }
    }
  }

  if (!configFile.existsSync()) {
    print('⚠️ [Web2App] Konfigürasyon dosyası bulunamadı: ${configFile.path}');
    print('ℹ️ Varsayılan ayarlar korunacak.');
    return;
  }

  print('📄 Konfigürasyon dosyası okunuyor: ${configFile.path}');
  final String content = configFile.readAsStringSync(encoding: utf8);
  final Map<String, dynamic> config;
  try {
    config = json.decode(content) as Map<String, dynamic>;
  } catch (e) {
    print('❌ [Web2App] JSON ayrıştırma hatası: $e');
    throw FormatException('Invalid JSON in app_config: $e');
  }

  final appInfo = config['app_info'] as Map<String, dynamic>? ?? {};
  final assets = config['assets'] as Map<String, dynamic>? ?? {};
  final signing = config['signing'] as Map<String, dynamic>? ?? {};
  final appStore = config['app_store_connect'] as Map<String, dynamic>? ?? {};
  final monetization = config['monetization'] as Map<String, dynamic>? ?? {};

  final String appName = appInfo['app_name']?.toString() ?? appInfo['name']?.toString() ?? 'Web2App';
  final String packageName = appInfo['package_name']?.toString() ?? appInfo['package']?.toString() ?? 'com.web2app.app';
  final String appVersion = appInfo['app_version']?.toString() ?? '1.0.0';
  final int buildNumber = (appInfo['build_number'] as num?)?.toInt() ?? 1;

  final String rawAdmobAppId = (config['admob_app_id'] ??
          monetization['admob_app_id_android'] ??
          monetization['admob_app_id'] ??
          appInfo['admob_app_id'])
      ?.toString()
      .trim() ??
      '';
  final String admobAppId = rawAdmobAppId.isNotEmpty
      ? rawAdmobAppId
      : 'ca-app-pub-3940256099942544~3347511713';

  final String iconBase64 = assets['icon_base64']?.toString() ?? assets['icon']?.toString() ?? '';
  final String splashBase64 = assets['splash_base64']?.toString() ?? assets['splash']?.toString() ?? '';

  final String keystoreBase64 = signing['keystore_base64']?.toString() ?? '';
  final String keystorePassword = signing['keystore_password']?.toString() ?? '';
  final String keyAlias = signing['key_alias']?.toString() ?? 'upload';
  final String keyPassword = signing['key_password']?.toString() ?? keystorePassword;

  final String appStoreIssuerId = appStore['issuer_id']?.toString() ?? '';
  final String appStoreKeyId = appStore['key_id']?.toString() ?? '';
  final String appStoreP8Base64 = appStore['p8_base64']?.toString() ?? '';

  print('📦 Uygulama Adı      : $appName');
  print('🆔 Paket Kimliği     : $packageName');
  print('🏷️  Sürüm              : v$appVersion+$buildNumber');
  print('📢 AdMob App ID       : $admobAppId');
  print('🎨 İkon Base64       : ${iconBase64.isNotEmpty ? "Mevcut (${(iconBase64.length / 1024).toStringAsFixed(1)} KB)" : "Yok (Varsayılan)"}');
  print('🔑 Keystore          : ${keystoreBase64.isNotEmpty ? "Mevcut (${(keystoreBase64.length / 1024).toStringAsFixed(1)} KB)" : "Yok (Debug/Unsigned)"}');
  print('🍎 TestFlight p8     : ${appStoreP8Base64.isNotEmpty ? "Mevcut (Key: $appStoreKeyId)" : "Yok"}');

  final String androidRoot = '${workingDir.path}/android';
  final String iosRoot = '${workingDir.path}/ios';

  // 1. ANDROID UYGULAMALARI
  if (platform == 'all' || platform == 'android') {
    print('\n🤖 [Android] Yapılandırmalar uygulanıyor ($androidRoot)...');
    _applyAndroidConfig(
      androidRoot: androidRoot,
      appName: appName,
      packageName: packageName,
      admobAppId: admobAppId,
      iconBase64: iconBase64,
      splashBase64: splashBase64,
      keystoreBase64: keystoreBase64,
      keystorePassword: keystorePassword,
      keyAlias: keyAlias,
      keyPassword: keyPassword,
    );
  }

  // 2. IOS UYGULAMALARI
  if (platform == 'all' || platform == 'ios') {
    print('\n🍏 [iOS] Yapılandırmalar uygulanıyor ($iosRoot)...');
    _applyIosConfig(
      iosRoot: iosRoot,
      appName: appName,
      packageName: packageName,
      iconBase64: iconBase64,
      appStoreIssuerId: appStoreIssuerId,
      appStoreKeyId: appStoreKeyId,
      appStoreP8Base64: appStoreP8Base64,
    );
  }

  print('\n✅ [Web2App] Tüm yapılandırmalar başarıyla uygulandı!\n');
}

void main(List<String> args) {
  String configPath = 'assets/config/app_config.json';
  String platform = 'all';

  for (final arg in args) {
    if (arg.startsWith('--config=')) {
      configPath = arg.substring('--config='.length);
    } else if (arg.startsWith('--platform=')) {
      platform = arg.substring('--platform='.length).toLowerCase();
    }
  }

  applyAppConfig(configPath: configPath, platform: platform);
}

/// Android Proje Dosyalarını Günceller
void _applyAndroidConfig({
  required String androidRoot,
  required String appName,
  required String packageName,
  required String admobAppId,
  required String iconBase64,
  required String splashBase64,
  required String keystoreBase64,
  required String keystorePassword,
  required String keyAlias,
  required String keyPassword,
}) {
  // 1. AndroidManifest.xml
  final manifestFile = File('$androidRoot/app/src/main/AndroidManifest.xml');
  if (manifestFile.existsSync()) {
    var manifestContent = manifestFile.readAsStringSync(encoding: utf8);
    manifestContent = manifestContent.replaceAll(
      RegExp(r'android:label="[^"]*"'),
      'android:label="@string/app_name"',
    );
    if (manifestContent.contains('package="')) {
      manifestContent = manifestContent.replaceAll(
        RegExp(r'package="[^"]*"'),
        'package="$packageName"',
      );
    }

    final admobRegex = RegExp(
      r'<meta-data\s+[^>]*android:name="com\.google\.android\.gms\.ads\.APPLICATION_ID"[^>]*\/?>',
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );
    if (admobRegex.hasMatch(manifestContent)) {
      manifestContent = manifestContent.replaceAll(
        admobRegex,
        '<meta-data\n            android:name="com.google.android.gms.ads.APPLICATION_ID"\n            android:value="$admobAppId"/>',
      );
    } else {
      manifestContent = manifestContent.replaceFirst(
        '</application>',
        '    <meta-data\n            android:name="com.google.android.gms.ads.APPLICATION_ID"\n            android:value="$admobAppId"/>\n    </application>',
      );
    }

    manifestFile.writeAsStringSync(manifestContent, encoding: utf8);
    print('  ✓ AndroidManifest.xml güncellendi (android:label="@string/app_name", AdMob ID="$admobAppId")');
  } else {
    manifestFile.parent.createSync(recursive: true);
    manifestFile.writeAsStringSync('''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$packageName">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <application
        android:label="@string/app_name"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="$admobAppId"/>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''', encoding: utf8);
    print('  ✓ AndroidManifest.xml oluşturuldu (android:label="@string/app_name", AdMob ID="$admobAppId")');
  }

  // 2. strings.xml
  final stringsFile = File('$androidRoot/app/src/main/res/values/strings.xml');
  stringsFile.parent.createSync(recursive: true);
  stringsFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">$appName</string>
</resources>
''', encoding: utf8);
  print('  ✓ res/values/strings.xml güncellendi');

  final stylesFile = File('$androidRoot/app/src/main/res/values/styles.xml');
  if (!stylesFile.existsSync()) {
    stylesFile.parent.createSync(recursive: true);
    stylesFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
''', encoding: utf8);
    print('  ✓ res/values/styles.xml oluşturuldu');
  }

  final nightStylesFile = File('$androidRoot/app/src/main/res/values-night/styles.xml');
  if (!nightStylesFile.existsSync()) {
    nightStylesFile.parent.createSync(recursive: true);
    nightStylesFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
''', encoding: utf8);
    print('  ✓ res/values-night/styles.xml oluşturuldu');
  }

  final launchBgFile = File('$androidRoot/app/src/main/res/drawable/launch_background.xml');
  if (!launchBgFile.existsSync()) {
    launchBgFile.parent.createSync(recursive: true);
    launchBgFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
</layer-list>
''', encoding: utf8);
    print('  ✓ res/drawable/launch_background.xml oluşturuldu');
  }

  // 3. android/app/build.gradle
  final appBuildGradle = File('$androidRoot/app/build.gradle');
  if (appBuildGradle.existsSync()) {
    var content = appBuildGradle.readAsStringSync(encoding: utf8);
    content = content.replaceAll(
      RegExp(r'applicationId\s*=?\s*["\x27][^"\x27]+["\x27]'),
      'applicationId = "$packageName"',
    );
    content = content.replaceAll(
      RegExp(r'namespace\s*=?\s*["\x27][^"\x27]+["\x27]'),
      'namespace = "$packageName"',
    );
    appBuildGradle.writeAsStringSync(content, encoding: utf8);
    print('  ✓ android/app/build.gradle güncellendi (applicationId="$packageName")');
  } else {
    appBuildGradle.parent.createSync(recursive: true);
    appBuildGradle.writeAsStringSync('''plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "$packageName"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId = "$packageName"
        minSdk = 21
        targetSdk = 35
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
    }

    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties['keyAlias']
                keyPassword = keystoreProperties['keyPassword']
                storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
                storePassword = keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            signingConfig = keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug
            minifyEnabled = false
            shrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
''', encoding: utf8);
    print('  ✓ android/app/build.gradle oluşturuldu');
  }

  // 4. İkon Dosyaları (Base64 -> PNG)
  final resDir = Directory('$androidRoot/app/src/main/res');
  if (iconBase64.isNotEmpty) {
    try {
      final bytes = base64Decode(iconBase64.replaceAll(RegExp(r'\s+'), ''));
      final mipmapDirs = [
        'mipmap-mdpi',
        'mipmap-hdpi',
        'mipmap-xhdpi',
        'mipmap-xxhdpi',
        'mipmap-xxxhdpi',
      ];
      for (final dir in mipmapDirs) {
        final iconFile = File('${resDir.path}/$dir/ic_launcher.png');
        iconFile.parent.createSync(recursive: true);
        iconFile.writeAsBytesSync(bytes);
      }
      print('  ✓ Android mipmap ikonları Base64 verisinden üretildi (5 çözünürlük)');
    } catch (e) {
      print('  ⚠️ İkon Base64 çözülemedi: $e');
      _ensureDefaultAndroidIcons(resDir);
    }
  } else {
    _ensureDefaultAndroidIcons(resDir);
    print('  ✓ Android mipmap varsayılan ikonları kontrol edildi / üretildi');
  }

  // 5. Splash Görseli
  if (splashBase64.isNotEmpty) {
    try {
      final bytes = base64Decode(splashBase64.replaceAll(RegExp(r'\s+'), ''));
      final splashFile = File('$androidRoot/app/src/main/res/drawable/splash_logo.png');
      splashFile.parent.createSync(recursive: true);
      splashFile.writeAsBytesSync(bytes);

      final splashXxhdpi = File('$androidRoot/app/src/main/res/drawable-xxhdpi/splash_logo.png');
      splashXxhdpi.parent.createSync(recursive: true);
      splashXxhdpi.writeAsBytesSync(bytes);
      print('  ✓ Android splash_logo.png oluşturuldu');
    } catch (e) {
      print('  ⚠️ Splash Base64 çözülemedi: $e');
    }
  }

  // 6. Keystore & İmzalama (Signing Key)
  if (keystoreBase64.isNotEmpty) {
    try {
      final keystoreBytes = base64Decode(keystoreBase64.replaceAll(RegExp(r'\s+'), ''));
      final keystoreFile = File('$androidRoot/upload.keystore');
      keystoreFile.parent.createSync(recursive: true);
      keystoreFile.writeAsBytesSync(keystoreBytes);

      final appKeystoreFile = File('$androidRoot/app/upload.keystore');
      appKeystoreFile.parent.createSync(recursive: true);
      appKeystoreFile.writeAsBytesSync(keystoreBytes);

      final keyPropsFile = File('$androidRoot/key.properties');
      keyPropsFile.writeAsStringSync('''storePassword=$keystorePassword
keyPassword=$keyPassword
keyAlias=$keyAlias
storeFile=../upload.keystore
''', encoding: utf8);
      print('  ✓ upload.keystore ve key.properties başarıyla oluşturuldu ve bağlandı');
    } catch (e) {
      print('  ⚠️ Keystore Base64 çözülemedi: $e');
    }
  }
}

/// iOS Proje Dosyalarını Günceller
void _applyIosConfig({
  required String iosRoot,
  required String appName,
  required String packageName,
  required String iconBase64,
  required String appStoreIssuerId,
  required String appStoreKeyId,
  required String appStoreP8Base64,
}) {
  // 1. Info.plist
  final infoPlistFile = File('$iosRoot/Runner/Info.plist');
  if (infoPlistFile.existsSync()) {
    var plistContent = infoPlistFile.readAsStringSync(encoding: utf8);
    if (plistContent.contains('<key>CFBundleDisplayName</key>')) {
      plistContent = plistContent.replaceAll(
        RegExp(r'<key>CFBundleDisplayName<\/key>\s*<string>[^<]*<\/string>'),
        '<key>CFBundleDisplayName</key>\n\t<string>$appName</string>',
      );
    } else {
      plistContent = plistContent.replaceFirst(
        '<dict>',
        '<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>$appName</string>',
      );
    }

    if (plistContent.contains('<key>CFBundleName</key>')) {
      plistContent = plistContent.replaceAll(
        RegExp(r'<key>CFBundleName<\/key>\s*<string>[^<]*<\/string>'),
        '<key>CFBundleName</key>\n\t<string>$appName</string>',
      );
    }

    infoPlistFile.writeAsStringSync(plistContent, encoding: utf8);
    print('  ✓ ios/Runner/Info.plist güncellendi (CFBundleDisplayName="$appName")');
  } else {
    infoPlistFile.parent.createSync(recursive: true);
    infoPlistFile.writeAsStringSync('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>\$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>$appName</string>
	<key>CFBundleExecutable</key>
	<string>\$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$appName</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>\$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>\$(FLUTTER_BUILD_NUMBER)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
</dict>
</plist>
''', encoding: utf8);
    print('  ✓ ios/Runner/Info.plist oluşturuldu');
  }

  // 2. project.pbxproj (PRODUCT_BUNDLE_IDENTIFIER)
  final pbxprojFile = File('$iosRoot/Runner.xcodeproj/project.pbxproj');
  if (pbxprojFile.existsSync()) {
    var pbxContent = pbxprojFile.readAsStringSync(encoding: utf8);
    pbxContent = pbxContent.replaceAll(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*[^;]+;'),
      'PRODUCT_BUNDLE_IDENTIFIER = $packageName;',
    );
    pbxprojFile.writeAsStringSync(pbxContent, encoding: utf8);
    print('  ✓ ios/Runner.xcodeproj/project.pbxproj güncellendi (PRODUCT_BUNDLE_IDENTIFIER=$packageName)');
  } else {
    pbxprojFile.parent.createSync(recursive: true);
    pbxprojFile.writeAsStringSync('''// !\$*UTF8*\$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 54;
	objects = {
		97C147031CF9000F007C117D /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				PRODUCT_BUNDLE_IDENTIFIER = $packageName;
			};
			name = Debug;
		};
		97C147041CF9000F007C117D /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				PRODUCT_BUNDLE_IDENTIFIER = $packageName;
			};
			name = Release;
		};
	};
	rootObject = 97C146E61CF9000F007C117D;
}
''', encoding: utf8);
    print('  ✓ ios/Runner.xcodeproj/project.pbxproj oluşturuldu');
  }

  // 3. iOS İkon Varlıkları (Base64 -> AppIcon.appiconset)
  if (iconBase64.isNotEmpty) {
    try {
      final bytes = base64Decode(iconBase64.replaceAll(RegExp(r'\s+'), ''));
      final iconsetDir = Directory('$iosRoot/Runner/Assets.xcassets/AppIcon.appiconset');
      iconsetDir.createSync(recursive: true);

      final icon1024 = File('${iconsetDir.path}/Icon-App-1024x1024@1x.png');
      icon1024.writeAsBytesSync(bytes);

      final contentsJsonFile = File('${iconsetDir.path}/Contents.json');
      contentsJsonFile.writeAsStringSync('''{
  "images" : [
    {
      "filename" : "Icon-App-1024x1024@1x.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''', encoding: utf8);
      print('  ✓ iOS AppIcon.appiconset ikon varlıkları Base64 verisinden üretildi');
    } catch (e) {
      print('  ⚠️ iOS İkon Base64 çözülemedi: $e');
    }
  }

  // 4. App Store Connect API Anahtarı (.p8) ve Fastlane Yapılandırması
  if (appStoreP8Base64.isNotEmpty) {
    try {
      final p8Bytes = base64Decode(appStoreP8Base64.replaceAll(RegExp(r'\s+'), ''));
      final fastlaneDir = Directory('$iosRoot/fastlane');
      fastlaneDir.createSync(recursive: true);

      final keyFileName = appStoreKeyId.isNotEmpty ? 'AuthKey_$appStoreKeyId.p8' : 'AuthKey.p8';
      final p8File = File('${fastlaneDir.path}/$keyFileName');
      p8File.writeAsBytesSync(p8Bytes);

      File('$iosRoot/$keyFileName').writeAsBytesSync(p8Bytes);

      final appFile = File('${fastlaneDir.path}/Appfile');
      appFile.writeAsStringSync('''app_identifier("$packageName")
apple_id("developer@web2app.local")
itc_team_id("$appStoreIssuerId")
''', encoding: utf8);

      final fastFile = File('${fastlaneDir.path}/Fastfile');
      fastFile.writeAsStringSync('''default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    api_key = app_store_connect_api_key(
      key_id: "$appStoreKeyId",
      issuer_id: "$appStoreIssuerId",
      key_filepath: "fastlane/$keyFileName",
      duration: 1200,
      in_house: false
    )
    pilot(
      api_key: api_key,
      app_identifier: "$packageName",
      skip_waiting_for_build_processing: true
    )
  end
end
''', encoding: utf8);
      print('  ✓ App Store Connect AuthKey (.p8), Appfile ve Fastfile TestFlight için yapılandırıldı');
    } catch (e) {
      print('  ⚠️ App Store Connect p8 Base64 çözülemedi: $e');
    }
  }
}

/// Android mipmap ikonlarının varlığını garanti eder, yoksa varsayılan 1x1 PNG yazar
void _ensureDefaultAndroidIcons(Directory resDir) {
  const defaultPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
  final defaultBytes = base64Decode(defaultPngBase64);
  final mipmapDirs = [
    'mipmap-mdpi',
    'mipmap-hdpi',
    'mipmap-xhdpi',
    'mipmap-xxhdpi',
    'mipmap-xxxhdpi',
  ];
  for (final dir in mipmapDirs) {
    final iconFile = File('${resDir.path}/$dir/ic_launcher.png');
    if (!iconFile.existsSync()) {
      iconFile.parent.createSync(recursive: true);
      iconFile.writeAsBytesSync(defaultBytes);
    }
  }
}

