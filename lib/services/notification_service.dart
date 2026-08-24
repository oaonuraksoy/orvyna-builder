import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/app_config.dart';

typedef NotificationUrlCallback = void Function(String targetUrl);

/// OneSignal Anlık Bildirim (Push Notification) Yöneticisi
class NotificationService {
  final NotificationsConfig config;
  NotificationUrlCallback? onUrlReceived;
  bool _initialized = false;

  NotificationService({required this.config});

  /// OneSignal SDK'sını başlatır ve dinleyicileri ayarlar
  Future<void> initialize({NotificationUrlCallback? onUrlCallback}) async {
    if (!config.onesignalEnabled || config.onesignalAppId.isEmpty) {
      debugPrint('[NotificationService] OneSignal devre dışı veya App ID boş.');
      return;
    }

    onUrlReceived = onUrlCallback;

    try {
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      // OneSignal Başlatma
      OneSignal.initialize(config.onesignalAppId);

      // İzin Diyaloğu (Gerekiyorsa)
      if (config.promptPermissionOnLaunch) {
        await OneSignal.Notifications.requestPermission(true);
      }

      // Bildirim Tıklama Dinleyicisi
      OneSignal.Notifications.addClickListener((event) {
        final additionalData = event.notification.additionalData;
        final launchUrl = event.notification.launchUrl;

        String? targetUrl;
        if (additionalData != null && additionalData.containsKey('target_url')) {
          targetUrl = additionalData['target_url'] as String?;
        } else if (launchUrl != null && launchUrl.isNotEmpty) {
          targetUrl = launchUrl;
        }

        if (targetUrl != null && targetUrl.isNotEmpty) {
          debugPrint('[NotificationService] Bildirim tıklandı, hedef URL: $targetUrl');
          onUrlReceived?.call(targetUrl);
        }
      });

      _initialized = true;
      debugPrint('[NotificationService] OneSignal başarıyla başlatıldı.');
    } catch (e) {
      debugPrint('[NotificationService] OneSignal başlatma hatası: $e');
    }
  }

  /// Kullanıcı OneSignal Player ID / Subscription ID'sini alır
  Future<String?> getSubscriptionId() async {
    if (!_initialized) return null;
    return OneSignal.User.pushSubscription.id;
  }

  /// Manuel olarak bildirim izni talep eder
  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    return await OneSignal.Notifications.requestPermission(true);
  }
}
