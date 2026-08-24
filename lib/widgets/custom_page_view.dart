import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_config.dart';

/// 3 Farklı Layout Şablonunu (Document, CardGrid, HeroContact) destekleyen zengin Custom Page render bileşeni
class CustomPageView extends StatefulWidget {
  final CustomPageConfig page;
  final ThemeConfig theme;
  final VoidCallback onBackToHome;
  final ValueChanged<String>? onNavigateCustomPage;

  const CustomPageView({
    super.key,
    required this.page,
    required this.theme,
    required this.onBackToHome,
    this.onNavigateCustomPage,
  });

  @override
  State<CustomPageView> createState() => _CustomPageViewState();
}

class _CustomPageViewState extends State<CustomPageView> {
  final Set<int> _expandedFaqIndices = {0}; // İlk FAQ varsayılan açık

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[CustomPageView] URL launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.page.layout) {
      case CustomPageLayout.cardGrid:
        return _buildCardGridLayout(context);
      case CustomPageLayout.heroContact:
        return _buildHeroContactLayout(context);
      case CustomPageLayout.document:
        return _buildDocumentLayout(context);
    }
  }

  /// 1. DOCUMENT LAYOUT: Temiz, Tipografik Makale / Metin Stili (Hakkımızda, KVKK, Gizlilik)
  Widget _buildDocumentLayout(BuildContext context) {
    final isDark = widget.theme.backgroundColor.computeLuminance() < 0.5;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.theme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Ana Sayfaya Dön',
          onPressed: widget.onBackToHome,
        ),
        title: Text(
          widget.page.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sayfa Üst Bilgi Rozeti
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: widget.theme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_rounded, size: 14.0, color: widget.theme.primaryColor),
                  const SizedBox(width: 6.0),
                  Text(
                    'Resmi Bilgilendirme Belgesi',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),

            // Başlık
            Text(
              widget.page.title,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Son Güncelleme: ${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12.0, color: mutedColor),
            ),
            const SizedBox(height: 16.0),
            Divider(color: borderColor),
            const SizedBox(height: 16.0),

            // Paragraflar ve Markdown Benzeri Formatlama
            ..._parseMarkdownToWidgets(
              content: widget.page.content,
              textColor: textColor,
              mutedColor: mutedColor,
              cardBg: cardBg,
              borderColor: borderColor,
            ),

            const SizedBox(height: 32.0),
            Center(
              child: OutlinedButton.icon(
                onPressed: widget.onBackToHome,
                icon: const Icon(Icons.home_rounded),
                label: const Text('Ana Sayfaya Dön'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  /// 2. CARD & GRID LAYOUT: Kartlar, Rozetler ve Akordeon SSS Stili
  Widget _buildCardGridLayout(BuildContext context) {
    final isDark = widget.theme.backgroundColor.computeLuminance() < 0.5;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final sections = _extractFaqSections(widget.page.content);

    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.theme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Ana Sayfaya Dön',
          onPressed: widget.onBackToHome,
        ),
        title: Text(
          widget.page.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Başlık & Giriş Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.theme.primaryColor.withValues(alpha: 0.15),
                    widget.theme.accentColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: widget.theme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.quiz_rounded, color: widget.theme.primaryColor, size: 24.0),
                      const SizedBox(width: 8.0),
                      Text(
                        widget.page.title,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Merak ettiğiniz tüm soruların yanıtları ve detaylı açıklamalar aşağıda listelenmiştir.',
                    style: TextStyle(fontSize: 13.0, color: mutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Akordeon FAQ Listesi
            if (sections.isNotEmpty)
              ...List.generate(sections.length, (index) {
                final item = sections[index];
                final isExpanded = _expandedFaqIndices.contains(index);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isExpanded ? widget.theme.primaryColor : borderColor,
                      width: isExpanded ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                      key: PageStorageKey('faq_$index'),
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          if (expanded) {
                            _expandedFaqIndices.add(index);
                          } else {
                            _expandedFaqIndices.remove(index);
                          }
                        });
                      },
                      leading: CircleAvatar(
                        radius: 14.0,
                        backgroundColor: isExpanded
                            ? widget.theme.primaryColor
                            : widget.theme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            color: isExpanded ? Colors.white : widget.theme.primaryColor,
                          ),
                        ),
                      ),
                      title: Text(
                        item.question,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.answer,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                color: mutedColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
            else
              ..._parseMarkdownToWidgets(
                content: widget.page.content,
                textColor: textColor,
                mutedColor: mutedColor,
                cardBg: cardBg,
                borderColor: borderColor,
              ),

            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  /// 3. HERO & CONTACT LAYOUT: Degrade Hero Banner, İletişim Butonları ve CTA Stili
  Widget _buildHeroContactLayout(BuildContext context) {
    final isDark = widget.theme.backgroundColor.computeLuminance() < 0.5;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Degrade Hero Banner AppBar
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            backgroundColor: widget.theme.primaryColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Ana Sayfaya Dön',
              onPressed: widget.onBackToHome,
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.page.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.theme.primaryColor, widget.theme.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.headset_mic_rounded, size: 36.0, color: Colors.white),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Size Yardımcı Olmaktan Mutluluk Duyarız',
                        style: TextStyle(fontSize: 12.0, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // İçerik ve İletişim Butonları
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hızlı İletişim Buton Kartları (Telefon, E-posta, WhatsApp, Harita)
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactActionTile(
                          icon: Icons.phone_rounded,
                          label: 'Bizi Arayın',
                          subtitle: 'Müşteri Hizmetleri',
                          color: const Color(0xFF2563EB),
                          onTap: () => _launchUrl('tel:+905551234567'),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: _buildContactActionTile(
                          icon: Icons.chat_rounded,
                          label: 'WhatsApp',
                          subtitle: 'Canlı Mesajlaşma',
                          color: const Color(0xFF25D366),
                          onTap: () => _launchUrl('https://wa.me/905551234567'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactActionTile(
                          icon: Icons.email_rounded,
                          label: 'E-posta Gönder',
                          subtitle: 'Destek Ekibi',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => _launchUrl('mailto:destek@example.com'),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: _buildContactActionTile(
                          icon: Icons.location_on_rounded,
                          label: 'Konum & Adres',
                          subtitle: 'Haritada Gör',
                          color: const Color(0xFFEA580C),
                          onTap: () => _launchUrl('https://maps.google.com'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24.0),
                  Text(
                    'İletişim & Açıklama Detayları',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12.0),

                  // Markdown Metni
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _parseMarkdownToWidgets(
                        content: widget.page.content,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        cardBg: cardBg,
                        borderColor: borderColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: Colors.white, size: 18.0),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Basit, sağlam ve zarif Markdown Metin Çözümleyici
  List<Widget> _parseMarkdownToWidgets({
    required String content,
    required Color textColor,
    required Color mutedColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    final List<Widget> widgets = [];
    final lines = content.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8.0));
        continue;
      }

      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
            child: Text(
              line.substring(4),
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 18.0, bottom: 8.0),
            child: Text(
              line.substring(3),
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: textColor),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
            child: Text(
              line.substring(2),
              style: TextStyle(fontSize: 21.0, fontWeight: FontWeight.w900, color: textColor),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6.0, right: 8.0),
                  width: 6.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: widget.theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: TextStyle(fontSize: 14.0, height: 1.5, color: textColor),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.startsWith('> ')) {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: widget.theme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.0),
              border: Border(left: BorderSide(color: widget.theme.primaryColor, width: 4.0)),
            ),
            child: Text(
              line.substring(2),
              style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: textColor),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              line,
              style: TextStyle(fontSize: 14.0, height: 1.6, color: textColor),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Soru & Cevap formatını tespit eder (Soru? -> Cevap)
  List<({String question, String answer})> _extractFaqSections(String content) {
    final List<({String question, String answer})> items = [];
    final blocks = content.split(RegExp(r'\n(?=#{1,3}\s|\d+\.\s)'));

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.isNotEmpty) {
        String q = lines[0].replaceFirst(RegExp(r'^(#{1,3}\s*|\d+\.\s*)'), '').trim();
        String a = lines.skip(1).join('\n').trim();
        if (q.isNotEmpty) {
          items.add((question: q, answer: a.isNotEmpty ? a : 'Ayrıntılı bilgi için destek ekibimize ulaşabilirsiniz.'));
        }
      }
    }

    return items;
  }
}
