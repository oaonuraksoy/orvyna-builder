import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/app_config.dart';

/// Webview sayfası yüklenirken gösterilen animasyonlu Shimmer iskelet bileşeni
/// Merkezinde Logo, Başlık, İnce Progress Bar ve "Yükleniyor..." metni barındırır.
class ShimmerLoadingView extends StatelessWidget {
  final ThemeConfig theme;
  final String appName;
  final String splashBase64;
  final String iconBase64;
  final bool? splashShowTitle;
  final bool? splashShowLoadingBar;
  final String? splashLoadingText;

  const ShimmerLoadingView({
    super.key,
    required this.theme,
    this.appName = '',
    this.splashBase64 = '',
    this.iconBase64 = '',
    this.splashShowTitle,
    this.splashShowLoadingBar,
    this.splashLoadingText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.backgroundColor.computeLuminance() < 0.5;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    final showTitle = splashShowTitle ?? theme.splashShowTitle;
    final showLoadingBar = splashShowLoadingBar ?? theme.splashShowLoadingBar;
    final loadingText = splashLoadingText ?? theme.splashLoadingText;

    ImageProvider? logoImage;
    if (splashBase64.isNotEmpty) {
      try {
        logoImage = MemoryImage(base64Decode(splashBase64.replaceAll(RegExp(r'\s+'), '')));
      } catch (_) {}
    } else if (iconBase64.isNotEmpty) {
      try {
        logoImage = MemoryImage(base64Decode(iconBase64.replaceAll(RegExp(r'\s+'), '')));
      } catch (_) {}
    }

    return Container(
      color: theme.backgroundColor,
      child: Stack(
        children: [
          // 1. Arka Plan Shimmer İskelet Katmanı (Zero CLS)
          Opacity(
            opacity: 0.35,
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Banner Skeleton
                    Container(
                      width: double.infinity,
                      height: 180.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Horizontal Category Chips Placeholder
                    Row(
                      children: List.generate(4, (index) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: index == 3 ? 0 : 8.0),
                            height: 38.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24.0),

                    // Grid Content Cards Placeholder
                    Row(
                      children: [
                        Expanded(child: _buildCardSkeleton()),
                        const SizedBox(width: 12.0),
                        Expanded(child: _buildCardSkeleton()),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // List Items Placeholder
                    _buildListRowSkeleton(),
                    const SizedBox(height: 12.0),
                    _buildListRowSkeleton(),
                  ],
                ),
              ),
            ),
          ),

          // 2. Merkez Splash & Loading Bar Katmanı (Tam Dikey ve Yatay Merkezleme)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32.0),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.6)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 24.0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo / İkon
                  if (logoImage != null)
                    Container(
                      width: 72.0,
                      height: 72.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 16.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image(image: logoImage, fit: BoxFit.contain),
                      ),
                    )
                  else
                    Container(
                      width: 64.0,
                      height: 64.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.primaryColor, theme.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18.0),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 16.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.public_rounded, size: 36.0, color: Colors.white),
                    ),

                  if (showTitle) ...[
                    const SizedBox(height: 16.0),
                    // Uygulama Başlığı (Tam Ortalanmış & Şık Tipografi)
                    Text(
                      appName.isNotEmpty ? appName : 'Web2App',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],

                  if (showLoadingBar) ...[
                    const SizedBox(height: 18.0),
                    // Şık İnce Loading Bar (Progress Bar)
                    SizedBox(
                      width: 140.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: LinearProgressIndicator(
                          minHeight: 3.5,
                          backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                        ),
                      ),
                    ),
                  ],

                  if (loadingText.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    // Özel Yüklenme Metni (Tam Ortalanmış)
                    Text(
                      loadingText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      height: 140.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
    );
  }

  Widget _buildListRowSkeleton() {
    return Row(
      children: [
        Container(
          width: 50.0,
          height: 50.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 14.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                width: 140.0,
                height: 12.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
