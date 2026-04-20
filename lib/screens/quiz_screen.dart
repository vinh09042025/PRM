import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/word.dart';
import '../providers/deck_provider.dart';

class QuizScreen extends StatefulWidget {
  final int deckId;
  final List<Word> words;
  const QuizScreen({super.key, required this.deckId, required this.words});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _isFinished = false;
  int? _selectedIndex;
  bool _isAnswered = false;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  void _generateOptions() {
    final correctWord = widget.words[_currentIndex];
    List<String> options = [correctWord.back];

    // Lấy 3 đáp án sai từ các từ khác trong deck
    List<String> otherBacks = widget.words
        .where((w) => w.id != correctWord.id)
        .map((w) => w.back)
        .toList();

    otherBacks.shuffle();
    options.addAll(otherBacks.take(3));

    // Nếu không đủ 4 từ (tuy đã check ở màn hình trước), ta có thể lấy thêm từ list mặc định
    while (options.length < 4) {
      options.add("Đáp án ngẫu nhiên ${options.length}");
    }

    options.shuffle();
    setState(() {
      _options = options;
      _isAnswered = false;
      _selectedIndex = null;
    });
  }

  void _onAnswer(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      if (_options[index] == widget.words[_currentIndex].back) {
        _correctCount++;
      }
    });

    // Chờ 1.5 giây để người dùng thấy kết quả rồi chuyển câu
    Timer(const Duration(milliseconds: 1500), () {
      if (_currentIndex < widget.words.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _generateOptions();
      } else {
        setState(() {
          _isFinished = true;
        });
        // Ghi lại kết quả
        context.read<DeckProvider>().recordStudySession(
          widget.deckId,
          _correctCount,
          widget.words.length,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return _QuizResultView(
        deckId: widget.deckId,
        correct: _correctCount,
        total: widget.words.length,
        onRetry: () => Navigator.pop(context),
      );
    }

    final word = widget.words[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trắc nghiệm (${_currentIndex + 1}/${widget.words.length})',
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.words.length,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 48),

            // Câu hỏi
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Text(
                    'Từ này có nghĩa là gì?',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    word.front,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Các đáp án
            Expanded(
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final option = _options[index];
                  Color? color;
                  IconData? icon;

                  if (_isAnswered) {
                    if (option == word.back) {
                      color = Colors.green;
                      icon = Icons.check_circle;
                    } else if (_selectedIndex == index) {
                      color = Colors.red;
                      icon = Icons.cancel;
                    }
                  }

                  return InkWell(
                    onTap: () => _onAnswer(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: color != null
                            ? color.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color ?? colorScheme.outlineVariant,
                          width: color != null ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: color != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: color ?? colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (icon != null) Icon(icon, color: color),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizResultView extends StatefulWidget {
  final int deckId;
  final int correct;
  final int total;
  final VoidCallback onRetry;

  const _QuizResultView({
    required this.deckId,
    required this.correct,
    required this.total,
    required this.onRetry,
  });

  @override
  State<_QuizResultView> createState() => _QuizResultViewState();
}

class _QuizResultViewState extends State<_QuizResultView> {
  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = context.read<DeckProvider>().getAllStudySessions(
      widget.deckId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = (widget.correct / widget.total * 100).round();
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score >= 80
                      ? 'Tuyệt vời! 🏆'
                      : score >= 50
                      ? 'Khá lắm! 👍'
                      : 'Cố gắng thêm nhé! 💪',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CircularProgressIndicator(
                        value: widget.correct / widget.total,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$score%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Bạn đã trả lời đúng ${widget.correct} trên tổng số ${widget.total} câu hỏi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 48),
                // Trend chart by attempts
                const Text(
                  'Tiến trình theo lần ôn tập',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _sessionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      return Text('Lỗi: ${snapshot.error}');
                    }

                    final sessions = snapshot.data ?? [];

                    if (sessions.isEmpty) {
                      return const Text('Chưa có dữ liệu');
                    }

                    // Prepare chart data: score percentage for each attempt
                    final chartSpots = <FlSpot>[];
                    for (int i = 0; i < sessions.length; i++) {
                      final correct = sessions[i]['correct_count'] as int;
                      final total = sessions[i]['total_count'] as int;
                      final percentage = total > 0
                          ? (correct / total * 100)
                          : 0.0;
                      chartSpots.add(FlSpot(i.toDouble(), percentage));
                    }

                    final maxY = 100.0;
                    final maxX = (chartSpots.length - 1).toDouble();

                    return SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: maxX > 0 ? maxX : 1,
                          minY: 0,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 20,
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: chartSpots.length > 10
                                    ? (chartSpots.length / 5).roundToDouble()
                                    : 1,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    (value.toInt() + 1).toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}%',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartSpots,
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 2,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                          radius: 4,
                                          color: Colors.blue,
                                          strokeWidth: 0,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onRetry,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Quay lại danh sách'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
