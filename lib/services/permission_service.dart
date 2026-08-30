import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_config.dart';

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Mobil motor çalışma zamanı izin yöneticisi (Native & WebRTC)
class PermissionService {
  final PermissionsConfig config;

  PermissionService({required this.config});

  /// Başlangıçta istenmesi gereken izinleri topluca talep eder
  Future<void> requestAppPermissions() async {
    final List<Permission> permissionsToRequest = [];

    if (config.camera) permissionsToRequest.add(Permission.camera);
    if (config.microphone) permissionsToRequest.add(Permission.microphone);
    if (config.location) permissionsToRequest.add(Permission.locationWhenInUse);
    if (config.storage) {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          permissionsToRequest.add(Permission.photos);
          permissionsToRequest.add(Permission.videos);
        } else {
          permissionsToRequest.add(Permission.storage);
        }
      } else {
        permissionsToRequest.add(Permission.storage);
        permissionsToRequest.add(Permission.photos);
      }
    }
    if (config.notifications) permissionsToRequest.add(Permission.notification);

    if (permissionsToRequest.isNotEmpty) {
      try {
        final statuses = await permissionsToRequest.request();
        debugPrint('[PermissionService] İzin sonuçları: $statuses');
      } catch (e) {
        debugPrint('[PermissionService] İzin isteme hatası: $e');
      }
    }
  }

  /// Webview içinden gelen WebRTC medya (kamera/mikrofon) izin isteklerini yönetir
  Future<PermissionResponse?> handleWebPermissionRequest(
    PermissionRequest request,
  ) async {
    final List<PermissionResourceType> grantedResources = [];

    for (final resource in request.resources) {
      if (resource == PermissionResourceType.CAMERA && config.camera) {
        final status = await Permission.camera.request();
        if (status.isGranted) {
          grantedResources.add(PermissionResourceType.CAMERA);
        }
      } else if (resource == PermissionResourceType.MICROPHONE && config.microphone) {
        final status = await Permission.microphone.request();
        if (status.isGranted) {
          grantedResources.add(PermissionResourceType.MICROPHONE);
        }
      }
    }

    if (grantedResources.isNotEmpty) {
      return PermissionResponse(
        resources: grantedResources,
        action: PermissionResponseAction.GRANT,
      );
    }

    return PermissionResponse(
      resources: request.resources,
      action: PermissionResponseAction.DENY,
    );
  }

  /// Webview Geolocation (GPS) izin isteklerini yönetir
  Future<GeolocationPermissionShowPromptResponse?> handleGeolocationPrompt(
    String origin,
  ) async {
    if (!config.location) {
      return GeolocationPermissionShowPromptResponse(
        origin: origin,
        allow: false,
        retain: false,
      );
    }

    final status = await Permission.locationWhenInUse.request();
    final isAllowed = status.isGranted;

    return GeolocationPermissionShowPromptResponse(
      origin: origin,
      allow: isAllowed,
      retain: true,
    );
  }
}
