import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/deck_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'day';
  Map<String, int> _stats = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final stats = await context.read<DeckProvider>().getStatistics(_selectedPeriod);
      setState(() {
        _stats = stats;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê học tập'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Period Selector
            Center(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'day', label: Text('Ngày')),
                  ButtonSegment(value: 'week', label: Text('Tuần')),
                  ButtonSegment(value: 'month', label: Text('Tháng')),
                  ButtonSegment(value: 'year', label: Text('Năm')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedPeriod = newSelection.first;
                    _loadStats();
                  });
                },
              ),
            ),
            const SizedBox(height: 32),

            // Chart Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biểu đồ từ mới đã thuộc',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Theo ${_selectedText(_selectedPeriod)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 250,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Cần cấu hình Index trên Firebase Console',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Vui lòng kiểm tra terminal để lấy link tạo Index',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                )
                              : _stats.isEmpty
                                  ? const Center(child: Text('Chưa có dữ liệu học tập'))
                                  : _buildChart(colorScheme),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Summary Stats
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Tổng từ đã thuộc',
                    _stats.values.fold(0, (sum, val) => sum + val).toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Trung bình',
                    _calculateAverage(),
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _selectedText(String period) {
    switch (period) {
      case 'day': return 'Ngày học';
      case 'week': return 'Tuần học';
      case 'month': return 'Tháng học';
      case 'year': return 'Năm học';
      default: return 'Ngày học';
    }
  }

  String _calculateAverage() {
    if (_stats.isEmpty) return '0';
    final total = _stats.values.fold(0, (sum, val) => sum + val);
    return (total / _stats.length).toStringAsFixed(1);
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(ColorScheme colorScheme) {
    final sortedKeys = _stats.keys.toList()..sort();
    final dataPoints = sortedKeys.map((key) => _stats[key] ?? 0).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (dataPoints.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colorScheme.primary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} từ',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  final key = sortedKeys[value.toInt()];
                  // Hiển thị nhãn rút gọn
                  String label = key;
                  if (_selectedPeriod == 'day') label = key.substring(5); // MM-DD
                  if (_selectedPeriod == 'week') label = key.substring(5); // WXX
                  if (_selectedPeriod == 'month') label = key.substring(5); // MM
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dataPoints.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dataPoints[index].toDouble(),
                color: colorScheme.primary,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
