import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_config.dart';

/// WhatsApp / Canlı Destek Yüzen Aksiyon Butonu (Floating Support Button)
class FloatingSupportButton extends StatefulWidget {
  final FloatingButtonConfig config;
  final VoidCallback? onCustomTap;

  const FloatingSupportButton({
    super.key,
    required this.config,
    this.onCustomTap,
  });

  @override
  State<FloatingSupportButton> createState() => _FloatingSupportButtonState();
}

class _FloatingSupportButtonState extends State<FloatingSupportButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAction() async {
    HapticFeedback.lightImpact();

    if (widget.onCustomTap != null) {
      widget.onCustomTap!();
      return;
    }

    final target = widget.config.target.trim();
    final type = widget.config.type.toLowerCase();

    try {
      if (type == 'whatsapp') {
        final cleanPhone = target.replaceAll(RegExp(r'[^0-9]'), '');
        final waUrl = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent("Merhaba, destek almak istiyorum.")}';
        final uri = Uri.parse(waUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (type == 'phone') {
        final uri = Uri.parse('tel:$target');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        // live_chat veya custom_url
        final uri = Uri.parse(target.startsWith('http') ? target : 'https://$target');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('[FloatingSupportButton] Açma hatası: $e');
    }
  }

  IconData _resolveIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'whatsapp':
        return Icons.chat_bubble_rounded;
      case 'chat':
        return Icons.forum_rounded;
      case 'support':
        return Icons.support_agent_rounded;
      case 'phone':
        return Icons.phone_in_talk_rounded;
      case 'help':
        return Icons.help_outline_rounded;
      default:
        return Icons.chat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.config.enabled) return const SizedBox.shrink();

    final isBottom = widget.config.position.toLowerCase().contains('bottom');
    final isRight = widget.config.position.toLowerCase().contains('right');

    final color = widget.config.backgroundColor;
    final hasLabel = widget.config.label.trim().isNotEmpty;

    return Positioned(
      bottom: isBottom ? 24.0 : null,
      top: !isBottom ? 24.0 : null,
      right: isRight ? 20.0 : null,
      left: !isRight ? 20.0 : null,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.04),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Tooltip(
              message: widget.config.tooltip.isNotEmpty
                  ? widget.config.tooltip
                  : 'Canlı Destek',
              child: InkWell(
                onTap: _handleAction,
                borderRadius: BorderRadius.circular(30.0),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: hasLabel ? 16.0 : 14.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(30.0),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 14.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            _resolveIcon(widget.config.icon),
                            color: Colors.white,
                            size: 22.0,
                          ),
                          if (widget.config.showBadge)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (hasLabel) ...[
                        const SizedBox(width: 8.0),
                        Text(
                          widget.config.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
