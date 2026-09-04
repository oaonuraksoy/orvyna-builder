import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../models/app_config.dart';

/// Akıllı Mağaza İçi Puanlama ve Değerlendirme Servisi
class InAppReviewService {
  final InAppReviewConfig config;
  final String? packageName;
  final InAppReview _inAppReview = InAppReview.instance;

  int _launchCount = 0;
  int _actionCount = 0;
  DateTime _firstLaunchDate = DateTime.now();
  bool _hasPrompted = false;

  InAppReviewService({
    required this.config,
    this.packageName,
  });

  int get launchCount => _launchCount;
  int get actionCount => _actionCount;
  DateTime get firstLaunchDate => _firstLaunchDate;
  bool get hasPrompted => _hasPrompted;
  bool get isEnabled => config.enabled;

  /// Puanlama gösterildi olarak işaretler
  void recordPromptShown() {
    _hasPrompted = true;
  }

  /// Uygulama her açıldığında sayacı artırır
  void recordAppLaunch() {
    if (!config.enabled) return;
    _launchCount++;
  }

  /// Kullanıcı önemli bir işlem yaptığında (sayfa gezintisi, sipariş, form vb.) çağrılır
  void recordUserAction() {
    if (!config.enabled) return;
    _actionCount++;
  }

  /// Puanlama kutusunun gösterilme vaktinin gelip gelmediğini kontrol eder
  bool shouldPromptReview() {
    if (!config.enabled) return false;
    if (_hasPrompted) return false;

    final daysPassed = DateTime.now().difference(_firstLaunchDate).inDays;
    final meetsLaunchCount = _launchCount >= config.launchCountTrigger;
    final meetsDays = daysPassed >= config.daysUntilPrompt;
    final meetsActions = _actionCount >= config.minActionsTrigger;

    return meetsLaunchCount && meetsDays && meetsActions;
  }

  /// Puanlama akışını tetikler
  Future<bool> requestReview({
    BuildContext? context,
    String? storeUrl,
    bool force = false,
  }) async {
    if (!force && !shouldPromptReview()) {
      return false;
    }
    _hasPrompted = true;
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        return true;
      }
    } catch (_) {}

    if (context != null && context.mounted) {
      return await showRatingDialog(context, storeUrl: storeUrl);
    } else {
      await openStoreListing(storeUrl);
      return true;
    }
  }

  /// Mağaza sayfasını açar (Google Play veya App Store)
  Future<void> openStoreListing(String? targetUrl) async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.openStoreListing(appStoreId: packageName);
        return;
      }
    } catch (_) {}

    final effectiveUrl = (targetUrl != null && targetUrl.isNotEmpty)
        ? targetUrl
        : (config.customReviewUrl.isNotEmpty
            ? config.customReviewUrl
            : (packageName != null
                ? 'market://details?id=$packageName'
                : 'https://play.google.com/store/apps'));

    try {
      final uri = Uri.parse(effectiveUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback web url
        final webUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=${packageName ?? "com.example.app"}',
        );
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[InAppReviewService] Mağaza açma hatası: $e');
    }
  }

  /// 5 Yıldızlı Akıllı Değerlendirme Diyalogu (4-5 Yıldız Mağazaya, 1-3 Yıldız Geri Bildirime)
  Future<bool> showRatingDialog(
    BuildContext context, {
    String? storeUrl,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _RatingPromptDialog(
        onPositiveRated: (rating) async {
          Navigator.of(ctx).pop(true);
          await openStoreListing(storeUrl);
        },
        onFeedbackGiven: (feedback, rating) {
          Navigator.of(ctx).pop(false);
          debugPrint('[InAppReviewService] Kullanıcı geri bildirimi ($rating yıldız): $feedback');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geri bildiriminiz için teşekkür ederiz! Deneyiminizi geliştireceğiz.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        },
      ),
    );

    return result ?? false;
  }

  void markReviewed() {
    _hasPrompted = true;
  }

  void resetCounters() {
    _launchCount = 0;
    _actionCount = 0;
    _firstLaunchDate = DateTime.now();
    _hasPrompted = false;
  }
}

class _RatingPromptDialog extends StatefulWidget {
  final ValueChanged<int> onPositiveRated;
  final Function(String feedback, int rating) onFeedbackGiven;

  const _RatingPromptDialog({
    required this.onPositiveRated,
    required this.onFeedbackGiven,
  });

  @override
  State<_RatingPromptDialog> createState() => _RatingPromptDialogState();
}

class _RatingPromptDialogState extends State<_RatingPromptDialog> {
  int _selectedRating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _showFeedbackInput = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      backgroundColor: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 40.0),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Uygulamamızı Beğendiniz mi?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6.0),
            const Text(
              'Deneyiminizi geliştirmemiz için lütfen birkaç saniyenizi ayırıp bizi değerlendirin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), height: 1.3),
            ),
            const SizedBox(height: 18.0),

            // Yıldız Seçici
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = starValue <= _selectedRating;
                return IconButton(
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF475569),
                    size: 32.0,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = starValue;
                      _showFeedbackInput = starValue <= 3;
                    });
                  },
                );
              }),
            ),

            if (_showFeedbackInput) ...[
              const SizedBox(height: 14.0),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13.0, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Neyi daha iyi yapabiliriz? Görüşlerinizi yazın...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20.0),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Daha Sonra', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedRating >= 4) {
                        widget.onPositiveRated(_selectedRating);
                      } else {
                        widget.onFeedbackGiven(_feedbackController.text.trim(), _selectedRating);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    child: Text(
                      _selectedRating >= 4 ? 'Mağazada Puanla' : 'Geri Bildirim Gönder',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
