import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/market_localizations.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/version_service.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenNotifications;

  const HomeScreen({
    super.key,
    required this.onTabChange,
    required this.onToggleLanguage,
    required this.onOpenNotifications,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _latestPrices = [];
  List<Map<String, dynamic>> _featuredGuides = [];
  String _userName = '';
  String _preferredMarket = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('HomeScreen');
    _loadUserPreferences();
    _loadHomeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionService.checkForUpdates(context);
    });
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _preferredMarket = prefs.getString('user_preferred_market') ?? '';
    });
  }

  Future<void> _loadHomeData() async {
    try {
      final client = Supabase.instance.client;

      // Fetch latest price updates
      final pricesResponse = await client
          .from('cocoon_prices')
          .select('*')
          .order('report_date', ascending: false)
          .limit(8);

      // Fetch featured guides
      final guidesResponse = await client
          .from('content_items')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .limit(3);

      setState(() {
        _latestPrices = List<Map<String, dynamic>>.from(pricesResponse);
        _featuredGuides = List<Map<String, dynamic>>.from(guidesResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sharePriceOnWhatsApp(Map<String, dynamic> price, bool isKn) async {
    final market = price['market_name'] ?? 'APMC';
    final breed = price['breed'] ?? 'CB';
    final avg = price['avg_price'] ?? '0';
    final min = price['min_price'] ?? '0';
    final max = price['max_price'] ?? '0';
    final date = price['report_date'] ?? '';

    final text = isKn
        ? '*ರೇಷ್ಮೆ ಮಾಹಿತಿ (Reshme Info) ಮಾರುಕಟ್ಟೆ ದರ*\n'
          'ದಿನಾಂಕ: $date\n'
          'ಮಾರುಕಟ್ಟೆ: $market\n'
          'ತಳಿ: $breed\n'
          'ಸರಾಸರಿ ದರ: ₹$avg/ಕೆಜಿ\n'
          'ಕನಿಷ್ಠ: ₹$min | ಗರಿಷ್ಠ: ₹$max\n\n'
          'ಹೆಚ್ಚಿನ ವಿವರಗಳಿಗಾಗಿ Reshme Info ಆ್ಯಪ್ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ.'
        : '*Reshme Info APMC Silk Cocoon Rate*\n'
          'Date: $date\n'
          'Market: $market\n'
          'Breed: $breed\n'
          'Average: ₹$avg/kg\n'
          'Min: ₹$min | Max: ₹$max\n\n'
          'Download Reshme Info App for live rates.';

    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        AnalyticsService.logWhatsAppShare(market, breed);
      } else {
        final webUri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKn = Localizations.localeOf(context).languageCode == 'kn';

    final topPrice = _latestPrices.isNotEmpty ? _latestPrices.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/reshme_logo.png',
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              isKn ? 'ರೇಷ್ಮೆ ಮಾಹಿತಿ' : 'RESHME INFO',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher
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

          // Notification Bell
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: widget.onOpenNotifications,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName.isNotEmpty
                                  ? (isKn ? 'ನಮಸ್ಕಾರ, $_userName' : 'Welcome, $_userName')
                                  : (isKn ? 'ಕರ್ನಾಟಕ ರೇಷ್ಮೆ ಮಾರುಕಟ್ಟೆ' : 'Karnataka Silk Intelligence'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isKn ? 'ಇಂದಿನ ನೇರ ಹರಾಜು ದರಗಳು' : 'Live APMC Auction Rates Today',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isKn ? 'ನೇರ ಹರಾಜು' : 'LIVE APMC',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
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

              // Spotlight Price Card
              if (_isLoading)
                Container(
                  height: 180,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (topPrice != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 18, color: AppTheme.primaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    MarketLocalizations.getMarketName(context, topPrice['market_name'] ?? 'APMC'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  topPrice['breed'] ?? 'CB',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Card Body
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isKn ? 'ಸರಾಸರಿ ದರ (ಪ್ರತಿ ಕೆಜಿ)' : 'Average Rate (Per Kg)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${topPrice['avg_price'] ?? '0'}',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.accentGreen,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        isKn ? 'ದಿನಾಂಕ' : 'Report Date',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        topPrice['report_date'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 12),

                              // Min / Max Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              isKn ? 'ಕನಿಷ್ಠ: ' : 'Min: ',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                            ),
                                            Text(
                                              '₹${topPrice['min_price'] ?? '0'}',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              isKn ? 'ಗರಿಷ್ಠ: ' : 'Max: ',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                            ),
                                            Text(
                                              '₹${topPrice['max_price'] ?? '0'}',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // WhatsApp Button
                                  InkWell(
                                    onTap: () => _sharePriceOnWhatsApp(topPrice, isKn),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF25D366),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.share, color: Colors.white, size: 15),
                                          SizedBox(width: 5),
                                          Text(
                                            'WhatsApp',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Quick Action Navigation Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isKn ? 'ತ್ವರಿತ ಸೇವೆಗಳು' : 'Quick Actions',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.storefront,
                        title: isKn ? 'ಮಾರುಕಟ್ಟೆ ದರ' : 'All Markets',
                        subtitle: isKn ? 'ಎಲ್ಲ APMC ದರಗಳು' : 'Live rates',
                        color: const Color(0xFFEFF6FF),
                        iconColor: AppTheme.primaryColor,
                        onTap: () => widget.onTabChange(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.show_chart,
                        title: isKn ? 'ವಾರದ ವರದಿ' : '7-Day Stats',
                        subtitle: isKn ? 'ದರ ಏರಿಳಿತಗಳು' : 'Weekly trend',
                        color: const Color(0xFFF0FDF4),
                        iconColor: AppTheme.accentGreen,
                        onTap: () => widget.onTabChange(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.menu_book,
                        title: isKn ? 'ರೇಷ್ಮೆ ಮಾಹಿತಿ' : 'Knowledge',
                        subtitle: isKn ? 'ವಿಡಿಯೋ ಮತ್ತು ಮಾಹಿತಿ' : 'Guides & tips',
                        color: const Color(0xFFFFFBEB),
                        iconColor: AppTheme.accentAmber,
                        onTap: () => widget.onTabChange(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.notifications_active,
                        title: isKn ? 'ಸುದ್ದಿ ಮತ್ತು ಪ್ರಕಟಣೆ' : 'Alerts',
                        subtitle: isKn ? 'ತಕ್ಷಣದ ಸೂಚನೆಗಳು' : 'Bulletins',
                        color: const Color(0xFFFAF5FF),
                        iconColor: const Color(0xFF9333EA),
                        onTap: widget.onOpenNotifications,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Rates Feed Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isKn ? 'ಇತ್ತೀಚಿನ ಮಾರುಕಟ್ಟೆ ದರಗಳು' : 'Latest Market Bulletins',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.onTabChange(1),
                      child: Text(
                        isKn ? 'ಎಲ್ಲವನ್ನೂ ವೀಕ್ಷಿಸಿ' : 'View All',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Horizontal Price Tickers
              if (_latestPrices.isNotEmpty)
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _latestPrices.length,
                    itemBuilder: (context, index) {
                      final item = _latestPrices[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    MarketLocalizations.getMarketName(context, item['market_name'] ?? ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['breed'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${item['avg_price'] ?? '0'}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accentGreen),
                                ),
                                Text(
                                  '${item['min_price']} - ₹${item['max_price']}/kg',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              item['report_date'] ?? '',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // Featured Video Guides
              if (_featuredGuides.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isKn ? 'ರೇಷ್ಮೆ ಕೃಷಿ ವಿಡಿಯೋಗಳು' : 'Sericulture Video Guides',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      InkWell(
                        onTap: () => widget.onTabChange(3),
                        child: Text(
                          isKn ? 'ಹೆಚ್ಚಿನ ಮಾಹಿತಿ' : 'Explore',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _featuredGuides.length,
                  itemBuilder: (context, index) {
                    final guide = _featuredGuides[index];
                    final title = isKn ? (guide['title_kn'] ?? guide['title']) : guide['title'];
                    final videoId = guide['youtube_video_id'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.play_arrow, color: Color(0xFFDC2626), size: 28),
                        ),
                        title: Text(
                          title ?? 'Sericulture Tutorial',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        subtitle: Text(
                          isKn ? 'ಉಚಿತ ಕೃಷಿ ಸಲಹೆಗಳು' : 'Free farming advisory',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                        onTap: () async {
                          if (videoId != null && videoId.toString().isNotEmpty) {
                            final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            widget.onTabChange(3);
                          }
                        },
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
