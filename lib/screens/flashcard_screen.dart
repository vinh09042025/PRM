import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/word.dart';
import '../providers/deck_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class FlashcardScreen extends StatefulWidget {
  final String deckId;
  final List<Word> words;
  const FlashcardScreen({super.key, required this.deckId, required this.words});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with TickerProviderStateMixin {
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
      if (mounted) setState(() => _isSpeaking = false);
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
      setState(() => _isShowingRememberedAnimation = true);
      _rememberedAnimationController.forward();
      
      // Cập nhật trạng thái "Đã học" lên Cloud
      final word = widget.words[_currentIndex];
      if (!word.isLearned) {
        context.read<DeckProvider>().toggleWordLearned(word);
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      _correctCount++;
    } else {
      setState(() => _isShowingForgetAnimation = true);
      _forgetAnimationController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    if (_currentIndex < widget.words.length - 1) {
      setState(() {
        _currentIndex++;
        _isShowingRememberedAnimation = false;
        _isShowingForgetAnimation = false;
        _rememberedAnimationController.reset();
        _forgetAnimationController.reset();
      });
    } else {
      setState(() => _isFinished = true);
      context.read<DeckProvider>().recordStudySession(
        widget.deckId,
        _correctCount,
        widget.words.length,
      );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${widget.words.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / widget.words.length,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Hero(
                  tag: 'card_hero',
                  child: FlipCardWidget(
                    key: ValueKey(_currentIndex),
                    front: _CardFace(
                      text: word.front, 
                      isFront: true,
                      onSpeak: () => _speak(word.front),
                      isSpeaking: _isSpeaking,
                    ),
                    back: _CardFace(
                      text: word.back,
                      subText: word.example,
                      isFront: false,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: Row(
                  children: [
                    _AnswerButton(
                      label: 'Chưa thuộc',
                      icon: Icons.sentiment_dissatisfied_rounded,
                      color: Colors.redAccent,
                      onTap: () => _onAnswer(false),
                    ),
                    const SizedBox(width: 20),
                    _AnswerButton(
                      label: 'Đã thuộc',
                      icon: Icons.sentiment_very_satisfied_rounded,
                      color: Colors.greenAccent.shade700,
                      onTap: () => _onAnswer(true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_isShowingRememberedAnimation) _buildOverlay(Icons.check_circle, Colors.green),
          if (_isShowingForgetAnimation) _buildOverlay(Icons.cancel, Colors.red),
        ],
      ),
    );
  }

  Widget _buildOverlay(IconData icon, Color color) {
    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Icon(icon, color: color, size: 120),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.3)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String? subText;
  final bool isFront;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  const _CardFace({
    required this.text, 
    this.subText, 
    required this.isFront,
    this.onSpeak,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 420,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isFront && onSpeak != null)
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                  color: isSpeaking ? colorScheme.primary : Colors.grey,
                ),
                onPressed: onSpeak,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFront ? 'THUẬT NGỮ' : 'ĐỊNH NGHĨA',
                    style: TextStyle(
                      letterSpacing: 2,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (subText != null && subText!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Divider(indent: 40, endIndent: 40),
                    ),
                    Text(
                      subText!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

class _FlipCardWidgetState extends State<FlipCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
    setState(() => _isFront = !_isFront);
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
              ..setEntry(3, 2, 0.001)
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

class _ResultView extends StatefulWidget {
  final String deckId;
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
    _sessionsFuture = context.read<DeckProvider>().getAllStudySessions(widget.deckId);
  }

  @override
  Widget build(BuildContext context) {
    final score = (widget.correct / widget.total * 100).round();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả học tập')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: widget.correct / widget.total,
                            strokeWidth: 12,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '$score%',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const Text('Chính xác', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Tuyệt vời! Bạn đã thuộc ${widget.correct} từ.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Tiến trình ôn tập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _sessionsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final sessions = snapshot.data!;
                  if (sessions.isEmpty) return const Text('Chưa có dữ liệu lịch sử');

                  final spots = sessions.asMap().entries.map((e) {
                    final p = (e.value['correct_count'] / e.value['total_count'] * 100);
                    return FlSpot(e.key.toDouble(), p);
                  }).toList();

                  return Container(
                    height: 200,
                    padding: const EdgeInsets.only(top: 20, right: 20),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: colorScheme.primary,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: colorScheme.primary.withOpacity(0.1),
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Tiếp tục học tập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
