import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/app_config.dart';

/// AdMob Monetization Servisi (Banner, Interstitial, App Open)
class AdMobService {
  final MonetizationConfig config;
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  bool _isInterstitialLoading = false;
  bool _isAppOpenLoading = false;
  int _pageNavigationCounter = 0;
  DateTime? _lastInterstitialShownTime;
  bool _isInitialized = false;

  AdMobService({required this.config});

  /// AdMob SDK'sını başlatır
  Future<void> initialize() async {
    if (!config.admobEnabled) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;

      // Interstitial ve App Open reklamları önceden yükle
      if (config.interstitialEnabled) {
        _loadInterstitialAd();
      }
      if (config.appOpenEnabled) {
        _loadAppOpenAd();
      }

      debugPrint('[AdMobService] Google Mobile Ads SDK başarıyla başlatıldı.');
    } catch (e) {
      debugPrint('[AdMobService] SDK başlatma hatası: $e');
    }
  }

  // --- BANNER REKLAM ---
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return config.bannerIdAndroid.isNotEmpty
          ? config.bannerIdAndroid
          : 'ca-app-pub-3940256099942544/6300978111'; // Android Test ID
    } else if (Platform.isIOS) {
      return config.bannerIdIos.isNotEmpty
          ? config.bannerIdIos
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS Test ID
    }
    return '';
  }

  /// Banner reklam widget'ı oluşturur
  Widget buildBannerWidget() {
    if (!config.admobEnabled || !config.bannerEnabled || !_isInitialized) {
      return const SizedBox.shrink();
    }

    return _BannerAdWidget(adUnitId: bannerAdUnitId);
  }

  // --- INTERSTITIAL REKLAM ---
  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return config.interstitialIdAndroid.isNotEmpty
          ? config.interstitialIdAndroid
          : 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return config.interstitialIdIos.isNotEmpty
          ? config.interstitialIdIos
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  void _loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('[AdMobService] Interstitial reklam yüklendi.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          debugPrint('[AdMobService] Interstitial yükleme başarısız: $error');
        },
      ),
    );
  }

  /// Sayfa geçişinde interstitial reklamı kontrol eder ve gerekiyorsa gösterir
  void onPageNavigated() {
    if (!config.admobEnabled || !config.interstitialEnabled || !_isInitialized) return;

    _pageNavigationCounter++;

    final now = DateTime.now();
    final timePassed = _lastInterstitialShownTime == null ||
        now.difference(_lastInterstitialShownTime!).inSeconds >= config.interstitialTimeIntervalSeconds;

    if (_pageNavigationCounter >= config.interstitialPageInterval && timePassed) {
      showInterstitialAd();
    }
  }

  void showInterstitialAd() {
    if (_interstitialAd == null) {
      _loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _pageNavigationCounter = 0;
        _lastInterstitialShownTime = DateTime.now();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
  }

  // --- APP OPEN REKLAM ---
  String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return config.appOpenIdAndroid.isNotEmpty
          ? config.appOpenIdAndroid
          : 'ca-app-pub-3940256099942544/3419832817';
    } else if (Platform.isIOS) {
      return config.appOpenIdIos.isNotEmpty
          ? config.appOpenIdIos
          : 'ca-app-pub-3940256099942544/5662645252';
    }
    return '';
  }

  void _loadAppOpenAd() {
    if (_isAppOpenLoading || _appOpenAd != null) return;
    _isAppOpenLoading = true;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
          debugPrint('[AdMobService] App Open reklam yüklendi.');
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _isAppOpenLoading = false;
          debugPrint('[AdMobService] App Open yükleme hatası: $error');
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    if (!config.admobEnabled || !config.appOpenEnabled || !_isInitialized) return;

    if (_appOpenAd == null) {
      _loadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _appOpenAd?.dispose();
  }
}

class _BannerAdWidget extends StatefulWidget {
  final String adUnitId;

  const _BannerAdWidget({required this.adUnitId});

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('[AdMobService] Banner yüklenemedi: $error');
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
}
