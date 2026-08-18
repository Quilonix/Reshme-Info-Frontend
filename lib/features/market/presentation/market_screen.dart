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
  String? _selectedDate; // Format: YYYY-MM-DD
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('MarketPricesScreen');
    _fetchMarketsAndPrices();
  }

  String _formatDate(DateTime dt) {
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _fetchMarketsAndPrices({bool forceRefresh = false}) async {
    final dateKey = _selectedDate ?? 'all';
    final cacheKey = 'prices_${_selectedMarket}_${_selectedBreed}_$dateKey';

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

      // Query cocoon prices with optional date filter
      var query = client.from('cocoon_prices').select('*');
      if (_selectedMarket != 'All') {
        query = query.eq('market_name', _selectedMarket);
      }
      if (_selectedBreed != 'All') {
        query = query.eq('breed', _selectedBreed);
      }
      if (_selectedDate != null && _selectedDate!.isNotEmpty) {
        query = query.eq('report_date', _selectedDate!);
      }

      final List<dynamic> pricesData =
          await query.order('report_date', ascending: false).limit(100);

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

  void _onMarketChanged(String market) {
    setState(() {
      _selectedMarket = market;
      _isLoading = true;
    });
    AnalyticsService.logMarketFilter(market);
    _fetchMarketsAndPrices(forceRefresh: true);
  }

  void _onBreedChanged(String breed) {
    setState(() {
      _selectedBreed = breed;
      _isLoading = true;
    });
    AnalyticsService.logBreedFilter(breed);
    _fetchMarketsAndPrices(forceRefresh: true);
  }

  void _onDateChanged(String? date) {
    setState(() {
      _selectedDate = date;
      _isLoading = true;
    });
    _fetchMarketsAndPrices(forceRefresh: true);
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null ? DateTime.tryParse(_selectedDate!) ?? now : now,
      firstDate: DateTime(2024, 1, 1),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _onDateChanged(_formatDate(picked));
    }
  }

  Future<void> _sharePriceOnWhatsApp(Map<String, dynamic> price, bool isKn) async {
    final market = price['market_name'] ?? 'APMC';
    final breed = price['breed'] ?? 'CB';
    final avg = price['avg_price'] ?? '0';
    final min = price['min_price'] ?? '0';
    final max = price['max_price'] ?? '0';
    final date = price['report_date'] ?? '';
    final lots = price['lot_number'] != null ? '${price['lot_number']} ಲಾಟ್‌ಗಳು' : '';

    final text = isKn
        ? '*ರೇಷ್ಮೆ ಮಾಹಿತಿ (Reshme Info) ಮಾರುಕಟ್ಟೆ ಹರಾಜು ದರ*\n'
          'ದಿನಾಂಕ: $date\n'
          'ಮಾರುಕಟ್ಟೆ: $market\n'
          'ತಳಿ: $breed\n'
          'ಸರಾಸರಿ ದರ: ₹$avg/ಕೆಜಿ\n'
          'ಕನಿಷ್ಠ: ₹$min | ಗರಿಷ್ಠ: ₹$max\n'
          '$lots\n\n'
          'ದೈನಂದಿನ ನೇರ ಮಾರುಕಟ್ಟೆ ದರಗಳಿಗಾಗಿ Reshme Info ಆ್ಯಪ್ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ.'
        : '*Reshme Info APMC Silk Cocoon Auction Rate*\n'
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

    final todayStr = _formatDate(DateTime.now());
    final yesterdayStr = _formatDate(DateTime.now().subtract(const Duration(days: 1)));

    final filteredPrices = _prices.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final market = (p['market_name'] ?? '').toLowerCase();
      final breed = (p['breed'] ?? '').toLowerCase();
      return market.contains(q) || breed.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Text(
          isKn ? 'ಮಾರುಕಟ್ಟೆ ಹರಾಜು ದರಗಳು' : 'APMC Auction Rates',
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
          // Filter & Search Controls Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Date Selector Bar
                Row(
                  children: [
                    // All Dates
                    _buildDateChip(
                      label: isKn ? 'ಎಲ್ಲ ದಿನಾಂಕ' : 'All Dates',
                      isSelected: _selectedDate == null,
                      onTap: () => _onDateChanged(null),
                    ),
                    const SizedBox(width: 6),
                    // Today
                    _buildDateChip(
                      label: isKn ? 'ಇಂದು' : 'Today',
                      isSelected: _selectedDate == todayStr,
                      onTap: () => _onDateChanged(todayStr),
                    ),
                    const SizedBox(width: 6),
                    // Yesterday
                    _buildDateChip(
                      label: isKn ? 'ನಿನ್ನೆ' : 'Yesterday',
                      isSelected: _selectedDate == yesterdayStr,
                      onTap: () => _onDateChanged(yesterdayStr),
                    ),
                    const SizedBox(width: 6),
                    // Calendar Picker Button
                    InkWell(
                      onTap: _pickCustomDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: (_selectedDate != null && _selectedDate != todayStr && _selectedDate != yesterdayStr)
                              ? AppTheme.primaryColor
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (_selectedDate != null && _selectedDate != todayStr && _selectedDate != yesterdayStr)
                                ? AppTheme.primaryColor
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 14,
                              color: (_selectedDate != null && _selectedDate != todayStr && _selectedDate != yesterdayStr)
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (_selectedDate != null && _selectedDate != todayStr && _selectedDate != yesterdayStr)
                                  ? _selectedDate!
                                  : (isKn ? 'ಕ್ಯಾಲೆಂಡರ್' : 'Pick Date'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: (_selectedDate != null && _selectedDate != todayStr && _selectedDate != yesterdayStr)
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Search Input Box
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: isKn ? 'ಮಾರುಕಟ್ಟೆ ಅಥವಾ ತಳಿ ಹುಡುಕಿ...' : 'Search APMC or breed...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Market Chips Bar
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _markets.length,
                    itemBuilder: (context, index) {
                      final market = _markets[index];
                      final isSelected = _selectedMarket == market;
                      final label = MarketLocalizations.getMarketName(context, market);

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => _onMarketChanged(market),
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: const Color(0xFFF8FAFC),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 6),

                // Breed Chips Bar
                SizedBox(
                  height: 30,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _breeds.length,
                    itemBuilder: (context, index) {
                      final breedItem = _breeds[index];
                      final code = breedItem['code'] ?? '';
                      final isSelected = _selectedBreed == code;
                      final name = isKn ? (breedItem['name_kn'] ?? code) : (breedItem['name'] ?? code);

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(name),
                          selected: isSelected,
                          onSelected: (_) => _onBreedChanged(code),
                          selectedColor: const Color(0xFFEFF6FF),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Active Filter Indicator Bar
          if (_selectedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFEFF6FF),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        isKn ? 'ಆಯ್ಕೆಮಾಡಿದ ದಿನಾಂಕ: $_selectedDate' : 'Filtered by Date: $_selectedDate',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _onDateChanged(null),
                    child: Text(
                      isKn ? 'ರದ್ದುಮಾಡಿ' : 'Clear',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),

          // Price Cards Feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchMarketsAndPrices(forceRefresh: true),
              color: AppTheme.primaryColor,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredPrices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                isKn ? 'ಯಾವುದೇ ದರಗಳು ಲಭ್ಯವಿಲ್ಲ' : 'No price records found',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isKn ? 'ಬೇರೆ ದಿನಾಂಕ, ಮಾರುಕಟ್ಟೆ ಅಥವಾ ತಳಿ ಆಯ್ಕೆಮಾಡಿ' : 'Try selecting another date or market',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: filteredPrices.length,
                          itemBuilder: (context, index) {
                            final price = filteredPrices[index];
                            return _buildPriceCard(price, isKn);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> price, bool isKn) {
    final market = price['market_name'] ?? 'APMC';
    final breed = price['breed'] ?? 'CB';
    final avg = price['avg_price'] ?? '0';
    final min = price['min_price'] ?? '0';
    final max = price['max_price'] ?? '0';
    final date = price['report_date'] ?? '';
    final lots = price['lot_number'];
    final quality = price['quality'] ?? 'A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Top Row: Market Name, Breed Badge, Quality Tag
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront, color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      MarketLocalizations.getMarketName(context, market),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        breed,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Grade $quality',
                        style: const TextStyle(
                          color: AppTheme.accentGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Main Price & Stats Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Average Price Big Display
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKn ? 'ಸರಾಸರಿ ದರ' : 'Average Rate',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '₹$avg',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      isKn ? 'ಪ್ರತಿ ಕೆಜಿಗೆ' : 'per kg',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                // Min - Max Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isKn ? 'ಕನಿಷ್ಠ: ' : 'Min: ',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          Text(
                            '₹$min',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isKn ? 'ಗರಿಷ್ಠ: ' : 'Max: ',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          Text(
                            '₹$max',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.accentAmber),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar: Lots info, Date & WhatsApp Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                    ),
                    if (lots != null) ...[
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.grey.shade400)),
                      const SizedBox(width: 8),
                      Text(
                        isKn ? '$lots ಲಾಟ್‌ಗಳು' : '$lots lots',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),

                // WhatsApp 1-tap share
                InkWell(
                  onTap: () => _sharePriceOnWhatsApp(price, isKn),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.share, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'WhatsApp',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
