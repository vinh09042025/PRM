import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../providers/deck_provider.dart';

class AIGenerateScreen extends StatefulWidget {
  const AIGenerateScreen({super.key});

  @override
  State<AIGenerateScreen> createState() => _AIGenerateScreenState();
}

class _AIGenerateScreenState extends State<AIGenerateScreen> {
  final _aiService = AIService();
  final _categoryController = TextEditingController();
  
  String _selectedLanguage = 'Tiếng Anh';
  String _selectedDifficulty = 'Medium';
  int _wordCount = 10;
  bool _isLoading = false;

  final List<String> _languages = ['Tiếng Anh', 'Tiếng Pháp', 'Tiếng Nhật', 'Tiếng Hàn', 'Tiếng Trung', 'Tiếng Đức'];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  Future<void> _handleGenerate() async {
    if (_categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập chủ đề (Thể loại)'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final aiWords = await _aiService.generateFlashcards(
        language: _selectedLanguage,
        difficulty: _selectedDifficulty,
        category: _categoryController.text,
        count: _wordCount,
      );

      if (!mounted) return;

      final deckName = 'AI: ${_categoryController.text}';
      await context.read<DeckProvider>().addAIGeneratedDeck(deckName, aiWords);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tạo thành công bộ thẻ: $deckName'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bằng AI'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPromotionCard(colorScheme),
                const SizedBox(height: 32),
                
                _buildSectionTitle('Ngôn ngữ muốn học'),
                const SizedBox(height: 12),
                _buildDropdown(_selectedLanguage, _languages, (val) => setState(() => _selectedLanguage = val!)),
                
                const SizedBox(height: 24),
                _buildSectionTitle('Mức độ khó'),
                const SizedBox(height: 12),
                _buildDifficultySelector(colorScheme),
                
                const SizedBox(height: 24),
                _buildSectionTitle('Chủ đề hoặc Thể loại'),
                const SizedBox(height: 12),
                TextField(
                  controller: _categoryController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'VD: Du lịch, Nấu ăn, Công nghệ...',
                    prefixIcon: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary, size: 20),
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                _buildSectionTitle('Số lượng thẻ: $_wordCount'),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: colorScheme.primary,
                    inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.1),
                    thumbColor: colorScheme.primary,
                    overlayColor: colorScheme.primary.withValues(alpha: 0.1),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _wordCount.toDouble(),
                    min: 5,
                    max: 20,
                    divisions: 3,
                    onChanged: (val) => setState(() => _wordCount = val.toInt()),
                  ),
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGenerate,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isLoading) ...[
                          const Icon(Icons.flash_on_rounded),
                          const SizedBox(width: 12),
                          const Text('BẮT ĐẦU TẠO BỘ THẺ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ] else ...[
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          const Text('ĐANG XỬ LÝ...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: colorScheme.surface.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAIPulseAnimation(colorScheme),
                      const SizedBox(height: 24),
                      Text(
                        'Gemini đang soạn thảo bộ thẻ...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Việc này có thể mất vài giây'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIPulseAnimation(ColorScheme colorScheme) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 50),
    );
  }

  Widget _buildPromotionCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Sức mạnh từ AI',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Chúng tôi sử dụng Gemini AI để giúp bạn soạn từ vựng nhanh gấp 10 lần.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 16)))).toList(),
        ),
      ),
    );
  }

  Widget _buildDifficultySelector(ColorScheme colorScheme) {
    return Row(
      children: _difficulties.map((d) {
        bool isSelected = _selectedDifficulty == d;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedDifficulty = d),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Text(
                  d,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
