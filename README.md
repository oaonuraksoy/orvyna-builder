# 🚀 Orvyna Builder Engine

**Orvyna Builder Engine**, [Orvyna App Studio Pro](https://orvyna.tr) masaüstü stüdyosu tarafından yapılandırılan web uygulamalarını yüksek performanslı native Android ve iOS paketlerine dönüştüren resmi bulut ve yerel derleme çekirdeğidir.

Bu depo, Orvyna kullanıcılarının kendi GitHub Actions kotaları üzerinden bağımsız, güvenli ve otomatik mobil derleme (CI/CD) alabilmeleri için tasarlanmıştır.

---

## 🌟 Özellikler

- **📱 Gelişmiş Webview Motoru:** Donanım hızlandırmalı, pürüzsüz kaydırma ve Zero-CLS (Cumulative Layout Shift) önleyici akıllı iskelet yükleyici.
- **🛡️ Biyometrik Doğrulama:** Touch ID, Face ID ve Parmak İzi desteği (`local_auth`).
- **🦖 Çevrimdışı Dino Mini Oyunu:** 60 FPS `Ticker` motoru ile internet kesintilerinde eğlenceli bekleme ekranı.
- **🔔 Anlık Bildirimler & Reklam:** OneSignal Push ve Google AdMob (Banner, Interstitial, Rewarded, App Open).
- **⚡ GitHub Actions CI/CD:** 
  - Android APK (Evrensel veya mimari bazlı)
  - Android App Bundle (Google Play Store AAB)
  - iOS IPA & TestFlight dağıtımı (Fastlane entegrasyonu)

---

## 🛠️ İş Akışları (Workflows)

Bu depo iki temel GitHub Actions iş akışına sahiptir:

| İş Akışı | Dosya | Açıklama |
|---|---|---|
| **Android AAB & APK Build** | `.github/workflows/build_android.yml` | `workflow_dispatch` ile tetiklenir; Keystore imzalama, ikon üretimi ve APK/AAB derlemesini gerçekleştirir. |
| **iOS Build & TestFlight** | `.github/workflows/deploy_ios.yml` | `workflow_dispatch` ile tetiklenir; iOS IPA derlemesini ve TestFlight gönderimini Fastlane ile yürütür. |

---

## 🔒 Güvenlik & Konfigürasyon

Uygulama ayarları, ikonlar, renkler ve imzalama anahtarları bu depoda saklanmaz. Tüm konfigürasyon, **Orvyna App Studio** masaüstü uygulamasından derleme anında dinamik olarak enjekte edilir:

```bash
# Yerel yapılandırma aracı
dart tool/apply_app_config.dart --platform=android
dart tool/apply_app_config.dart --platform=ios
```

---

## 📄 Lisans

Bu proje Orvyna ekosisteminin bir parçasıdır. Tüm hakları saklıdır.
