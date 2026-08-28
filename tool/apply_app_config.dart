import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Web2App Bulut & CI/CD Konfigürasyon Uygulayıcı (Build Preprocessor)
///
/// Bu fonksiyon / script, enjekte edilmiş `app_config.json` dosyasını okuyarak:
/// 1. AndroidManifest.xml içindeki `android:label` (@string/app_name), AdMob meta-data ve strings.xml değerlerini günceller.
/// 2. android/app/build.gradle içindeki `applicationId` değerini günceller (namespace "com.web2app.app" olarak sabit kalır).
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
  final security = config['security'] as Map<String, dynamic>? ?? {};
  final biometric = config['biometric'] as Map<String, dynamic>? ??
      (config['biometric_auth'] as Map<String, dynamic>? ??
          (security['biometric'] as Map<String, dynamic>? ?? {}));
  final notifications = config['notifications'] as Map<String, dynamic>? ?? {};
  final permissions = config['permissions'] as Map<String, dynamic>? ?? {};

  final bool isAdmobEnabled = monetization['admob_enabled'] == true || config['admob_enabled'] == true;
  final bool isBiometricEnabled = biometric['enabled'] == true ||
      config['biometric_auth']?['enabled'] == true ||
      config['biometric']?['enabled'] == true ||
      security['biometric_auth'] == true ||
      security['biometric'] == true;
  final bool isPushEnabled = notifications['onesignal_enabled'] == true ||
      permissions['notifications'] == true ||
      notifications['enabled'] == true ||
      config['push_notifications_enabled'] == true;

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
  final String iconUrl = assets['icon_url']?.toString() ?? '';
  final String splashUrl = assets['splash_url']?.toString() ?? '';

  final String keystoreBase64 = signing['keystore_base64']?.toString() ?? '';
  final String keystorePassword = signing['keystore_password']?.toString() ?? '';
  final String rawKeyAlias = signing['key_alias']?.toString() ?? '';
  final String keyAlias = rawKeyAlias.trim().isNotEmpty ? rawKeyAlias.trim() : 'upload';
  final String rawKeyPassword = signing['key_password']?.toString() ?? '';
  final String keyPassword = rawKeyPassword.trim().isNotEmpty ? rawKeyPassword.trim() : keystorePassword;

  final String appStoreIssuerId = appStore['issuer_id']?.toString() ?? '';
  final String appStoreKeyId = appStore['key_id']?.toString() ?? '';
  final String appStoreP8Base64 = appStore['p8_base64']?.toString() ?? '';

  print('📦 Uygulama Adı      : $appName');
  print('🆔 Paket Kimliği     : $packageName');
  print('🏷️  Sürüm              : v$appVersion+$buildNumber');
  print('📢 AdMob              : ${isAdmobEnabled ? "Aktif ($admobAppId)" : "Devre Dışı"}');
  print('🔐 Biyometrik Kilit   : ${isBiometricEnabled ? "Aktif" : "Devre Dışı"}');
  print('🔔 Push Bildirimleri  : ${isPushEnabled ? "Aktif" : "Devre Dışı"}');
  print('🎨 İkon Kaynağı      : ${iconUrl.isNotEmpty ? "URL ($iconUrl)" : (iconBase64.isNotEmpty ? "Base64 (${(iconBase64.length / 1024).toStringAsFixed(1)} KB)" : "Yok (Varsayılan)")}');
  print('✨ Splash Kaynağı    : ${splashUrl.isNotEmpty ? "URL ($splashUrl)" : (splashBase64.isNotEmpty ? "Base64 (${(splashBase64.length / 1024).toStringAsFixed(1)} KB)" : "Yok (Varsayılan)")}');
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
      isAdmobEnabled: isAdmobEnabled,
      admobAppId: admobAppId,
      isBiometricEnabled: isBiometricEnabled,
      isPushEnabled: isPushEnabled,
      iconBase64: iconBase64,
      iconUrl: iconUrl,
      splashBase64: splashBase64,
      splashUrl: splashUrl,
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
      isAdmobEnabled: isAdmobEnabled,
      admobAppId: admobAppId,
      isBiometricEnabled: isBiometricEnabled,
      isPushEnabled: isPushEnabled,
      iconBase64: iconBase64,
      iconUrl: iconUrl,
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

/// URL veya Base64 formatındaki görsel verisini Uint8List / List<int> olarak döner
List<int>? _fetchImageBytes({String? url, String? base64Str}) {
  if (url != null && url.trim().isNotEmpty && url.startsWith('http')) {
    try {
      print('  🌐 Görsel URL\'den indiriliyor: $url');
      final curlResult = Process.runSync('curl', ['-sL', '--fail', '--retry', '2', url.trim()], stdoutEncoding: null);
      if (curlResult.exitCode == 0 && curlResult.stdout is List<int> && (curlResult.stdout as List<int>).isNotEmpty) {
        final bytes = curlResult.stdout as List<int>;
        print('  ✓ Görsel URL üzerinden başarıyla indirildi (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
        return bytes;
      } else {
        print('  ⚠️ URL indirme başarısız (exitCode: ${curlResult.exitCode})');
      }
    } catch (e) {
      print('  ⚠️ URL indirme hatası ($url): $e');
    }
  }

  if (base64Str != null && base64Str.trim().isNotEmpty) {
    try {
      return base64Decode(base64Str.replaceAll(RegExp(r'\s+'), ''));
    } catch (e) {
      print('  ⚠️ Base64 decode hatası: $e');
    }
  }

  return null;
}

/// Görseli opak (şeffaflıktan arındırılmış) 3 kanallı RGB PNG formatına dönüştürür (Apple App Store kuralı)
img.Image _makeOpaqueRgb(img.Image image) {
  final opaqueCanvas = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 3,
  );
  img.fill(opaqueCanvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(opaqueCanvas, image);
  return opaqueCanvas;
}

/// Android Proje Dosyalarını Günceller
void _applyAndroidConfig({
  required String androidRoot,
  required String appName,
  required String packageName,
  bool isAdmobEnabled = false,
  required String admobAppId,
  bool isBiometricEnabled = false,
  bool isPushEnabled = false,
  required String iconBase64,
  String iconUrl = '',
  required String splashBase64,
  String splashUrl = '',
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
        'package="com.web2app.app"',
      );
    }
    manifestContent = manifestContent.replaceAll(
      RegExp(r'android:name="(?:\.|\w+(\.\w+)*\.)MainActivity"'),
      'android:name="com.web2app.app.MainActivity"',
    );

    // TODO-05: AdMob Android Configuration
    final admobRegex = RegExp(
      r'\s*<meta-data\s+[^>]*android:name="com\.google\.android\.gms\.ads\.APPLICATION_ID"[^>]*\/?>',
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );
    if (isAdmobEnabled) {
      if (admobRegex.hasMatch(manifestContent)) {
        manifestContent = manifestContent.replaceAll(
          admobRegex,
          '\n        <meta-data\n            android:name="com.google.android.gms.ads.APPLICATION_ID"\n            android:value="$admobAppId"/>',
        );
      } else {
        manifestContent = manifestContent.replaceFirst(
          '</application>',
          '    <meta-data\n            android:name="com.google.android.gms.ads.APPLICATION_ID"\n            android:value="$admobAppId"/>\n    </application>',
        );
      }
    } else {
      manifestContent = manifestContent.replaceAll(admobRegex, '');
    }

    // TODO-06: Biyometrik Kilit Android Permissions (USE_BIOMETRIC & USE_FINGERPRINT)
    final biometricRegex = RegExp(
      r'\s*<uses-permission\s+[^>]*android:name="android\.permission\.USE_BIOMETRIC"[^>]*\/?>',
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );
    final fingerprintRegex = RegExp(
      r'\s*<uses-permission\s+[^>]*android:name="android\.permission\.USE_FINGERPRINT"[^>]*\/?>',
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );
    if (isBiometricEnabled) {
      if (!manifestContent.contains('android.permission.USE_BIOMETRIC')) {
        manifestContent = manifestContent.replaceFirst(
          '<application',
          '    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n    <application',
        );
      }
      if (!manifestContent.contains('android.permission.USE_FINGERPRINT')) {
        manifestContent = manifestContent.replaceFirst(
          '<application',
          '    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>\n    <application',
        );
      }
    } else {
      manifestContent = manifestContent.replaceAll(biometricRegex, '');
      manifestContent = manifestContent.replaceAll(fingerprintRegex, '');
    }

    // TODO-07: Push Bildirim Android Permission (POST_NOTIFICATIONS)
    final postNotifRegex = RegExp(
      r'\s*<uses-permission\s+[^>]*android:name="android\.permission\.POST_NOTIFICATIONS"[^>]*\/?>',
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );
    if (isPushEnabled) {
      if (!manifestContent.contains('android.permission.POST_NOTIFICATIONS')) {
        manifestContent = manifestContent.replaceFirst(
          '<application',
          '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    <application',
        );
      }
    } else {
      manifestContent = manifestContent.replaceAll(postNotifRegex, '');
    }

    manifestFile.writeAsStringSync(manifestContent, encoding: utf8);
    print('  ✓ AndroidManifest.xml güncellendi (android:label="@string/app_name", MainActivity="com.web2app.app.MainActivity", AdMob=${isAdmobEnabled ? "Açık" : "Kapalı"}, Biyometrik=${isBiometricEnabled ? "Açık" : "Kapalı"}, Push=${isPushEnabled ? "Açık" : "Kapalı"})');
  } else {
    manifestFile.parent.createSync(recursive: true);
    final permBuffer = StringBuffer();
    permBuffer.writeln('    <uses-permission android:name="android.permission.INTERNET"/>');
    permBuffer.writeln('    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>');
    if (isBiometricEnabled) {
      permBuffer.writeln('    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>');
      permBuffer.writeln('    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>');
    }
    if (isPushEnabled) {
      permBuffer.writeln('    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>');
    }

    final admobTag = isAdmobEnabled
        ? '        <meta-data\n            android:name="com.google.android.gms.ads.APPLICATION_ID"\n            android:value="$admobAppId"/>\n'
        : '';

    manifestFile.writeAsStringSync('''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.web2app.app">
${permBuffer.toString().trimRight()}
    <application
        android:label="@string/app_name"
        android:name="\${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name="com.web2app.app.MainActivity"
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
$admobTag        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''', encoding: utf8);
    print('  ✓ AndroidManifest.xml oluşturuldu (android:label="@string/app_name", MainActivity="com.web2app.app.MainActivity", AdMob=${isAdmobEnabled ? "Açık" : "Kapalı"}, Biyometrik=${isBiometricEnabled ? "Açık" : "Kapalı"}, Push=${isPushEnabled ? "Açık" : "Kapalı"})');
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
      'namespace = "com.web2app.app"',
    );
    appBuildGradle.writeAsStringSync(content, encoding: utf8);
    print('  ✓ android/app/build.gradle güncellendi (applicationId="$packageName", namespace="com.web2app.app")');
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
    namespace = "com.web2app.app"
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

  // 4. İkon Dosyaları (URL / Base64 -> PNG -> Center Crop 1:1 -> Mipmap & Adaptive)
  final resDir = Directory('$androidRoot/app/src/main/res');
  final iconBytes = _fetchImageBytes(url: iconUrl, base64Str: iconBase64);
  if (iconBytes != null && iconBytes.isNotEmpty) {
    try {
      final decodedImage = img.decodeImage(Uint8List.fromList(iconBytes));
      if (decodedImage != null) {
        // Merkezden 1:1 kare kırp (Center Crop)
        final minSide = math.min(decodedImage.width, decodedImage.height);
        final cropX = (decodedImage.width - minSide) ~/ 2;
        final cropY = (decodedImage.height - minSide) ~/ 2;
        final cropped = img.copyCrop(
          decodedImage,
          x: cropX,
          y: cropY,
          width: minSide,
          height: minSide,
        );

        // Standart Launcher İkonları: 48, 72, 96, 144, 192 px
        const launcherSizes = {
          'mipmap-mdpi': 48,
          'mipmap-hdpi': 72,
          'mipmap-xhdpi': 96,
          'mipmap-xxhdpi': 144,
          'mipmap-xxxhdpi': 192,
        };

        // Adaptive Foreground İkonları: 108, 162, 216, 324, 432 px
        const foregroundSizes = {
          'mipmap-mdpi': 108,
          'mipmap-hdpi': 162,
          'mipmap-xhdpi': 216,
          'mipmap-xxhdpi': 324,
          'mipmap-xxxhdpi': 432,
        };

        for (final entry in launcherSizes.entries) {
          final dir = entry.key;
          final size = entry.value;
          final resized = img.copyResize(
            cropped,
            width: size,
            height: size,
            interpolation: img.Interpolation.cubic,
          );
          final iconFile = File('${resDir.path}/$dir/ic_launcher.png');
          iconFile.parent.createSync(recursive: true);
          iconFile.writeAsBytesSync(img.encodePng(resized));
        }

        for (final entry in foregroundSizes.entries) {
          final dir = entry.key;
          final size = entry.value;
          final resized = img.copyResize(
            cropped,
            width: size,
            height: size,
            interpolation: img.Interpolation.cubic,
          );
          final fgFile = File('${resDir.path}/$dir/ic_launcher_foreground.png');
          fgFile.parent.createSync(recursive: true);
          fgFile.writeAsBytesSync(img.encodePng(resized));
        }

        // Android 8.0+ (API 26+) Adaptive Icon XML
        final anyDpiDir = Directory('${resDir.path}/mipmap-anydpi-v26');
        if (!anyDpiDir.existsSync()) anyDpiDir.createSync(recursive: true);
        final adaptiveXml = File('${anyDpiDir.path}/ic_launcher.xml');
        adaptiveXml.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@android:color/white" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''', encoding: utf8);

        print('  ✓ Android mipmap launcher ve adaptive foreground ikonları (5 çözünürlük) Cubic Antialiasing ile üretildi');
      } else {
        _writeRawIconsFallback(resDir, Uint8List.fromList(iconBytes));
      }
    } catch (e) {
      print('  ⚠️ İkon çözülemedi: $e');
      _ensureDefaultAndroidIcons(resDir);
    }
  } else {
    _ensureDefaultAndroidIcons(resDir);
    print('  ✓ Android mipmap varsayılan ikonları kontrol edildi / üretildi');
  }

  // 5. Splash Görseli (URL / Base64)
  final splashBytes = _fetchImageBytes(url: splashUrl, base64Str: splashBase64);
  if (splashBytes != null && splashBytes.isNotEmpty) {
    try {
      final splashFile = File('$androidRoot/app/src/main/res/drawable/splash_logo.png');
      splashFile.parent.createSync(recursive: true);
      splashFile.writeAsBytesSync(splashBytes);

      final splashXxhdpi = File('$androidRoot/app/src/main/res/drawable-xxhdpi/splash_logo.png');
      splashXxhdpi.parent.createSync(recursive: true);
      splashXxhdpi.writeAsBytesSync(splashBytes);
      print('  ✓ Android splash_logo.png oluşturuldu');
    } catch (e) {
      print('  ⚠️ Splash görseli yazılamadı: $e');
    }
  }

  // 6. Keystore & İmzalama (Signing Key)
  final keyPropsFile = File('$androidRoot/key.properties');
  if (keystoreBase64.trim().isNotEmpty && keystorePassword.trim().isNotEmpty) {
    try {
      final effectiveAlias = keyAlias.trim().isNotEmpty ? keyAlias.trim() : 'upload';
      final effectiveKeyPass = keyPassword.trim().isNotEmpty ? keyPassword.trim() : keystorePassword.trim();
      final effectiveStorePass = keystorePassword.trim();

      final keystoreBytes = base64Decode(keystoreBase64.replaceAll(RegExp(r'\s+'), ''));
      final keystoreFile = File('$androidRoot/upload.keystore');
      keystoreFile.parent.createSync(recursive: true);
      keystoreFile.writeAsBytesSync(keystoreBytes);

      final appKeystoreFile = File('$androidRoot/app/upload.keystore');
      appKeystoreFile.parent.createSync(recursive: true);
      appKeystoreFile.writeAsBytesSync(keystoreBytes);

      keyPropsFile.writeAsStringSync('''storePassword=$effectiveStorePass
keyPassword=$effectiveKeyPass
keyAlias=$effectiveAlias
storeFile=../upload.keystore
''', encoding: utf8);
      print('  ✓ upload.keystore ve key.properties başarıyla oluşturuldu ve bağlandı (Alias: $effectiveAlias)');
    } catch (e) {
      print('  ⚠️ Keystore Base64 çözülemedi: $e');
      if (keyPropsFile.existsSync()) {
        keyPropsFile.deleteSync();
      }
    }
  } else {
    // Keystore veya şifre girilmediyse key.properties silinmeli ki Gradle otomatik olarak debug signing kullansın ve APK derlemesi ÇÖKMESİN.
    if (keyPropsFile.existsSync()) {
      keyPropsFile.deleteSync();
      print('  ℹ️ Keystore veya şifre girilmediği için key.properties kaldırıldı (Debug signing kullanılacak)');
    } else {
      print('  ℹ️ Keystore veya şifre belirtilmedi (Debug signing kullanılacak)');
    }
  }
}

/// iOS Proje Dosyalarını Günceller
void _applyIosConfig({
  required String iosRoot,
  required String appName,
  required String packageName,
  bool isAdmobEnabled = false,
  String admobAppId = '',
  bool isBiometricEnabled = false,
  bool isPushEnabled = false,
  required String iconBase64,
  String iconUrl = '',
  required String appStoreIssuerId,
  required String appStoreKeyId,
  required String appStoreP8Base64,
}) {
  // 1. Info.plist
  final infoPlistFile = File('$iosRoot/Runner/Info.plist');
  if (infoPlistFile.existsSync()) {
    var plistContent = infoPlistFile.readAsStringSync(encoding: utf8);
    plistContent = plistContent.replaceAll(
      RegExp(r'<key>CFBundleDisplayName<\/key>\s*<string>[^<]*<\/string>'),
      '<key>CFBundleDisplayName</key>\n\t<string>$appName</string>',
    );
    plistContent = plistContent.replaceAll(
      RegExp(r'<key>CFBundleName<\/key>\s*<string>[^<]*<\/string>'),
      '<key>CFBundleName</key>\n\t<string>$appName</string>',
    );

    // TODO-05: AdMob iOS (GADApplicationIdentifier, SKAdNetworkItems, NSUserTrackingUsageDescription)
    if (isAdmobEnabled) {
      if (plistContent.contains('<key>GADApplicationIdentifier</key>')) {
        plistContent = plistContent.replaceAll(
          RegExp(r'<key>GADApplicationIdentifier<\/key>\s*<string>[^<]*<\/string>'),
          '<key>GADApplicationIdentifier</key>\n\t<string>$admobAppId</string>',
        );
      } else {
        plistContent = plistContent.replaceFirst(
          '</dict>',
          '\t<key>GADApplicationIdentifier</key>\n\t<string>$admobAppId</string>\n</dict>',
        );
      }

      if (!plistContent.contains('<key>NSUserTrackingUsageDescription</key>')) {
        plistContent = plistContent.replaceFirst(
          '</dict>',
          '\t<key>NSUserTrackingUsageDescription</key>\n\t<string>Size daha iyi bir reklam deneyimi sunabilmek için izninize ihtiyaç duyulmaktadır.</string>\n</dict>',
        );
      }
    } else {
      plistContent = plistContent.replaceAll(
        RegExp(r'\s*<key>GADApplicationIdentifier<\/key>\s*<string>[^<]*<\/string>'),
        '',
      );
      plistContent = plistContent.replaceAll(
        RegExp(r'\s*<key>SKAdNetworkItems<\/key>\s*<array>[\s\S]*?<\/array>'),
        '',
      );
      plistContent = plistContent.replaceAll(
        RegExp(r'\s*<key>NSUserTrackingUsageDescription<\/key>\s*<string>[^<]*<\/string>'),
        '',
      );
    }

    // TODO-06: Biyometrik Kilit iOS (NSFaceIDUsageDescription)
    if (isBiometricEnabled) {
      if (plistContent.contains('<key>NSFaceIDUsageDescription</key>')) {
        plistContent = plistContent.replaceAll(
          RegExp(r'<key>NSFaceIDUsageDescription<\/key>\s*<string>[^<]*<\/string>'),
          '<key>NSFaceIDUsageDescription</key>\n\t<string>Uygulamaya güvenli giriş yapmak için biyometrik kimlik doğrulama gereklidir.</string>',
        );
      } else {
        plistContent = plistContent.replaceFirst(
          '</dict>',
          '\t<key>NSFaceIDUsageDescription</key>\n\t<string>Uygulamaya güvenli giriş yapmak için biyometrik kimlik doğrulama gereklidir.</string>\n</dict>',
        );
      }
    } else {
      plistContent = plistContent.replaceAll(
        RegExp(r'\s*<key>NSFaceIDUsageDescription<\/key>\s*<string>[^<]*<\/string>'),
        '',
      );
    }

    // TODO-07: Push Bildirim iOS (UIBackgroundModes -> remote-notification)
    if (isPushEnabled) {
      if (plistContent.contains('<key>UIBackgroundModes</key>')) {
        if (!plistContent.contains('<string>remote-notification</string>')) {
          plistContent = plistContent.replaceFirst(
            RegExp(r'<key>UIBackgroundModes<\/key>\s*<array>'),
            '<key>UIBackgroundModes</key>\n\t<array>\n\t\t<string>remote-notification</string>',
          );
        }
      } else {
        plistContent = plistContent.replaceFirst(
          '</dict>',
          '\t<key>UIBackgroundModes</key>\n\t<array>\n\t\t<string>remote-notification</string>\n\t</array>\n</dict>',
        );
      }
    } else {
      plistContent = plistContent.replaceAll(
        RegExp(r'\s*<string>remote-notification<\/string>'),
        '',
      );
      plistContent = plistContent.replaceAll(
        RegExp(r'\s*<key>UIBackgroundModes<\/key>\s*<array>\s*<\/array>'),
        '',
      );
    }

    infoPlistFile.writeAsStringSync(plistContent, encoding: utf8);
    print('  ✓ ios/Runner/Info.plist güncellendi (CFBundleDisplayName="$appName", AdMob=${isAdmobEnabled ? "Açık" : "Kapalı"}, Biyometrik=${isBiometricEnabled ? "Açık" : "Kapalı"}, Push=${isPushEnabled ? "Açık" : "Kapalı"})');
  } else {
    infoPlistFile.parent.createSync(recursive: true);
    final iosExtras = StringBuffer();
    if (isAdmobEnabled) {
      iosExtras.writeln('\t<key>GADApplicationIdentifier</key>');
      iosExtras.writeln('\t<string>$admobAppId</string>');
      iosExtras.writeln('\t<key>NSUserTrackingUsageDescription</key>');
      iosExtras.writeln('\t<string>Size daha iyi bir reklam deneyimi sunabilmek için izninize ihtiyaç duyulmaktadır.</string>');
    }
    if (isBiometricEnabled) {
      iosExtras.writeln('\t<key>NSFaceIDUsageDescription</key>');
      iosExtras.writeln('\t<string>Uygulamaya güvenli giriş yapmak için biyometrik kimlik doğrulama gereklidir.</string>');
    }
    if (isPushEnabled) {
      iosExtras.writeln('\t<key>UIBackgroundModes</key>');
      iosExtras.writeln('\t<array>');
      iosExtras.writeln('\t\t<string>remote-notification</string>');
      iosExtras.writeln('\t</array>');
    }

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
	<string>$packageName</string>
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
	<key>UIViewControllerBasedStatusBarAppearance</key>
	<false/>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
${iosExtras.toString().trimRight()}
</dict>
</plist>
''', encoding: utf8);
    print('  ✓ ios/Runner/Info.plist oluşturuldu (CFBundleDisplayName="$appName", AdMob=${isAdmobEnabled ? "Açık" : "Kapalı"}, Biyometrik=${isBiometricEnabled ? "Açık" : "Kapalı"}, Push=${isPushEnabled ? "Açık" : "Kapalı"})');
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
    print('  ✓ ios/Runner.xcodeproj/project.pbxproj güncellendi (PRODUCT_BUNDLE_IDENTIFIER="$packageName")');
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

  // 3. iOS İkon Varlıkları (URL / Base64 -> %100 OPAK RGB PNG -> AppIcon.appiconset)
  final iconBytes = _fetchImageBytes(url: iconUrl, base64Str: iconBase64);
  if (iconBytes != null && iconBytes.isNotEmpty) {
    try {
      final iconsetDir = Directory('$iosRoot/Runner/Assets.xcassets/AppIcon.appiconset');
      iconsetDir.createSync(recursive: true);

      final icon1024 = File('${iconsetDir.path}/Icon-App-1024x1024@1x.png');
      final decodedImage = img.decodeImage(Uint8List.fromList(iconBytes));
      if (decodedImage != null) {
        final minSide = math.min(decodedImage.width, decodedImage.height);
        final cropX = (decodedImage.width - minSide) ~/ 2;
        final cropY = (decodedImage.height - minSide) ~/ 2;
        final cropped = img.copyCrop(
          decodedImage,
          x: cropX,
          y: cropY,
          width: minSide,
          height: minSide,
        );
        final resized = img.copyResize(
          cropped,
          width: 1024,
          height: 1024,
          interpolation: img.Interpolation.cubic,
        );
        final opaqueRgb = _makeOpaqueRgb(resized);
        icon1024.writeAsBytesSync(img.encodePng(opaqueRgb));
      } else {
        icon1024.writeAsBytesSync(iconBytes);
      }

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
      print('  ✓ iOS AppIcon.appiconset 1024x1024 HD ikon varlıkları Cubic Antialiasing ile üretildi');
    } catch (e) {
      print('  ⚠️ iOS İkon çözülemedi: $e');
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

/// Android mipmap ikonlarının ve adaptive icon XML'inin varlığını garanti eder, yoksa varsayılan 1x1 PNG yazar
void _ensureDefaultAndroidIcons(Directory resDir) {
  const defaultPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
  final defaultBytes = base64Decode(defaultPngBase64);
  _writeRawIconsFallback(resDir, defaultBytes);
}

void _writeRawIconsFallback(Directory resDir, List<int> bytes) {
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
      iconFile.writeAsBytesSync(bytes);
    }
    final fgFile = File('${resDir.path}/$dir/ic_launcher_foreground.png');
    if (!fgFile.existsSync()) {
      fgFile.parent.createSync(recursive: true);
      fgFile.writeAsBytesSync(bytes);
    }
  }
  final anyDpiDir = Directory('${resDir.path}/mipmap-anydpi-v26');
  final adaptiveXml = File('${anyDpiDir.path}/ic_launcher.xml');
  if (!adaptiveXml.existsSync()) {
    anyDpiDir.createSync(recursive: true);
    adaptiveXml.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@android:color/white" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''', encoding: utf8);
  }
}
