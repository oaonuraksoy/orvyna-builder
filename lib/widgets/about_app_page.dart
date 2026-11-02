import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_config.dart';

/// Uygulama içi Hakkında ekranı: mağazaların aradığı gizlilik ve destek bağlantıları burada bulunur.
class AboutAppPage extends StatelessWidget {
  final AppConfig config;

  const AboutAppPage({super.key, required this.config});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final info = config.appInfo;
    final store = config.storeMetadata;
    final links = <(IconData, String, String)>[
      if (store.privacyPolicyUrl.isNotEmpty) (Icons.privacy_tip_outlined, 'Gizlilik Politikası', store.privacyPolicyUrl),
      if (store.supportUrl.isNotEmpty) (Icons.support_agent_rounded, 'Destek', store.supportUrl),
      if (info.webUrl.isNotEmpty) (Icons.public_rounded, 'Web Sitesi', info.webUrl),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hakkında'),
        backgroundColor: config.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  info.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Text('Sürüm ${info.appVersion}', style: const TextStyle(color: Colors.grey)),
                if (store.copyright.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(store.copyright, style: const TextStyle(color: Colors.grey, fontSize: 12.0)),
                ],
              ],
            ),
          ),
          const Divider(height: 1.0),
          for (final (icon, title, url) in links)
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18.0),
              onTap: () => _open(url),
            ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Açık Kaynak Lisansları'),
            onTap: () => showLicensePage(context: context, applicationName: info.appName, applicationVersion: info.appVersion),
          ),
        ],
      ),
    );
  }
}
