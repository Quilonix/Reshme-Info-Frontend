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
  List<Map<String, dynamic>> _datePrices = [];
  List<Map<String, dynamic>> _featuredGuides = [];
  String _userName = '';
  String _preferredMarket = '';
  late String _selectedDate; // Default locked to today: YYYY-MM-DD
  bool _isLoading = true;
  bool _isTodayEmpty = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('HomeScreen');
    _selectedDate = _formatDate(DateTime.now());
    _loadUserPreferences();
    _loadDataForDate(_selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionService.checkForUpdates(context);
    });
  }

  String _formatDate(DateTime dt) {
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _preferredMarket = prefs.getString('user_preferred_market') ?? '';
    });
  }

  Future<void> _loadDataForDate(String targetDate) async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;

      // 1. Fetch prices for the locked/selected date
      final pricesResponse = await client
          .from('cocoon_prices')
          .select('*')
          .eq('report_date', targetDate)
          .order('avg_price', ascending: false);

      List<Map<String, dynamic>> prices = List<Map<String, dynamic>>.from(pricesResponse);
      bool todayEmpty = false;

      // If today is selected but no prices uploaded yet, fetch latest available date as fallback preview
      if (prices.isEmpty && targetDate == _formatDate(DateTime.now())) {
        todayEmpty = true;
        final fallbackResponse = await client
            .from('cocoon_prices')
            .select('*')
            .order('report_date', ascending: false)
            .limit(10);
        prices = List<Map<String, dynamic>>.from(fallbackResponse);
      }

      // 2. Fetch featured guides
      final guidesResponse = await client
          .from('content_items')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .limit(3);

      setState(() {
        _datePrices = prices;
        _featuredGuides = List<Map<String, dynamic>>.from(guidesResponse);
        _isTodayEmpty = todayEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onDateSelected(String date) {
    setState(() {
      _selectedDate = date;
    });
    _loadDataForDate(date);
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_selectedDate) ?? now,
      firstDate: DateTime(2024, 1, 1),
      lastDate: now, // Locked: Cannot pick future dates
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
      _onDateSelected(_formatDate(picked));
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
        ? '*ರೇಷ್ಮೆ ಮಾಹಿತಿ (Reshme Info) ಮಾರುಕಟ್ಟೆ ಹರಾಜು ದರ*\n'
          'ದಿನಾಂಕ: $date\n'
          'ಮಾರುಕಟ್ಟೆ: $market\n'
          'ತಳಿ: $breed\n'
          'ಸರಾಸರಿ ದರ: ₹$avg/ಕೆಜಿ\n'
          'ಕನಿಷ್ಠ: ₹$min | ಗರಿಷ್ಠ: ₹$max\n\n'
          'ದೈನಂದಿನ ಅಧಿಕೃತ ರೇಷ್ಮೆ ದರಗಳಿಗಾಗಿ Reshme Info ಆ್ಯಪ್ ಬಳಸಿ.'
        : '*Reshme Info APMC Silk Cocoon Rate*\n'
          'Date: $date\n'
          'Market: $market\n'
          'Breed: $breed\n'
          'Average: ₹$avg/kg\n'
          'Min: ₹$min | Max: ₹$max\n\n'
          'Download Reshme Info App for live market rates.';

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
    final isKn = Localizations.localeOf(context).languageCode == 'kn';

    final todayStr = _formatDate(DateTime.now());
    final yesterdayStr = _formatDate(DateTime.now().subtract(const Duration(days: 1)));
    final dayBeforeStr = _formatDate(DateTime.now().subtract(const Duration(days: 2)));

    // Highlight preferred market if exists, else first price
    final heroPrice = _datePrices.firstWhere(
      (p) => _preferredMarket.isNotEmpty && (p['market_name'] ?? '').toString().toLowerCase() == _preferredMarket.toLowerCase(),
      orElse: () => _datePrices.isNotEmpty ? _datePrices.first : {},
    );

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
          // Language Switcher Pill
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
      body: RefreshIndicator(
        onRefresh: () => _loadDataForDate(_selectedDate),
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Locked Date Navigation Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                    // Farmer Greeting
                    Text(
                      _userName.isNotEmpty
                          ? (isKn ? 'ನಮಸ್ಕಾರ, $_userName' : 'Welcome, $_userName')
                          : (isKn ? 'ದೈನಂದಿನ ಹರಾಜು ದರಗಳು' : 'Daily Auction Intelligence'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Date Selection Chips Bar (Today, Yesterday, Day Before, Custom Picker)
                    Row(
                      children: [
                        // Today (Locked Default)
                        _buildDateChip(
                          label: isKn ? 'ಇಂದು' : 'Today',
                          isSelected: _selectedDate == todayStr,
                          onTap: () => _onDateSelected(todayStr),
                        ),
                        const SizedBox(width: 6),

                        // Yesterday
                        _buildDateChip(
                          label: isKn ? 'ನಿನ್ನೆ' : 'Yesterday',
                          isSelected: _selectedDate == yesterdayStr,
                          onTap: () => _onDateSelected(yesterdayStr),
                        ),
                        const SizedBox(width: 6),

                        // Day Before
                        _buildDateChip(
                          label: isKn ? 'ಮೊನ್ನೆ' : 'Day Before',
                          isSelected: _selectedDate == dayBeforeStr,
                          onTap: () => _onDateSelected(dayBeforeStr),
                        ),
                        const SizedBox(width: 6),

                        // Calendar Picker Button
                        InkWell(
                          onTap: _pickCustomDate,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: (_selectedDate != todayStr && _selectedDate != yesterdayStr && _selectedDate != dayBeforeStr)
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (_selectedDate != todayStr && _selectedDate != yesterdayStr && _selectedDate != dayBeforeStr)
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 14,
                                  color: (_selectedDate != todayStr && _selectedDate != yesterdayStr && _selectedDate != dayBeforeStr)
                                      ? AppTheme.primaryColor
                                      : Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (_selectedDate != todayStr && _selectedDate != yesterdayStr && _selectedDate != dayBeforeStr)
                                      ? _selectedDate
                                      : (isKn ? 'ದಿನಾಂಕ' : 'Pick Date'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: (_selectedDate != todayStr && _selectedDate != yesterdayStr && _selectedDate != dayBeforeStr)
                                        ? AppTheme.primaryColor
                                        : Colors.white,
                                  ),
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

              const SizedBox(height: 14),

              // Today's Auction Status Notice if Today not yet finalized
              if (_selectedDate == todayStr && _isTodayEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Color(0xFFB45309)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isKn
                              ? 'ಇಂದಿನ ಹರಾಜು ನಡೆಯುತ್ತಿದೆ. ಹಿಂದಿನ ದಿನದ ದರಗಳನ್ನು ತೋರಿಸಲಾಗುತ್ತಿದೆ.'
                              : 'Today’s auction in progress. Showing latest closing rates.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // Spotlight Hero Price Card for Selected Date
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
              else if (heroPrice.isNotEmpty)
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
                        // Card Header with Market Pin & Breed
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    MarketLocalizations.getMarketName(context, heroPrice['market_name'] ?? 'APMC'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
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
                                  heroPrice['breed'] ?? 'CB',
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

                        // Main Rate Body
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
                                        '₹${heroPrice['avg_price'] ?? '0'}',
                                        style: const TextStyle(
                                          fontSize: 34,
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
                                        heroPrice['report_date'] ?? _selectedDate,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
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

                              // Min / Max & WhatsApp Row
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
                                              '₹${heroPrice['min_price'] ?? '0'}',
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
                                              '₹${heroPrice['max_price'] ?? '0'}',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // WhatsApp 1-tap share
                                  InkWell(
                                    onTap: () => _sharePriceOnWhatsApp(heroPrice, isKn),
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

              const SizedBox(height: 18),

              // Quick Action Tiles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.storefront,
                        title: isKn ? 'ಎಲ್ಲ ಮಾರುಕಟ್ಟೆಗಳು' : 'All Markets',
                        color: const Color(0xFFEFF6FF),
                        iconColor: AppTheme.primaryColor,
                        onTap: () => widget.onTabChange(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.show_chart,
                        title: isKn ? 'ವಾರದ ವರದಿ' : '7-Day Stats',
                        color: const Color(0xFFF0FDF4),
                        iconColor: AppTheme.accentGreen,
                        onTap: () => widget.onTabChange(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.menu_book,
                        title: isKn ? 'ರೇಷ್ಮೆ ಮಾಹಿತಿ' : 'Knowledge',
                        color: const Color(0xFFFFFBEB),
                        iconColor: AppTheme.accentAmber,
                        onTap: () => widget.onTabChange(3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Rates for Selected Date Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isKn ? 'ದಿನಾಂಕದ ಮಾರುಕಟ್ಟೆ ದರಗಳು' : 'APMC Rates for Selected Date',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.onTabChange(1),
                      child: Text(
                        isKn ? 'ವಿವರಗಳು' : 'View Full List',
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

              // Price List for Selected Date
              if (_datePrices.isEmpty && !_isLoading)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          isKn ? 'ಈ ದಿನಾಂಕಕ್ಕೆ ಯಾವುದೇ ದರಗಳು ಲಭ್ಯವಿಲ್ಲ' : 'No auction records for this date',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _datePrices.length,
                  itemBuilder: (context, index) {
                    final item = _datePrices[index];
                    return _buildPriceRowCard(item, isKn);
                  },
                ),

              const SizedBox(height: 20),

              // Featured Video Tutorials
              if (_featuredGuides.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    isKn ? 'ರೇಷ್ಮೆ ಕೃಷಿ ವಿಡಿಯೋ ಮಾರ್ಗದರ್ಶಿ' : 'Sericulture Video Tutorials',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
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
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.play_arrow, color: Color(0xFFDC2626), size: 26),
                        ),
                        title: Text(
                          title ?? 'Sericulture Tutorial',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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

  Widget _buildDateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? AppTheme.primaryColor : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRowCard(Map<String, dynamic> item, bool isKn) {
    final market = item['market_name'] ?? 'APMC';
    final breed = item['breed'] ?? 'CB';
    final avg = item['avg_price'] ?? '0';
    final min = item['min_price'] ?? '0';
    final max = item['max_price'] ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, size: 18, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MarketLocalizations.getMarketName(context, market),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          breed,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹$min - ₹$max',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Average Rate & WhatsApp Button
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$avg',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.accentGreen),
                  ),
                  Text(
                    isKn ? 'ಪ್ರತಿ ಕೆಜಿ' : 'per kg',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _sharePriceOnWhatsApp(item, isKn),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
