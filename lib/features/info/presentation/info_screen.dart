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
  String _selectedCategory = 'all';
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

  Future<void> _launchTutorial(String? urlString, String? videoId, String title) async {
    AnalyticsService.logViewGuide(title, videoId != null ? 'video' : 'article');
    String targetUrl = urlString ?? '';
    if (videoId != null && videoId.isNotEmpty) {
      targetUrl = 'https://www.youtube.com/watch?v=$videoId';
    }
    if (targetUrl.isEmpty) return;

    final uri = Uri.parse(targetUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKn = Localizations.localeOf(context).languageCode == 'kn';

    final filteredList = _contentList.where((item) {
      if (_selectedCategory == 'all') return true;
      return item['type'] == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Text(
          isKn ? 'ರೇಷ್ಮೆ ಕೃಷಿ ಮಾಹಿತಿ & ವಿಡಿಯೋ' : 'Sericulture Guides & Videos',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              onTap: widget.onToggleLanguage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.white, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      isKn ? 'English' : 'ಕನ್ನಡ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: widget.onOpenNotifications,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('all', isKn ? 'ಎಲ್ಲ ಮಾಹಿತಿಗಳು' : 'All Tutorials'),
                const SizedBox(width: 8),
                _buildFilterChip('video', isKn ? 'ವಿಡಿಯೋ ಪಾಠಗಳು' : 'Video Lessons'),
                const SizedBox(width: 8),
                _buildFilterChip('basicInfo', isKn ? 'ಕೃಷಿ ಕೈಪಿಡಿ' : 'Handbooks'),
              ],
            ),
          ),

          // Content Feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchContent,
              color: AppTheme.primaryColor,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_outlined, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                isKn ? 'ಯಾವುದೇ ಮಾಹಿತಿಗಳು ಲಭ್ಯವಿಲ್ಲ' : 'No guides found',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final title = isKn ? (item['title_kn'] ?? item['title']) : item['title'];
                            final desc = isKn ? (item['description_kn'] ?? item['description']) : item['description'];
                            final videoId = item['youtube_video_id'];
                            final isVideo = item['type'] == 'video' || (videoId != null && videoId.toString().isNotEmpty);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A).withOpacity(0.025),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Video Thumbnail Banner if Video
                                  if (isVideo && videoId != null)
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(18),
                                            topRight: Radius.circular(18),
                                          ),
                                          child: Image.network(
                                            'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                                            height: 160,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 120,
                                              color: const Color(0xFF0F172A),
                                              child: const Center(
                                                child: Icon(Icons.videocam, color: Colors.white54, size: 40),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDC2626).withOpacity(0.92),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
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
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isVideo ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isVideo ? 'YouTube Video' : 'Advisory Article',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: isVideo ? const Color(0xFFDC2626) : AppTheme.primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          title ?? 'Sericulture Advisory',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (desc != null && desc.toString().isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            desc,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                                          ),
                                        ],
                                        const SizedBox(height: 14),

                                        // Action Button
                                        InkWell(
                                          onTap: () => _launchTutorial(item['url'], videoId, title ?? ''),
                                          child: Row(
                                            children: [
                                              Text(
                                                isVideo
                                                    ? (isKn ? 'ವಿಡಿಯೋ ವೀಕ್ಷಿಸಿ' : 'Watch on YouTube')
                                                    : (isKn ? 'ಸಂಪೂರ್ಣ ಮಾಹಿತಿ ಓದಿ' : 'Read Full Guide'),
                                                style: const TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward, size: 16, color: AppTheme.primaryColor),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = category),
      selectedColor: AppTheme.primaryColor,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
