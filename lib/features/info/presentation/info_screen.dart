import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_theme.dart';

class InfoScreen extends StatefulWidget {
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenNotifications;

  const InfoScreen({
    super.key,
    required this.onToggleLanguage,
    required this.onOpenNotifications,
  });

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  List<Map<String, dynamic>> _contentList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('KnowledgeHubScreen');
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      final response = await Supabase.instance.client
          .from('content_items')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      setState(() {
        _contentList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String? urlString, String title, String type) async {
    if (urlString == null || urlString.isEmpty) return;
    AnalyticsService.logViewGuide(title, type);
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKn = Localizations.localeOf(context).languageCode == 'kn';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isKn ? 'ರೇಷ್ಮೆ ಕೃಷಿ ಮಾಹಿತಿ & ವಿಡಿಯೋಗಳು' : 'Farming Tutorials & Guides'),
        actions: [
          // 1-Tap Language Toggle in Header
          InkWell(
            onTap: widget.onToggleLanguage,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    isKn ? 'EN' : 'ಕನ್ನಡ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: widget.onOpenNotifications,
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchContent,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contentList.isEmpty
              ? Center(
                  child: Text(
                    isKn ? 'ಮಾಹಿತಿ ಲೇಖನಗಳು ಲಭ್ಯವಿಲ್ಲ' : 'No guides published yet',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchContent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contentList.length,
                    itemBuilder: (context, index) {
                      final item = _contentList[index];
                      final title = isKn && item['title_kn'] != null && item['title_kn'].isNotEmpty
                          ? item['title_kn']
                          : item['title'];
                      final desc = isKn && item['description_kn'] != null && item['description_kn'].isNotEmpty
                          ? item['description_kn']
                          : item['description'];
                      final isVideo = item['type'] == 'video';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _launchUrl(item['url'], title, item['type']),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item['youtube_thumbnail'] != null && (item['youtube_thumbnail'] as String).isNotEmpty)
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.network(
                                      item['youtube_thumbnail'],
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                    if (isVideo)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.65),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                      ),
                                  ],
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isVideo ? Icons.play_circle_fill : Icons.article,
                                          color: isVideo ? const Color(0xFFDC2626) : AppTheme.primaryColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isVideo ? (isKn ? 'ವಿಡಿಯೋ ಪಾಠ' : 'Video Tutorial') : (isKn ? 'ಮಾರ್ಗದರ್ಶಿ ಲೇಖನ' : 'Advisory Guide'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isVideo ? const Color(0xFFDC2626) : AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      title ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                    if (desc != null && desc.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        desc,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isKn ? 'ವೀಕ್ಷಿಸಲು ಇಲ್ಲಿ ಸ್ಪರ್ಶಿಸಿ' : 'Tap to open guide',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryColor, size: 16),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
