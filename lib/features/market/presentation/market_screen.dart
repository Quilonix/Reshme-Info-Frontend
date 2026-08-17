import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/market_localizations.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/theme/app_theme.dart';

class MarketScreen extends StatefulWidget {
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenNotifications;

  const MarketScreen({
    super.key,
    required this.onToggleLanguage,
    required this.onOpenNotifications,
  });

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<Map<String, dynamic>> _prices = [];
  List<String> _markets = ['All'];
  List<Map<String, dynamic>> _breeds = [
    {'code': 'All', 'name': 'All Breeds', 'name_kn': 'ಎಲ್ಲ ತಳಿಗಳು'}
  ];
  String _selectedMarket = 'All';
  String _selectedBreed = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('MarketPricesScreen');
    _fetchMarketsAndPrices();
  }

  Future<void> _fetchMarketsAndPrices({bool forceRefresh = false}) async {
    final cacheKey = 'prices_${_selectedMarket}_${_selectedBreed}';

    if (!forceRefresh) {
      final cachedPrices = await CacheService.get<List<dynamic>>(key: cacheKey);
      final cachedMarkets = await CacheService.get<List<dynamic>>(key: 'markets_list');
      final cachedBreeds = await CacheService.get<List<dynamic>>(key: 'breeds_list');

      if (cachedPrices != null) {
        setState(() {
          if (cachedMarkets != null) _markets = List<String>.from(cachedMarkets);
          if (cachedBreeds != null) _breeds = List<Map<String, dynamic>>.from(cachedBreeds);
          _prices = List<Map<String, dynamic>>.from(cachedPrices);
          _isLoading = false;
        });
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;

      // Fetch active markets
      final List<dynamic> marketsData = await client
          .from('markets')
          .select('name')
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      final List<String> marketNames = [
        'All',
        ...marketsData.map((m) => m['name'] as String)
      ];

      // Fetch breeds
      final List<dynamic> breedsData = await client
          .from('breeds')
          .select('*')
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> dynamicBreeds = [
        {'code': 'All', 'name': 'All Breeds', 'name_kn': 'ಎಲ್ಲ ತಳಿಗಳು'},
        ...breedsData.map((b) => Map<String, dynamic>.from(b))
      ];

      // Query cocoon prices
      var query = client.from('cocoon_prices').select('*');
      if (_selectedMarket != 'All') {
        query = query.eq('market_name', _selectedMarket);
      }
      if (_selectedBreed != 'All') {
        query = query.eq('breed', _selectedBreed);
      }

      final List<dynamic> pricesData =
          await query.order('report_date', ascending: false).limit(50);

      // Cache results
      await CacheService.set(key: cacheKey, data: pricesData);
      await CacheService.set(key: 'markets_list', data: marketNames);
      await CacheService.set(key: 'breeds_list', data: dynamicBreeds);

      setState(() {
        _markets = marketNames;
        _breeds = dynamicBreeds;
        _prices = List<Map<String, dynamic>>.from(pricesData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sharePrice(Map<String, dynamic> item, bool isKn) async {
    final rawMarket = item['market_name'] ?? 'Market';
    final market = MarketLocalization.getLocalizedMarket(rawMarket, isKn);
    final breed = MarketLocalization.getLocalizedBreed(item['breed'] ?? 'CB', isKn);
    final avg = item['avg_price'] ?? item['price_per_kg'] ?? 0;
    final min = item['min_price'] ?? 0;
    final max = item['max_price'] ?? 0;
    final date = item['report_date'] ?? '';

    final text = isKn
        ? '$market ರೇಷ್ಮೆ ಮಾರುಕಟ್ಟೆ ದರ ($date)\nತಳಿ: $breed\nಸರಾಸರಿ: ₹$avg/kg\nಕನಿಷ್ಠ: ₹$min | ಗರಿಷ್ಠ: ₹$max\n\nರೇಷ್ಮೆ ಮಾಹಿತಿ ಆ್ಯಪ್ ಮೂಲಕ ಹಂಚಿಕೊಳ್ಳಲಾಗಿದೆ.'
        : '$market Silk Cocoon Price ($date)\nBreed: $breed\nAvg: Rs $avg/kg\nMin: Rs $min | Max: Rs $max\n\nShared via Reshme Info App.';

    final encoded = Uri.encodeComponent(text);
    final whatsappUrl = Uri.parse('whatsapp://send?text=$encoded');
    final webUrl = Uri.parse('https://api.whatsapp.com/send?text=$encoded');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKn = Localizations.localeOf(context).languageCode == 'kn';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isKn ? 'ಮಾರುಕಟ್ಟೆ ದರಗಳು' : 'Market Rates'),
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
            onPressed: () => _fetchMarketsAndPrices(forceRefresh: true),
            tooltip: 'Refresh prices',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Horizontal Market Selector Chips with Kannada Translation
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: _markets.map((market) {
                  final isSelected = _selectedMarket == market;
                  final displayName = MarketLocalization.getLocalizedMarket(market, isKn);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: const Color(0xFFF1F5F9),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedMarket = market);
                          AnalyticsService.logSelectMarket(market);
                          _fetchMarketsAndPrices();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 2. Breed Filter Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
            child: Row(
              children: _breeds.map((breed) {
                final isSelected = _selectedBreed == breed['code'];
                final label = MarketLocalization.getLocalizedBreed(breed['code'], isKn);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedBreed = breed['code']);
                        AnalyticsService.logSelectBreed(breed['code']);
                        _fetchMarketsAndPrices();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1, color: AppTheme.cardBorder),

          // 3. Price Cards List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _prices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              isKn ? 'ಯಾವುದೇ ದರ ದಾಖಲಾಗಿಲ್ಲ' : 'No price records found for this filter',
                              style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _fetchMarketsAndPrices(forceRefresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: _prices.length,
                          itemBuilder: (context, index) {
                            final item = _prices[index];
                            return _ModernPriceCard(
                              item: item,
                              isKn: isKn,
                              onShare: () => _sharePrice(item, isKn),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ModernPriceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isKn;
  final VoidCallback onShare;

  const _ModernPriceCard({
    required this.item,
    required this.isKn,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final avg = item['avg_price'] ?? item['price_per_kg'] ?? 0;
    final min = item['min_price'] ?? 0;
    final max = item['max_price'] ?? 0;
    final lots = item['lot_number'];
    final weight = item['total_weight'];
    final breedCode = item['breed'] ?? 'CB';
    final marketName = item['market_name'] ?? 'Market';

    final localizedMarket = MarketLocalization.getLocalizedMarket(marketName, isKn);
    final localizedBreed = MarketLocalization.getLocalizedBreed(breedCode, isKn);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Localized Market Name, Breed Badge, Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      localizedMarket,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: breedCode == 'BV' ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: breedCode == 'BV' ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Text(
                        localizedBreed,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: breedCode == 'BV' ? const Color(0xFFB45309) : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  item['report_date'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Middle Row: Average Price Spotlight
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKn ? 'ಸರಾಸರಿ ಧಾರಣೆ' : 'Average Price',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹$avg',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ kg',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Share Button (Large Tactile touch target)
                InkWell(
                  onTap: onShare,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share, color: Color(0xFF16A34A), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom Metric Blocks: Min, Max, Lots, Weight
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricColumn(label: isKn ? 'ಕನಿಷ್ಠ' : 'Min', value: '₹$min', color: const Color(0xFF475569)),
                  Container(width: 1, height: 20, color: AppTheme.cardBorder),
                  _MetricColumn(label: isKn ? 'ಗರಿಷ್ಠ' : 'Max', value: '₹$max', color: const Color(0xFF166534)),
                  if (lots != null) ...[
                    Container(width: 1, height: 20, color: AppTheme.cardBorder),
                    _MetricColumn(label: isKn ? 'ಲಾಟ್‌ಗಳು' : 'Lots', value: '$lots', color: AppTheme.primaryColor),
                  ],
                  if (weight != null) ...[
                    Container(width: 1, height: 20, color: AppTheme.cardBorder),
                    _MetricColumn(label: isKn ? 'ತೂಕ' : 'Qty', value: '${weight}kg', color: const Color(0xFF0D9488)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}
