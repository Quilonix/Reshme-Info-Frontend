import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenNotifications;

  const AboutScreen({
    super.key,
    required this.onLanguageChange,
    required this.onToggleLanguage,
    required this.onOpenNotifications,
  });

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _quilonixStatus = 'Live & Operational';
  bool _quilonixOnline = true;

  @override
  void initState() {
    super.initState();
    _checkQuilonixLiveStatus();
  }

  Future<void> _checkQuilonixLiveStatus() async {
    try {
      final res = await http.get(Uri.parse('https://quilonix.in')).timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _quilonixOnline = res.statusCode == 200;
          _quilonixStatus = _quilonixOnline ? 'Live & Operational' : 'Official Partner';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quilonixStatus = 'Official Partner';
        });
      }
    }
  }

  Future<void> _openWebUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendSupportEmail() async {
    final uri = Uri.parse('mailto:reshmeinfo@quilonix.in?subject=Reshme%20Info%20Support%20Inquiry');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKn = Localizations.localeOf(context).languageCode == 'kn';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Text(
          isKn ? 'ನಮ್ಮ ಬಗ್ಗೆ & ಸಂಪರ್ಕ' : 'About & Support',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Branding Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/reshme_logo.png',
                    height: 64,
                    errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: AppTheme.primaryColor, size: 56),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isKn ? 'ರೇಷ್ಮೆ ಮಾಹಿತಿ 2.0' : 'Reshme Info 2.0',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isKn
                        ? 'ಕರ್ನಾಟಕದ ರೈತರು ಮತ್ತು ರೀಲರ್‌ಗಳಿಗಾಗಿ ಅಧಿಕೃತ ರೇಷ್ಮೆ ಮಾರುಕಟ್ಟೆ ನೇರ ಹರಾಜು ದರಗಳ ವೇದಿಕೆ'
                        : 'Karnataka Real-Time APMC Silk Cocoon Auction Intelligence Platform',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Free & No Ads Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              isKn ? '100% ಉಚಿತ' : '100% Free',
                              style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.block, color: AppTheme.primaryColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              isKn ? 'ಜಾಹೀರಾತು ರಹಿತ' : 'Zero Ads',
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quilonix Technology Partner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.hub_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'QUILONIX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.accentGreen),
                        ),
                        child: Text(
                          _quilonixStatus,
                          style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 10.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Built with advanced agentic cloud infrastructure and high-throughput real-time streaming engines.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () => _openWebUrl('https://quilonix.in'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.language, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'quilonix.in',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_outward, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Support & Contact Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isKn ? 'ಸಹಾಯ & ಬೆಂಬಲ' : 'Help & Farmer Support',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.email_outlined, color: AppTheme.primaryColor, size: 20),
                    ),
                    title: const Text(
                      'reshmeinfo@quilonix.in',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    subtitle: Text(
                      isKn ? 'ಪ್ರಶ್ನೆಗಳು ಅಥವಾ ಸಲಹೆಗಳಿಗಾಗಿ ನಮಗೆ ಇಮೇಲ್ ಮಾಡಿ' : 'Official support email for farmer inquiries',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    onTap: _sendSupportEmail,
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppTheme.accentGreen, size: 20),
                    ),
                    title: Text(
                      isKn ? 'ಗೌಪ್ಯತಾ ನೀತಿ' : 'Privacy Policy',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => _openWebUrl('https://reshmeinfo.quilonix.in/privacy-policy'),
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_outlined, color: AppTheme.accentAmber, size: 20),
                    ),
                    title: Text(
                      isKn ? 'ನಿಯಮಗಳು ಮತ್ತು ಷರತ್ತುಗಳು' : 'Terms & Conditions',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => _openWebUrl('https://reshmeinfo.quilonix.in/terms'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // App Build Version
            Text(
              'Reshme Info v2.0.0 (Build 20260818)',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
