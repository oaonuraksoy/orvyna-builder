import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_config.dart';

/// 4 Farklı Çevrimdışı Modunu (Standard, Custom HTML, Cache Fallback, Mini Dino Game) destekleyen gelişmiş çevrimdışı ekranı
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
    switch (config.offlineModeType) {
      case OfflineModeType.customHtml:
        return _buildCustomHtmlScreen(context);
      case OfflineModeType.cacheFirstFallback:
        return _buildCacheFallbackScreen(context);
      case OfflineModeType.interactiveGame:
        return _buildInteractiveGameScreen(context);
      case OfflineModeType.standardRetry:
        return _buildStandardRetryScreen(context);
    }
  }

  /// 1. Standart Modern Yenile Butonlu Hata Ekranı
  Widget _buildStandardRetryScreen(BuildContext context) {
    final isDark = theme.backgroundColor.computeLuminance() < 0.5;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
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
                  config.offlineTitle.isNotEmpty ? config.offlineTitle : 'İnternet Bağlantısı Yok',
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
                  config.offlineMessage.isNotEmpty
                      ? config.offlineMessage
                      : 'Lütfen ağ bağlantınızı kontrol edip tekrar deneyiniz.',
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
                    config.retryButtonText.isNotEmpty ? config.retryButtonText : 'Tekrar Dene',
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

  /// 2. Özel HTML / Markdown Çevrimdışı Sayfası
  Widget _buildCustomHtmlScreen(BuildContext context) {
    final isDark = theme.backgroundColor.computeLuminance() < 0.5;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(config.offlineTitle.isNotEmpty ? config.offlineTitle : 'Çevrimdışı Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: config.retryButtonText,
            onPressed: onRetry,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  config.customOfflineHtml.isNotEmpty
                      ? config.customOfflineHtml
                      : config.offlineMessage,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.6,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(config.retryButtonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Önbellek Odaklı Çevrimdışı Sunum Ekranı
  Widget _buildCacheFallbackScreen(BuildContext context) {
    final isDark = theme.backgroundColor.computeLuminance() < 0.5;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? Colors.grey[400] : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: const Color(0xFF0EA5E9)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cached_rounded, size: 16.0, color: Color(0xFF0EA5E9)),
                      SizedBox(width: 6.0),
                      Text(
                        'Önbellek (Cache) Modu',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
                Icon(Icons.cloud_off_rounded, size: 56.0, color: theme.primaryColor),
                const SizedBox(height: 16.0),
                Text(
                  config.offlineTitle.isNotEmpty ? config.offlineTitle : 'Çevrimdışı Önbellek',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 8.0),
                Text(
                  config.offlineMessage.isNotEmpty
                      ? config.offlineMessage
                      : 'Şu anda yerel önbellek sürümündesiniz. Canlı veriler için internet bağlantısı bekleniyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.0, color: subtitleColor),
                ),
                const SizedBox(height: 28.0),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18.0),
                  label: Text(config.retryButtonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 4. İnteraktif Dinozor / Mini Runner Oyunu Ekranı
  Widget _buildInteractiveGameScreen(BuildContext context) {
    return _InteractiveDinoGameWidget(
      theme: theme,
      config: config,
      onRetry: onRetry,
    );
  }
}

/// İnternet yokken çalışan eğlenceli Dino Runner oyunu
class _InteractiveDinoGameWidget extends StatefulWidget {
  final ThemeConfig theme;
  final OfflineSettingsConfig config;
  final VoidCallback onRetry;

  const _InteractiveDinoGameWidget({
    required this.theme,
    required this.config,
    required this.onRetry,
  });

  @override
  State<_InteractiveDinoGameWidget> createState() => _InteractiveDinoGameWidgetState();
}

class _InteractiveDinoGameWidgetState extends State<_InteractiveDinoGameWidget>
    with SingleTickerProviderStateMixin {
  // Oyun Durumu
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _highScore = 0;

  // Dinozor Zıplama Fiziği
  double _dinoY = 0.0; // 0 = zemin, 1.0 = maksimum zıplama
  double _dinoVelocity = 0.0;
  static const double _gravity = -0.0035;
  static const double _jumpForce = 0.07;

  // Engel (Kaktüs / Kaya) Pozisyonu
  double _obstacleX = 1.2; // 1.2 = sağdan giriyor, -0.3 = soldan çıktı
  double _obstacleSpeed = 0.016;

  Timer? _gameLoopTimer;

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _dinoY = 0.0;
      _dinoVelocity = 0.0;
      _obstacleX = 1.2;
      _obstacleSpeed = 0.016;
    });

    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
  }

  void _jump() {
    if (!_isPlaying) {
      _startGame();
      return;
    }
    if (_dinoY == 0.0) {
      setState(() {
        _dinoVelocity = _jumpForce;
      });
    }
  }

  void _updateGame() {
    if (!mounted || !_isPlaying || _isGameOver) return;

    setState(() {
      // 1. Dinozor fiziği
      _dinoY += _dinoVelocity;
      _dinoVelocity += _gravity;
      if (_dinoY <= 0.0) {
        _dinoY = 0.0;
        _dinoVelocity = 0.0;
      }

      // 2. Engel hareketi
      _obstacleX -= _obstacleSpeed;
      if (_obstacleX < -0.2) {
        _obstacleX = 1.2 + (Random().nextDouble() * 0.4);
        _score += 10;
        if (_score > _highScore) _highScore = _score;
        // Hızı kademeli artır
        if (_obstacleSpeed < 0.035) {
          _obstacleSpeed += 0.0008;
        }
      }

      // 3. Çarpışma Testi (AABB Hitbox)
      // Dino hitbox: X: 0.15 - 0.28, Y: 0.0 - 0.25
      // Obstacle hitbox: X: _obstacleX, Y: 0.0 - 0.22
      if (_obstacleX > 0.08 && _obstacleX < 0.24 && _dinoY < 0.28) {
        _isGameOver = true;
        _isPlaying = false;
        _gameLoopTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.backgroundColor.computeLuminance() < 0.5;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.theme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Çevrimdışı Mini Oyun', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yeniden Bağlan',
            onPressed: widget.onRetry,
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: _jump,
          child: Column(
            children: [
              // Üst Skor & Bilgi Paneli
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.videogame_asset_rounded, color: Color(0xFF38BDF8), size: 20.0),
                        const SizedBox(width: 6.0),
                        Text(
                          'SKOR: $_score',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'EN YÜKSEK: $_highScore',
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),

              // Oyun Alanı (Canvas / Widget Simulator)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final obstaclePosX = _obstacleX * constraints.maxWidth;

                      return Stack(
                        children: [
                          // Bulutlar
                          Positioned(
                            top: 24.0,
                            left: 40.0,
                            child: Icon(Icons.cloud_rounded, color: isDark ? Colors.white12 : Colors.black12, size: 36.0),
                          ),
                          Positioned(
                            top: 50.0,
                            right: 60.0,
                            child: Icon(Icons.cloud_rounded, color: isDark ? Colors.white10 : Colors.black12, size: 28.0),
                          ),

                          // Zemin Çizgisi
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 40.0,
                            child: Container(
                              height: 3.0,
                              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                            ),
                          ),

                          // Dinozor Karakteri
                          Positioned(
                            left: 40.0,
                            bottom: 40.0 + (_dinoY * 180.0),
                            child: Container(
                              width: 38.0,
                              height: 42.0,
                              decoration: BoxDecoration(
                                color: widget.theme.primaryColor,
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.theme.primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 8.0,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                color: Colors.white,
                                size: 24.0,
                              ),
                            ),
                          ),

                          // Engel (Kaktüs / Kaya)
                          Positioned(
                            left: obstaclePosX,
                            bottom: 40.0,
                            child: Container(
                              width: 26.0,
                              height: 36.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 18.0,
                              ),
                            ),
                          ),

                          // Başlangıç veya Oyun Bitti Katmanı
                          if (!_isPlaying)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(16.0),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 16.0),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isGameOver ? Icons.sports_score_rounded : Icons.touch_app_rounded,
                                      size: 44.0,
                                      color: _isGameOver ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                                    ),
                                    const SizedBox(height: 12.0),
                                    Text(
                                      _isGameOver ? 'OYUN BİTTİ!' : 'Zıplamak İçin Ekrana Dokunun',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6.0),
                                    Text(
                                      _isGameOver ? 'Son Skor: $_score' : 'İnternet beklenirken eğlenin!',
                                      style: const TextStyle(fontSize: 13.0, color: Color(0xFF94A3B8)),
                                    ),
                                    const SizedBox(height: 16.0),
                                    ElevatedButton.icon(
                                      onPressed: _startGame,
                                      icon: Icon(_isGameOver ? Icons.replay_rounded : Icons.play_arrow_rounded),
                                      label: Text(_isGameOver ? 'Yeniden Oyna' : 'Oyunu Başlat'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: widget.theme.primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Alt Butonlar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _jump,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        label: const Text('ZIPLA (Dokun)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(widget.config.retryButtonText.isNotEmpty ? widget.config.retryButtonText : 'Yenile'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

