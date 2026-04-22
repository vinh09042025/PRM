import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/deck_provider.dart';

class QuizScreen extends StatefulWidget {
  final String deckId;
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

    List<String> otherBacks = widget.words
        .where((w) => w.id != correctWord.id)
        .map((w) => w.back)
        .toList();

    otherBacks.shuffle();
    options.addAll(otherBacks.take(3));

    while (options.length < 4) {
      options.add("Đáp án ngẫu nhiên ${options.length}");
    }

    options.shuffle();
    if (mounted) {
      setState(() {
        _options = options;
        _isAnswered = false;
        _selectedIndex = null;
      });
    }
  }

  void _onAnswer(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      if (_options[index] == widget.words[_currentIndex].back) {
        _correctCount++;
        // Cập nhật trạng thái "Đã học" lên Cloud
        final word = widget.words[_currentIndex];
        if (!word.isLearned) {
          context.read<DeckProvider>().toggleWordLearned(word);
        }
      }
    });

    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_currentIndex < widget.words.length - 1) {
        setState(() => _currentIndex++);
        _generateOptions();
      } else {
        setState(() => _isFinished = true);
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
        title: Text('${_currentIndex + 1} / ${widget.words.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.words.length,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 48),
            
            // Question Card
            Container(
              padding: const EdgeInsets.all(40),
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'ĐỊNH NGHĨA NÀO ĐÚNG?',
                    style: TextStyle(letterSpacing: 1.5, fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    word.front,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Options List
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final option = _options[index];
                  bool isCorrect = option == word.back;
                  bool isSelected = _selectedIndex == index;
                  
                  Color borderColor = colorScheme.outlineVariant.withValues(alpha: 0.5);
                  Color bgColor = colorScheme.surfaceContainer;
                  Color textColor = colorScheme.onSurface;
                  
                  if (_isAnswered) {
                    if (isCorrect) {
                      borderColor = Colors.greenAccent.shade700;
                      bgColor = Colors.green.shade50;
                      textColor = Colors.greenAccent.shade700;
                    } else if (isSelected) {
                      borderColor = Colors.redAccent;
                      bgColor = Colors.red.shade50;
                      textColor = Colors.redAccent;
                    }
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: InkWell(
                      onTap: () => _onAnswer(index),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor, width: (isSelected || (_isAnswered && isCorrect)) ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor),
                                color: isSelected ? borderColor : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : borderColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: (isSelected || (_isAnswered && isCorrect)) ? FontWeight.bold : FontWeight.normal,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (_isAnswered && isCorrect) const Icon(Icons.check_circle, color: Colors.green),
                            if (_isAnswered && isSelected && !isCorrect) const Icon(Icons.cancel, color: Colors.red),
                          ],
                        ),
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
  final String deckId;
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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final score = (widget.correct / widget.total * 100).round();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả trắc nghiệm')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: colorScheme.primary.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      score >= 80 ? 'TUYỆT VỜI! 🏆' : 'KHÁ LẮM! 👍',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 32),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: widget.correct / widget.total,
                            strokeWidth: 12,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ),
                        Text('$score%', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Bạn đúng ${widget.correct}/${widget.total} câu.',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
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
                  child: const Text('Xong', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
