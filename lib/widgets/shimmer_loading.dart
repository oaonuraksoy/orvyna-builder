import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/app_config.dart';

/// Webview sayfası yüklenirken gösterilen animasyonlu Shimmer iskelet bileşeni
class ShimmerLoadingView extends StatelessWidget {
  final ThemeConfig theme;

  const ShimmerLoadingView({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.backgroundColor.computeLuminance() < 0.5;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      color: theme.backgroundColor,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner Placeholder
              Container(
                width: double.infinity,
                height: 180.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              const SizedBox(height: 24.0),

              // Title bar placeholder
              Container(
                width: 140.0,
                height: 20.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              const SizedBox(height: 16.0),

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
              const SizedBox(height: 12.0),
              _buildListRowSkeleton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      height: 160.0,
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
          width: 54.0,
          height: 54.0,
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
                width: 160.0,
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
