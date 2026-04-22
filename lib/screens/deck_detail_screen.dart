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
    Future.microtask(() {
      if (!mounted) return;
      if (widget.deck.id != null) {
        context.read<DeckProvider>().fetchWords(widget.deck.id!);
      }
    });
  }

  void _showAddWordDialog() {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    final exampleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm từ mới'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                decoration: const InputDecoration(
                  labelText: 'Từ vựng (mặt trước)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: backController,
                decoration: const InputDecoration(
                  labelText: 'Nghĩa (mặt sau)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: exampleController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Câu ví dụ (tùy chọn)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
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

  void _showEditDeckDialog() {
    final controller = TextEditingController(text: widget.deck.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa tên bộ thẻ'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Tên bộ thẻ'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<DeckProvider>().updateDeck(widget.deck.id!, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDeckDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bộ thẻ?'),
        content: const Text('Tất cả từ vựng trong bộ thẻ này sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              context.read<DeckProvider>().deleteDeck(widget.deck.id!);
              Navigator.pop(context);
              Navigator.pop(context); // Go back home
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showEditWordDialog(dynamic word) {
    final frontController = TextEditingController(text: word.front);
    final backController = TextEditingController(text: word.back);
    final exampleController = TextEditingController(text: word.example ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa từ vựng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                decoration: const InputDecoration(labelText: 'Từ vựng'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: backController,
                decoration: const InputDecoration(labelText: 'Nghĩa'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: exampleController,
                decoration: const InputDecoration(labelText: 'Ví dụ'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
                context.read<DeckProvider>().updateWord(
                      widget.deck.id!,
                      word.id!,
                      frontController.text,
                      backController.text,
                      exampleController.text.isEmpty ? null : exampleController.text,
                    );
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteWordDialog(dynamic word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa từ?'),
        content: Text('Bạn có chắc muốn xóa từ "${word.front}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              context.read<DeckProvider>().deleteWord(widget.deck.id!, word.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer<DeckProvider>(
        builder: (context, provider, child) {
          final words = provider.currentWords;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom AppBar with Hero effect
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Hero(
                    tag: 'deck_${widget.deck.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        widget.deck.name,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary.withValues(alpha: 0.1), colorScheme.surface],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDeckDialog();
                      } else if (value == 'delete') {
                        _showDeleteDeckDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Sửa tên'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Xóa bộ thẻ', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action Cards Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Progress Summary
                      if (words.isNotEmpty) ...[
                        _buildProgressBanner(colorScheme, words),
                        const SizedBox(height: 20),
                      ],
                      Row(
                        children: [
                          _LearningModeCard(
                            title: 'Flashcards',
                            subtitle: 'Lật & Học',
                            icon: Icons.rectangle_outlined,
                            color: Colors.blueAccent,
                            onTap: () {
                              if (words.isEmpty) return _showEmptyWarning();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FlashcardScreen(
                                    deckId: widget.deck.id!,
                                    words: words,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _LearningModeCard(
                            title: 'Kiểm tra',
                            subtitle: 'Thử thách',
                            icon: Icons.assignment_outlined,
                            color: Colors.orangeAccent,
                            onTap: () {
                              if (words.isEmpty) return _showEmptyWarning();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizScreen(
                                    deckId: widget.deck.id!,
                                    words: words,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Title Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Từ vựng (${words.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.sort, size: 18),
                        label: const Text('Thứ tự'),
                      )
                    ],
                  ),
                ),
              ),

              // Words List
              if (words.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Chưa có từ nào. Hãy thêm từ mới!')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final word = words[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        word.front,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        word.back,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    word.isLearned ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: word.isLearned ? Colors.amber : Colors.grey.shade400,
                                    size: 28,
                                  ),
                                  onPressed: () => provider.toggleWordLearned(word),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditWordDialog(word);
                                    } else if (value == 'delete') {
                                      _showDeleteWordDialog(word);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Sửa'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Xóa'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: words.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWordDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm từ'),
      ),
    );
  }

  void _showEmptyWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vui lòng thêm ít nhất 1 từ để học!'), behavior: SnackBarBehavior.floating),
    );
  }

  void _showQuizWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cần ít nhất 4 từ để bắt đầu Quiz!'), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildProgressBanner(ColorScheme colorScheme, List<dynamic> words) {
    final learnedCount = words.where((w) => w.isLearned).length;
    final progress = words.isEmpty ? 0.0 : learnedCount / words.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tiến độ học tập',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã học $learnedCount/${words.length} từ vựng',
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LearningModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
