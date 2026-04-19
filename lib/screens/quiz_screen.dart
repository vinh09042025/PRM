import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          widget.words.length
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return _QuizResultView(
        correct: _correctCount, 
        total: widget.words.length,
        onRetry: () => Navigator.pop(context),
      );
    }

    final word = widget.words[_currentIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Trắc nghiệm (${_currentIndex + 1}/${widget.words.length})'),
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
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    word.front,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Các đáp án
            Expanded(
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: color != null ? color.withOpacity(0.1) : Colors.transparent,
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
                                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
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

class _QuizResultView extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onRetry;

  const _QuizResultView({required this.correct, required this.total, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final score = (correct / total * 100).round();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score >= 80 ? 'Tuyệt vời! 🏆' : score >= 50 ? 'Khá lắm! 👍' : 'Cố gắng thêm nhé! 💪',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: CircularProgressIndicator(
                      value: correct / total,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text('$score%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Bạn đã trả lời đúng $correct trên tổng số $total câu hỏi.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Quay lại danh sách'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
