import 'package:flutter/material.dart';
import '../models/app_config.dart';

/// İnternet bağlantısı kesildiğinde veya sayfa yüklenemediğinde gösterilen şık çevrimdışı ekranı
class OfflineScreen extends StatelessWidget {
  final OfflineSettingsConfig config;
  final ThemeConfig theme;
  final VoidCallback onRetry;

  const OfflineScreen({
    super.key,
    required this.config,
    required this.theme,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.backgroundColor.computeLuminance() < 0.5;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // İkon Çemberi
                Container(
                  width: 96.0,
                  height: 96.0,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 48.0,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 28.0),

                // Başlık
                Text(
                  config.offlineTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Açıklama
                Text(
                  config.offlineMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.0,
                    height: 1.5,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 32.0),

                // Yeniden Dene Butonu
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 20.0),
                  label: Text(
                    config.retryButtonText,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 52),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
