import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../providers/deck_provider.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;
  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<DeckProvider>().fetchWords(widget.deck.id!)
    );
  }

  void _showAddWordDialog() {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    final exampleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm từ mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                decoration: const InputDecoration(labelText: 'Từ tiếng Anh'),
              ),
              TextField(
                controller: backController,
                decoration: const InputDecoration(labelText: 'Nghĩa tiếng Việt'),
              ),
              TextField(
                controller: exampleController,
                decoration: const InputDecoration(labelText: 'Ví dụ (không bắt buộc)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                context.read<DeckProvider>().addWord(
                  widget.deck.id!,
                  frontController.text,
                  backController.text,
                  exampleController.text.isEmpty ? null : exampleController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWordDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 3 Nút chức năng phía trên
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.style,
                    label: 'Flashcard',
                    color: Colors.blue,
                    onTap: () {
                      final words = context.read<DeckProvider>().currentWords;
                      if (words.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bộ thẻ chưa có từ nào!')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashcardScreen(deckId: widget.deck.id!, words: words),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.quiz,
                    label: 'Làm Quiz',
                    color: Colors.orange,
                    onTap: () {
                      final words = context.read<DeckProvider>().currentWords;
                      if (words.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cần ít nhất 4 từ để làm Quiz!')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizScreen(deckId: widget.deck.id!, words: words),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tiêu đề danh sách
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.list, size: 20),
                SizedBox(width: 8),
                Text('Danh sách từ vựng', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Danh sách từ vựng
          Expanded(
            child: Consumer<DeckProvider>(
              builder: (context, provider, child) {
                if (provider.currentWords.isEmpty) {
                  return const Center(child: Text('Chưa có từ nào trong bộ thẻ này.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.currentWords.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final word = provider.currentWords[index];
                    return Card(
                      elevation: 0,
                      color: colorScheme.surfaceVariant.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: ListTile(
                        title: Text(word.front, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(word.back),
                        trailing: IconButton(
                          icon: Icon(
                            word.isLearned ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: word.isLearned ? Colors.green : colorScheme.outline,
                          ),
                          onPressed: () => provider.toggleWordLearned(word),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWordDialog,
        tooltip: 'Thêm từ mới',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
