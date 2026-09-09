# Orvyna Public Documentation & GitHub Pages Site

Bu klasör (`docs/`), `orvyna-builder` genel reposunun GitHub Pages üzerinden resmi web sitesi (`https://orvyna.tr`) olarak yayınlanmasını sağlar.

## 🚀 GitHub Pages Yapılandırması

Deponun web sitesi olarak yayına girmesi için:
1. GitHub deposunda **Settings** (Ayarlar) sekmesine gidin.
2. Sol menüden **Pages** seçeneğine tıklayın.
3. **Build and deployment** altında:
   - **Source:** `Deploy from a branch`
   - **Branch:** `main` / `/docs`
4. **Custom domain** alanına `orvyna.tr` girin ve **Save**'e tıklayın.
5. DNS tarafında `orvyna.tr` için GitHub Pages A/CNAME kayıtlarının yönlendirildiğinden ve HTTPS sertifikasının ("Enforce HTTPS") aktif olduğundan emin olun.

## 📁 Sayfalar

- `index.html`: Orvyna Landing Page (Özellikler, Tanıtım, İletişim)
- `privacy.html`: Apple Store Guideline 5.1, KVKK ve GDPR uyumlu Resmi Gizlilik Politikası
- `terms.html`: Resmi Kullanım Koşulları (Terms of Service)
- `CNAME`: `orvyna.tr` alan adı tanımlayıcısı
- `.nojekyll`: GitHub Pages'in saf HTML dosyalarını işlemeden sunması için bayrak dosyası
