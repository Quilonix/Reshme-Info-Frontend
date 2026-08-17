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
  String _quilonixStatus = 'Connected';
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
          _quilonixStatus = _quilonixOnline ? 'Live & Operational' : 'Online';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);
    final isKn = currentLocale.languageCode == 'kn';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isKn ? 'ಆ್ಯಪ್ ವಿವರ & ಸೆಟ್ಟಿಂಗ್ಸ್' : 'About & Settings'),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Branding Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/reshme_logo.png',
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.grass_rounded, size: 40, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Reshme Info (ರೇಷ್ಮೆ ಮಾಹಿತಿ)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Version 2.0.0 (Production Release)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isKn
                        ? 'ಕರ್ನಾಟಕದ ರೇಷ್ಮೆ ಕೃಷಿಕರು ಮತ್ತು ವ್ಯಾಪಾರಿಗಳಿಗೆ ನೈಜ ಸಮಯದ ಮಾರುಕಟ್ಟೆ ಹರಾಜು ಧಾರಣೆಗಳನ್ನು ಒದಗಿಸುವ ವೇದಿಕೆ.'
                        : 'A dedicated sericulture platform delivering verified, real-time silk cocoon market auction prices across Karnataka APMC markets.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // About Quilonix Card (Fetched & Linked with Quilonix.in)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business_rounded, color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Quilonix',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF16A34A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _quilonixOnline ? 'Live' : _quilonixStatus,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isKn ? 'ತಂತ್ರಜ್ಞಾನ ಮತ್ತು ನಾವೀನ್ಯತೆ ಪಾಲುದಾರರು' : 'Technology & Innovation Partner',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isKn
                        ? 'ಕ್ವಿಲೋನಿಕ್ಸ್ (Quilonix) ಭಾರತದ ಕೃಷಿಕರಿಗೆ ಡಿಜಿಟಲ್ ತಂತ್ರಜ್ಞಾನ ಮತ್ತು ನೈಜ ಸಮಯದ ಮಾರುಕಟ್ಟೆ ಬುದ್ಧಿಮತ್ತೆ ಒದಗಿಸುವ ಪ್ರಮುಖ ಸಾಫ್ಟ್‌ವೇರ್ ಸಂಸ್ಥೆಯಾಗಿದೆ.'
                        : 'Quilonix builds next-generation digital intelligence platforms empowering Indian farmers with real-time APMC data analytics.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => _openWebUrl('https://quilonix.in'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.language, color: AppTheme.primaryColor, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Visit quilonix.in',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Language Selector Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('change_language'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _LanguageTile(
                    title: 'ಕನ್ನಡ (Kannada)',
                    subtitle: 'ಕರ್ನಾಟಕದ ರೈತರಿಗೆ ಶಿಫಾರಸು ಮಾಡಲಾಗಿದೆ',
                    isSelected: currentLocale.languageCode == 'kn',
                    onTap: () {
                      widget.onLanguageChange(const Locale('kn'));
                      AnalyticsService.logLanguageChange('kn');
                    },
                  ),
                  const SizedBox(height: 8),
                  _LanguageTile(
                    title: 'English',
                    subtitle: 'English language interface',
                    isSelected: currentLocale.languageCode == 'en',
                    onTap: () {
                      widget.onLanguageChange(const Locale('en'));
                      AnalyticsService.logLanguageChange('en');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Legal & Info Links
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: Column(
                children: [
                  _LinkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: isKn ? 'ಗೌಪ್ಯತಾ ನೀತಿ (Privacy Policy)' : 'Privacy Policy',
                    onTap: () => _openWebUrl('https://reshmeinfo.com/privacy-policy'),
                  ),
                  const Divider(height: 1, color: AppTheme.cardBorder),
                  _LinkTile(
                    icon: Icons.description_outlined,
                    title: isKn ? 'ಬಳಕೆಯ ನಿಯಮಗಳು (Terms of Service)' : 'Terms of Service',
                    onTap: () => _openWebUrl('https://reshmeinfo.com/terms'),
                  ),
                  const Divider(height: 1, color: AppTheme.cardBorder),
                  _LinkTile(
                    icon: Icons.contact_support_outlined,
                    title: isKn ? 'ಬೆಂಬಲ ಮತ್ತು ಸಂಪರ್ಕ (Help & Support)' : 'Help & Support',
                    onTap: () => _openWebUrl('mailto:reshmeinfo@quilonix.in'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }
}
