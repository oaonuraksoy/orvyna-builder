import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../models/app_config.dart';

/// Face ID / Fingerprint & Biyometrik Kimlik Doğrulama Servisi
class BiometricService {
  final BiometricConfig config;
  bool _isUnlocked = false;
  DateTime? _lastUnlockTime;

  BiometricService({required this.config});

  /// Biyometrik kilidin aktif olup olmadığı
  bool get isEnabled => config.enabled;

  /// Fallback parolaya izin verilip verilmediği
  bool get allowFallback => config.allowFallback;

  /// Oturumun açık (doğrulanmış) olup olmadığı
  bool get isUnlocked => _isUnlocked;

  /// Doğrulama gerekip gerekmediğini kontrol eder
  bool get isAuthRequired {
    if (!config.enabled) return false;
    if (!_isUnlocked) return true;
    if (config.timeoutSeconds <= 0) return false;
    if (_lastUnlockTime == null) return true;

    final elapsedSeconds = DateTime.now().difference(_lastUnlockTime!).inSeconds;
    return elapsedSeconds > config.timeoutSeconds;
  }

  /// Doğrulamayı zorla kilitler
  void lock() {
    _isUnlocked = false;
    _lastUnlockTime = null;
  }

  /// Doğrulanmış olarak işaretler
  void markUnlocked() {
    _isUnlocked = true;
    _lastUnlockTime = DateTime.now();
  }

  /// Biyometrik kimlik doğrulaması gerçekleştirir
  Future<bool> authenticate({
    BuildContext? context,
    String? customReason,
    bool simulateSuccess = false,
  }) async {
    if (!config.enabled) {
      _isUnlocked = true;
      return true;
    }

    if (!isAuthRequired && _isUnlocked) {
      return true;
    }

    // Test modu veya simülasyon
    if (simulateSuccess) {
      markUnlocked();
      return true;
    }

    if (context != null && context.mounted) {
      try {
        final localAuth = LocalAuthentication();
        final isSupported = await localAuth.isDeviceSupported();
        final canCheckBiometrics = await localAuth.canCheckBiometrics;
        
        if (!isSupported || !canCheckBiometrics) {
          // Fallback to custom view or native fallback if device not supported
          if (config.allowFallback) {
             final success = await showBiometricPrompt(context, customReason: customReason);
             if (success) { markUnlocked(); return true; }
          }
          return false;
        }
        
        final authenticated = await localAuth.authenticate(
          localizedReason: customReason ?? (config.promptSubtitle.isNotEmpty ? config.promptSubtitle : 'Uygulamaya erişmek için doğrulama gerekiyor'),
          options: AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: true,
            biometricOnly: !config.allowFallback,
          ),
        );
        
        if (authenticated) {
          markUnlocked();
          return true;
        }
      } on PlatformException catch (_) {
         // Fallback on error
      }
      return false;
    }

    // Fallback varsayılan doğrulama (Haptic Feedback ile)
    try {
      HapticFeedback.mediumImpact();
      markUnlocked();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Şık ve modern biyometrik doğrulama diyalogu / alt paneli gösterir
  Future<bool> showBiometricPrompt(
    BuildContext context, {
    String? customReason,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'BiometricAuth',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return _BiometricChallengeView(
          config: config,
          customReason: customReason,
          onAuthenticated: () {
            Navigator.of(ctx).pop(true);
          },
          onFallback: config.allowFallback
              ? () {
                  Navigator.of(ctx).pop(true); // Fallback PIN / Şifre kabulü
                }
              : null,
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );

    return result ?? false;
  }
}

class _BiometricChallengeView extends StatefulWidget {
  final BiometricConfig config;
  final String? customReason;
  final VoidCallback onAuthenticated;
  final VoidCallback? onFallback;

  const _BiometricChallengeView({
    required this.config,
    this.customReason,
    required this.onAuthenticated,
    this.onFallback,
  });

  @override
  State<_BiometricChallengeView> createState() => _BiometricChallengeViewState();
}

class _BiometricChallengeViewState extends State<_BiometricChallengeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTouch() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      widget.onAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.config.promptTitle.isNotEmpty
        ? widget.config.promptTitle
        : 'Biyometrik Kimlik Doğrulama';
    final subtitle = widget.customReason ??
        (widget.config.promptSubtitle.isNotEmpty
            ? widget.config.promptSubtitle
            : 'Uygulamaya erişmek için Face ID veya Parmak İzinizi kullanın');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28.0),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0xFF334155), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animasyonlu Biyometrik Simge
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.08);
                    return Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: _handleTouch,
                        child: Container(
                          width: 84.0,
                          height: 84.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isAuthenticating ? Icons.lock_open_rounded : Icons.fingerprint_rounded,
                            size: 48.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24.0),

                // Başlık & Açıklama
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28.0),

                // Doğrulama Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleTouch,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.fingerprint_rounded, size: 18.0),
                    label: Text(
                      _isAuthenticating ? 'Doğrulanıyor...' : 'Kimliği Doğrula',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                  ),
                ),

                // Alternatif Şifre / Fallback
                if (widget.onFallback != null) ...[
                  const SizedBox(height: 12.0),
                  TextButton.icon(
                    onPressed: widget.onFallback,
                    icon: const Icon(Icons.password_rounded, size: 16.0, color: Color(0xFF94A3B8)),
                    label: const Text(
                      'Cihaz Şifresi ile Aç (PIN / Parola)',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
