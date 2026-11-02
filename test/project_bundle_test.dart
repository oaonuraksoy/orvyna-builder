import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../tool/project_bundle.dart';

void main() {
  final key = List<int>.generate(32, (i) => i);

  // Studio testindeki değerle aynı olmalıdır; iki taraf aynı biçimi kullanır.
  test('şifreleme biçimi Studio ile uyumlu', () async {
    final sealed = await sealBytes(key, utf8.encode('orvyna'), nonce: List<int>.filled(12, 7));
    expect(base64Encode(sealed), 'BwcHBwcHBwcHBwcHWksmp7xQOHTFmsd9uN3tYmAY0CUBbg==');
    expect(utf8.decode(await openBytes(key, sealed)), 'orvyna');
  });

  test('yanlış anahtarla açılmaz', () async {
    final sealed = await sealBytes(key, [1, 2, 3]);
    expect(() => openBytes(List<int>.filled(32, 9), sealed), throwsA(anything));
  });

  test('paket açılınca ayarlar yazılır, gizli değerler loglarda maskelenir', () async {
    final dir = Directory.systemTemp.createTempSync('bundle');
    addTearDown(() => dir.deleteSync(recursive: true));
    final sealed = await sealBytes(key, utf8.encode(json.encode({
      'config': {
        'app_info': {'app_name': 'Benim Dukkanim', 'package_name': 'com.dukkan.app', 'web_url': 'https://dukkan.test'},
        'monetization': {'admob_app_id': 'ca-app-pub-123~456'},
        'signing': {'keystore_password': 'gizli-parola'},
      },
      'store': {'play_json': '{"private_key":"abc"}', 'asc_key_id': 'KEY123'},
    })));
    final bundle = File('${dir.path}/bundle.enc')..writeAsBytesSync(sealed);
    final envFile = File('${dir.path}/env');
    final logs = <String>[];

    await openProject(
      bundlePath: bundle.path,
      key: key,
      configPath: '${dir.path}/app_config.json',
      tempDir: dir.path,
      githubEnvPath: envFile.path,
      out: logs.add,
    );

    final config = json.decode(File('${dir.path}/app_config.json').readAsStringSync()) as Map<String, dynamic>;
    expect(config.containsKey('store'), isFalse);
    expect(logs, containsAll([
      '::add-mask::Benim Dukkanim',
      '::add-mask::com.dukkan.app',
      '::add-mask::dukkan.test',
      '::add-mask::ca-app-pub-123~456',
      '::add-mask::gizli-parola',
    ]));
    expect(envFile.readAsStringSync(), contains('ORVYNA_PACKAGE=com.dukkan.app'));
    expect(File('${dir.path}/play_service_account.json').existsSync(), isTrue);
  });
}
