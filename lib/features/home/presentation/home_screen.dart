import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      // Fetch top latest price updates
      final pricesResponse = await client
          .from('cocoon_prices')
          .select('*')
          .order('report_date', ascending: false)
          .limit(6);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKn = Localizations.localeOf(context).languageCode == 'kn';

    final topPrice = _latestPrices.isNotEmpty ? _latestPrices.first : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'RESHME INFO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isKn ? 'ರೇಷ್ಮೆ ಮಾಹಿತಿ' : 'Silk Portal',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
          // Dedicated Notification Route Icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: widget.onOpenNotifications,
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Banner
              if (_userName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isKn ? 'ನಮಸ್ಕಾರ, $_userName' : 'Welcome, $_userName',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (_preferredMarket.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            MarketLocalization.getLocalizedMarket(_preferredMarket, isKn),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Hero Spotlight Price Card
              if (topPrice != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isKn ? 'ಇಂದಿನ ಪ್ರಮುಖ ಮಾರುಕಟ್ಟೆ ದರ' : 'Latest Market Spotlight',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            topPrice['report_date'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                MarketLocalization.getLocalizedMarket(topPrice['market_name'] ?? 'Karnataka Market', isKn),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${MarketLocalization.getLocalizedBreed(topPrice['breed'] ?? 'CB', isKn)} ಗೂಡು',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${topPrice['avg_price'] ?? topPrice['price_per_kg'] ?? '0'}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                isKn ? 'ಪ್ರತಿ ಕೆ.ಜಿ. ಸರಾಸರಿ' : 'Average per KG',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              '${isKn ? 'ಕನಿಷ್ಠ' : 'Min'}: ₹${topPrice['min_price'] ?? '—'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                            Container(width: 1, height: 16, color: AppTheme.cardBorder),
                            Text(
                              '${isKn ? 'ಗರಿಷ್ಠ' : 'Max'}: ₹${topPrice['max_price'] ?? '—'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Quick Actions Grid (Large tactile buttons)
              Text(
                isKn ? 'ತ್ವರಿತ ಆಯ್ಕೆಗಳು' : 'Quick Actions',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.storefront,
                      title: isKn ? 'ಮಾರುಕಟ್ಟೆ ದರ' : 'All Rates',
                      subtitle: isKn ? 'ಎಲ್ಲ ಮಾರುಕಟ್ಟೆಗಳು' : 'Live Auctions',
                      color: AppTheme.primaryColor,
                      onTap: () => widget.onTabChange(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.show_chart,
                      title: isKn ? 'ದರ ವಿಶ್ಲೇಷಣೆ' : 'Price Stats',
                      subtitle: isKn ? 'ವಾರದ ಗ್ರಾಫ್' : '7-Day Trends',
                      color: const Color(0xFF0D9488),
                      onTap: () => widget.onTabChange(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.menu_book,
                      title: isKn ? 'ಕೃಷಿ ಮಾಹಿತಿ' : 'Guides',
                      subtitle: isKn ? 'ವಿಡಿಯೋ ಪಾಠ' : 'Tutorials',
                      color: const Color(0xFFD97706),
                      onTap: () => widget.onTabChange(3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Market Tickers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isKn ? 'ಇತ್ತೀಚಿನ ಮಾರುಕಟ್ಟೆ ವರದಿಗಳು' : 'Recent Market Updates',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onTabChange(1),
                    child: Text(
                      isKn ? 'ಎಲ್ಲವನ್ನೂ ನೋಡಿ' : 'View All',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_latestPrices.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Center(
                    child: Text(
                      isKn ? 'ಯಾವುದೇ ದರ ದಾಖಲಾಗಿಲ್ಲ' : 'No price records found',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _latestPrices.length,
                  itemBuilder: (context, index) {
                    final item = _latestPrices[index];
                    return _PriceListItem(item: item, isKn: isKn);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceListItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isKn;

  const _PriceListItem({required this.item, required this.isKn});

  @override
  Widget build(BuildContext context) {
    final avg = item['avg_price'] ?? item['price_per_kg'] ?? 0;
    final min = item['min_price'] ?? 0;
    final max = item['max_price'] ?? 0;
    final marketName = item['market_name'] ?? 'Market';
    final breedCode = item['breed'] ?? 'CB';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                MarketLocalization.getLocalizedMarket(marketName, isKn),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      MarketLocalization.getLocalizedBreed(breedCode, isKn),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['report_date'] ?? '',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹$avg',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Min ₹$min - Max ₹$max',
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
