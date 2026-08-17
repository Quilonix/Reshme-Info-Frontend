import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/market_localizations.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenNotifications;

  const StatsScreen({
    super.key,
    required this.onToggleLanguage,
    required this.onOpenNotifications,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<FlSpot> _priceSpots = [];
  List<Map<String, dynamic>> _recentHistory = [];
  double _highestPrice = 0;
  double _lowestPrice = 0;
  double _currentAvg = 0;
  bool _isLoading = true;
  String _selectedBreed = 'CB';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('StatsScreen');
    _fetchTrendData();
  }

  Future<void> _fetchTrendData() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('cocoon_prices')
          .select('*')
          .eq('breed', _selectedBreed)
          .order('report_date', ascending: true)
          .limit(10);

      final List<FlSpot> spots = [];
      double high = 0;
      double low = 99999;
      double sum = 0;

      for (int i = 0; i < response.length; i++) {
        final price = (response[i]['avg_price'] as num).toDouble();
        spots.add(FlSpot(i.toDouble(), price));
        if (price > high) high = price;
        if (price < low) low = price;
        sum += price;
      }

      setState(() {
        _recentHistory = List<Map<String, dynamic>>.from(response.reversed);
        _highestPrice = high > 0 ? high : 780;
        _lowestPrice = low < 99999 ? low : 480;
        _currentAvg = spots.isNotEmpty ? (sum / spots.length) : 630;
        _priceSpots = spots.isNotEmpty
            ? spots
            : [
                const FlSpot(0, 520),
                const FlSpot(1, 580),
                const FlSpot(2, 610),
                const FlSpot(3, 590),
                const FlSpot(4, 650),
                const FlSpot(5, 680),
              ];
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
        title: Text(isKn ? 'ದರ ವಿಶ್ಲೇಷಣೆ & ಗ್ರಾಫ್' : 'Price Trends & Analytics'),
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
            onPressed: _fetchTrendData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breed Toggle Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _BreedToggleButton(
                      title: MarketLocalization.getLocalizedBreed('CB', isKn),
                      subtitle: isKn ? 'ಹೈಬ್ರಿಡ್ ಗೂಡು' : 'Hybrid',
                      isSelected: _selectedBreed == 'CB',
                      onTap: () {
                        setState(() => _selectedBreed = 'CB');
                        _fetchTrendData();
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _BreedToggleButton(
                      title: MarketLocalization.getLocalizedBreed('BV', isKn),
                      subtitle: isKn ? 'ಬಿಳಿ ಗೂಡು' : 'Bivoltine',
                      isSelected: _selectedBreed == 'BV',
                      onTap: () {
                        setState(() => _selectedBreed = 'BV');
                        _fetchTrendData();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Key Metrics Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryBox(
                    label: isKn ? 'ವಾರದ ಗರಿಷ್ಠ' : 'Weekly High',
                    value: '₹${_highestPrice.toInt()}',
                    color: const Color(0xFF16A34A),
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryBox(
                    label: isKn ? 'ವಾರದ ಕನಿಷ್ಠ' : 'Weekly Low',
                    value: '₹${_lowestPrice.toInt()}',
                    color: const Color(0xFFDC2626),
                    icon: Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryBox(
                    label: isKn ? 'ಸರಾಸರಿ ದರ' : 'Avg Rate',
                    value: '₹${_currentAvg.toInt()}',
                    color: AppTheme.primaryColor,
                    icon: Icons.show_chart,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Price Trend Chart Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isKn ? '10 ದಿನಗಳ ದರ ಏರಿಳಿತ' : '10-Day Price Movement',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${MarketLocalization.getLocalizedBreed(_selectedBreed, isKn)} (₹/kg)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 100,
                                getDrawingHorizontalLine: (value) => const FlLine(
                                  color: Color(0xFFF1F5F9),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: const FlTitlesData(
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _priceSpots,
                                  isCurved: true,
                                  color: AppTheme.primaryColor,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.primaryColor.withOpacity(0.08),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recent Price History
            Text(
              isKn ? 'ಇತ್ತೀಚಿನ ಹರಾಜು ಇತಿಹಾಸ' : 'Recent Auction History',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            if (_recentHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Center(
                  child: Text(
                    isKn ? 'ದಾಖಲೆಗಳು ಲಭ್ಯವಿಲ್ಲ' : 'No history records',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentHistory.length,
                itemBuilder: (context, index) {
                  final item = _recentHistory[index];
                  final avg = item['avg_price'] ?? item['price_per_kg'] ?? 0;
                  final rawMarket = item['market_name'] ?? 'Market';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              MarketLocalization.getLocalizedMarket(rawMarket, isKn),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                            Text(
                              item['report_date'] ?? '',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        Text(
                          '₹$avg/kg',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _BreedToggleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _BreedToggleButton({
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white.withOpacity(0.85) : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}
