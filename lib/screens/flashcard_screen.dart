import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/word.dart';
import '../providers/deck_provider.dart';

class FlashcardScreen extends StatefulWidget {
  final int deckId;
  final List<Word> words;
  const FlashcardScreen({super.key, required this.deckId, required this.words});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _isFinished = false;
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  late AnimationController _rememberedAnimationController;
  late AnimationController _forgetAnimationController;
  bool _isShowingRememberedAnimation = false;
  bool _isShowingForgetAnimation = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _rememberedAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _forgetAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _flutterTts.speak(text);
      setState(() => _isSpeaking = false);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _rememberedAnimationController.dispose();
    _forgetAnimationController.dispose();
    super.dispose();
  }

  void _onAnswer(bool isCorrect) async {
    if (isCorrect) {
      // Show remembered animation
      setState(() => _isShowingRememberedAnimation = true);
      _rememberedAnimationController.forward();

      // Wait for animation to complete before moving to next card
      await Future.delayed(const Duration(milliseconds: 600));

      _correctCount++;

      if (_currentIndex < widget.words.length - 1) {
        setState(() {
          _currentIndex++;
          _isShowingRememberedAnimation = false;
          _rememberedAnimationController.reset();
        });
      } else {
        setState(() {
          _isFinished = true;
        });
        // Ghi lại phiên học vào DB
        context.read<DeckProvider>().recordStudySession(
          widget.deckId,
          _correctCount,
          widget.words.length,
        );
      }
    } else {
      // Show forget animation
      setState(() => _isShowingForgetAnimation = true);
      _forgetAnimationController.forward();

      // Wait for animation to complete before moving to next card
      await Future.delayed(const Duration(milliseconds: 600));

      if (_currentIndex < widget.words.length - 1) {
        setState(() {
          _currentIndex++;
          _isShowingForgetAnimation = false;
          _forgetAnimationController.reset();
        });
      } else {
        setState(() {
          _isFinished = true;
        });
        // Ghi lại phiên học vào DB
        context.read<DeckProvider>().recordStudySession(
          widget.deckId,
          _correctCount,
          widget.words.length,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return _ResultView(
        deckId: widget.deckId,
        correct: _correctCount,
        total: widget.words.length,
        onRetry: () => Navigator.pop(context),
      );
    }

    final word = widget.words[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thẻ ghi nhớ (${_currentIndex + 1}/${widget.words.length})',
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: () => _speak(word.front),
                  icon: Icon(
                    _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                    color: _isSpeaking ? Colors.amber : null,
                  ),
                  tooltip: 'Phát âm từ',
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              // Tiến trình
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.words.length,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const Spacer(),

              // Thẻ Flashcard với hiệu ứng lật
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedOpacity(
                  opacity:
                      (_isShowingRememberedAnimation ||
                          _isShowingForgetAnimation)
                      ? 1 -
                            (_isShowingRememberedAnimation
                                ? _rememberedAnimationController.value
                                : _forgetAnimationController.value)
                      : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: FlipCardWidget(
                    key: ValueKey(_currentIndex),
                    front: _CardFace(text: word.front, isFront: true),
                    back: _CardFace(
                      text: word.back,
                      subText: word.example,
                      isFront: false,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Nút điều khiển
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            (_isShowingRememberedAnimation ||
                                _isShowingForgetAnimation)
                            ? null
                            : () => _onAnswer(false),
                        icon: const Icon(Icons.close),
                        label: const Text('Chưa thuộc'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            (_isShowingRememberedAnimation ||
                                _isShowingForgetAnimation)
                            ? null
                            : () => _onAnswer(true),
                        icon: const Icon(Icons.check),
                        label: const Text('Đã thuộc'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Remembered animation overlay
          if (_isShowingRememberedAnimation)
            AnimatedBuilder(
              animation: _rememberedAnimationController,
              builder: (context, child) {
                return Center(
                  child: Transform.scale(
                    scale: _rememberedAnimationController.value * 1.5,
                    child: Opacity(
                      opacity: 1 - _rememberedAnimationController.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          // Forget animation overlay
          if (_isShowingForgetAnimation)
            AnimatedBuilder(
              animation: _forgetAnimationController,
              builder: (context, child) {
                return Center(
                  child: Transform.scale(
                    scale: _forgetAnimationController.value * 1.5,
                    child: Opacity(
                      opacity: 1 - _forgetAnimationController.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class FlipCardWidget extends StatefulWidget {
  final Widget front;
  final Widget back;

  const FlipCardWidget({super.key, required this.front, required this.back});

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * pi;
        return GestureDetector(
          onTap: _flipCard,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: angle < pi / 2
                ? widget.front
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: widget.back,
                  ),
          ),
        );
      },
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String? subText;
  final bool isFront;

  const _CardFace({required this.text, this.subText, required this.isFront});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isFront
            ? Colors.white
            : colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFront ? 'Từ vựng' : 'Nghĩa',
              style: TextStyle(
                color: colorScheme.primary,
                letterSpacing: 2,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (subText != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Text(
                'Ví dụ:',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subText!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatefulWidget {
  final int deckId;
  final int correct;
  final int total;
  final VoidCallback onRetry;

  const _ResultView({
    required this.deckId,
    required this.correct,
    required this.total,
    required this.onRetry,
  });

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
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
                const Icon(Icons.stars, color: Colors.amber, size: 100),
                const SizedBox(height: 24),
                const Text(
                  'Hoàn thành phiên học!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bạn đã thuộc ${widget.correct}/${widget.total} từ ($score%)',
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
