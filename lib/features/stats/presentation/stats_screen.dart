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
                const FlSpot(0, 580),
                const FlSpot(1, 610),
                const FlSpot(2, 595),
                const FlSpot(3, 640),
                const FlSpot(4, 660),
                const FlSpot(5, 650),
                const FlSpot(6, 680),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Text(
          isKn ? 'ಮಾರುಕಟ್ಟೆ ವರದಿ & ವಿಶ್ಲೇಷಣೆ' : 'Market Trends & Analytics',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breed Selector Chips
            Row(
              children: ['CB', 'BV', 'CB_GOLD'].map((b) {
                final isSelected = _selectedBreed == b;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(b == 'CB' ? 'Cross Breed (CB)' : b == 'BV' ? 'Bivoltine (BV)' : 'CB Gold'),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedBreed = b);
                      _fetchTrendData();
                    },
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Top 3 KPI Metric Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: isKn ? 'ಗರಿಷ್ಠ ದರ' : 'Peak Rate',
                    value: '₹${_highestPrice.toStringAsFixed(0)}',
                    color: AppTheme.accentGreen,
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: isKn ? 'ಕನಿಷ್ಠ ದರ' : 'Lowest Rate',
                    value: '₹${_lowestPrice.toStringAsFixed(0)}',
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: isKn ? 'ಸರಾಸರಿ' : '7-Day Avg',
                    value: '₹${_currentAvg.toStringAsFixed(0)}',
                    color: AppTheme.primaryColor,
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Interactive Trend Chart Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isKn ? '7 ದಿನಗಳ ದರ ಏರಿಳಿತ ವರದಿ' : '7-Day Price Movement Trend',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedBreed,
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    height: 200,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 50,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: const FlTitlesData(
                                show: true,
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _priceSpots,
                                  isCurved: true,
                                  color: AppTheme.accentGreen,
                                  barWidth: 3.5,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.accentGreen.withOpacity(0.12),
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

            // Historical Table Feed
            Text(
              isKn ? 'ಇತ್ತೀಚಿನ ಹರಾಜು ಇತಿಹಾಸ' : 'Recent Auction Logs',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentHistory.length,
              itemBuilder: (context, index) {
                final item = _recentHistory[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MarketLocalizations.getMarketName(context, item['market_name'] ?? 'APMC'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            item['report_date'] ?? '',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${item['avg_price'] ?? '0'}/kg',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.accentGreen),
                          ),
                          Text(
                            '₹${item['min_price']} - ₹${item['max_price']}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}
