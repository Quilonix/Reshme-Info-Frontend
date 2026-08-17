import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('NotificationsFeedScreen');
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(30);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKn = Localizations.localeOf(context).languageCode == 'kn';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isKn ? 'ಸೂಚನೆಗಳು & ಮಾರುಕಟ್ಟೆ ಎಚ್ಚರಿಕೆಗಳು' : 'Notifications & Market Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off_outlined, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        isKn ? 'ಯಾವುದೇ ಹೊಸ ಸೂಚನೆಗಳಿಲ್ಲ' : 'No active notifications at this time',
                        style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final isHighPriority = item['priority'] == 'high';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isHighPriority ? const Color(0xFFFCA5A5) : AppTheme.cardBorder,
                            width: isHighPriority ? 1.5 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isHighPriority ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isHighPriority ? Icons.priority_high_rounded : Icons.notifications_active_outlined,
                                    color: isHighPriority ? const Color(0xFFDC2626) : AppTheme.primaryColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['created_at'] != null ? item['created_at'].toString().split('T')[0] : '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['message'] ?? '',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            if (item['image_url'] != null && (item['image_url'] as String).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item['image_url'],
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
