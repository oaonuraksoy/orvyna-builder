import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Public derleme deposundaki şifreli proje paketlerini işler.
/// Biçim: 12 bayt nonce + 16 bayt MAC + AES-256-GCM şifreli veri.
/// Anahtar yalnızca deponun Actions Secrets alanındadır.
final _algorithm = AesGcm.with256bits();

Future<Uint8List> sealBytes(List<int> key, List<int> plain, {List<int>? nonce}) async {
  final box = await _algorithm.encrypt(
    plain,
    secretKey: SecretKey(key),
    nonce: nonce ?? _algorithm.newNonce(),
  );
  return Uint8List.fromList([...box.nonce, ...box.mac.bytes, ...box.cipherText]);
}

Future<Uint8List> openBytes(List<int> key, List<int> sealed) async {
  final box = SecretBox(
    sealed.sublist(28),
    nonce: sealed.sublist(0, 12),
    mac: Mac(sealed.sublist(12, 28)),
  );
  return Uint8List.fromList(await _algorithm.decrypt(box, secretKey: SecretKey(key)));
}

/// Loglarda görünmemesi gereken değerleri GitHub Actions'a bildirir.
void maskValue(Object? value, void Function(String) out) {
  final text = value?.toString() ?? '';
  for (final line in const LineSplitter().convert(text)) {
    if (line.trim().length >= 3) out('::add-mask::${line.trim()}');
  }
}

/// Paketi çözer: ayarları app_config.json'a, mağaza anahtarlarını geçici dosyalara yazar.
Future<void> openProject({
  required String bundlePath,
  required List<int> key,
  required String configPath,
  required String tempDir,
  required String? githubEnvPath,
  void Function(String) out = print,
}) async {
  final plain = await openBytes(key, File(bundlePath).readAsBytesSync());
  final bundle = json.decode(utf8.decode(plain)) as Map<String, dynamic>;
  final config = bundle['config'] as Map<String, dynamic>;
  final store = bundle['store'] as Map<String, dynamic>? ?? {};

  final appInfo = config['app_info'] as Map<String, dynamic>? ?? {};
  final monetization = config['monetization'] as Map<String, dynamic>? ?? {};
  final notifications = config['notifications'] as Map<String, dynamic>? ?? {};
  final signing = config['signing'] as Map<String, dynamic>? ?? {};
  final webUrl = appInfo['web_url']?.toString() ?? '';
  for (final value in [
    appInfo['app_name'],
    appInfo['package_name'],
    webUrl,
    Uri.tryParse(webUrl)?.host,
    ...monetization.values.whereType<String>(),
    ...notifications.values.whereType<String>(),
    signing['keystore_password'],
    signing['key_password'],
    ...store.values,
  ]) {
    maskValue(value, out);
  }

  File(configPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(json.encode(config), encoding: utf8);

  final env = StringBuffer('ORVYNA_PACKAGE=${appInfo['package_name']}\n');
  final playJson = store['play_json']?.toString() ?? '';
  if (playJson.isNotEmpty) {
    final path = '$tempDir/play_service_account.json';
    File(path).writeAsStringSync(playJson);
    env.writeln('ORVYNA_PLAY_JSON=$path');
  }
  env.writeln('ASC_KEY_ID=${store['asc_key_id'] ?? ''}');
  env.writeln('ASC_ISSUER_ID=${store['asc_issuer_id'] ?? ''}');
  env.writeln('ASC_KEY_P8_BASE64=${store['asc_p8_base64'] ?? ''}');
  env.writeln('APPLE_TEAM_ID=${store['apple_team_id'] ?? ''}');
  if (githubEnvPath != null) {
    File(githubEnvPath).writeAsStringSync(env.toString(), mode: FileMode.append);
  }
}

Future<void> main(List<String> args) async {
  String arg(String name) => args.firstWhere((a) => a.startsWith('--$name='), orElse: () => '--$name=').split('=').last;
  final rawKey = Platform.environment['ORVYNA_PROJECT_KEY'] ?? '';
  if (rawKey.isEmpty) {
    stderr.writeln('Proje anahtarı bulunamadı. Studio üzerinden derlemeyi yeniden başlatın.');
    exit(1);
  }
  final key = base64Decode(rawKey);
  final command = args.isEmpty ? '' : args.first;
  if (command == 'open') {
    await openProject(
      bundlePath: 'projects/${arg('project')}/bundle.enc',
      key: key,
      configPath: 'assets/config/app_config.json',
      tempDir: Platform.environment['RUNNER_TEMP'] ?? Directory.systemTemp.path,
      githubEnvPath: Platform.environment['GITHUB_ENV'],
    );
  } else if (command == 'seal') {
    final sealed = await sealBytes(key, File(arg('in')).readAsBytesSync());
    File(arg('out')).writeAsBytesSync(sealed);
  } else {
    stderr.writeln('Kullanım: project_bundle.dart open --project=ID | seal --in=A --out=B');
    exit(64);
  }
}
