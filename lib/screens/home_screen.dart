import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/deck_provider.dart';
import 'deck_detail_screen.dart';
import 'ai_generate_screen.dart';
import 'statistics_screen.dart';
import 'login_screen.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      // Data sync is handled automatically by DeckProvider when UID changes
    });
  }

  void _showAddDeckDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo bộ từ mới'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tên bộ thẻ (vd: TOEIC, JLPT...)',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                context.read<DeckProvider>().addDeck(textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
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
        title: const Text('WordSprint', style: TextStyle(letterSpacing: 1.2)),
        actions: [
          Consumer2<ThemeProvider, AuthProvider>(
            builder: (context, themeProvider, authProvider, child) {
              final user = authProvider.firebaseUser;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined),
                onSelected: (value) async {
                  if (value == 'theme') {
                    themeProvider.toggleTheme(!themeProvider.isDarkMode);
                  } else if (value == 'migrate') {
                    _handleMigration();
                  } else if (value == 'logout') {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Người dùng',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        Text(
                          user?.email ?? 'Không có email',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(
                          themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(themeProvider.isDarkMode ? 'Chế độ sáng' : 'Chế độ tối'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'migrate',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text('Đồng bộ dữ liệu cũ'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _selectedIndex == 0 ? _buildLibraryBody(colorScheme) : const StatisticsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark_outlined),
            activeIcon: Icon(Icons.collections_bookmark),
            label: 'Thư viện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Thống kê',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? _buildFAB(colorScheme) : null,
    );
  }

  Widget _buildLibraryBody(ColorScheme colorScheme) {
    return Consumer<DeckProvider>(
      builder: (context, provider, child) {
        final filteredDecks = provider.decks
            .where((d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        final recentDecks = provider.decks
            .where((d) => d.lastStudied != null)
            .toList()
          ..sort((a, b) => b.lastStudied!.compareTo(a.lastStudied!));

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bộ thẻ...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear), 
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          }) 
                      : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // Streak Card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fireplace, color: Colors.orange, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${provider.currentStreak} Ngày liên tiếp',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Học tập chăm chỉ nhé!',
                          style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recent Title
            if (recentDecks.isNotEmpty && _searchQuery.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 20, top: 32, bottom: 12),
                  child: Text(
                    'Học gần đây',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // Recent List
            if (recentDecks.isNotEmpty && _searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentDecks.length > 5 ? 5 : recentDecks.length,
                    itemBuilder: (context, index) {
                      final deck = recentDecks[index];
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck))),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.history, size: 20, color: Colors.blueGrey),
                                  const Spacer(),
                                  Text(
                                    deck.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Library Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 32, bottom: 16),
                child: Text(
                  _searchQuery.isEmpty ? 'Thư viện của bạn' : 'Kết quả tìm kiếm',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Grid danh sách Deck
            if (provider.isLoading)
              const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                )),
              )
            else if (filteredDecks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'Chưa có bộ thẻ nào' : 'Không tìm thấy kết quả',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final deck = filteredDecks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DeckDetailScreen(deck: deck)),
                          ),
                          child: Hero(
                            tag: 'deck_${deck.id}',
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(Icons.collections_bookmark, color: colorScheme.primary),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            deck.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            deck.lastStudied != null
                                                ? 'Học lần cuối: ${deck.lastStudied!.day}/${deck.lastStudied!.month}'
                                                : 'Chưa bắt đầu học',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.black26),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredDecks.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFAB(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'ai_btn',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIGenerateScreen()),
            );
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Tạo bằng AI'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'add_btn',
          onPressed: _showAddDeckDialog,
          icon: const Icon(Icons.add),
          label: const Text('Thêm bộ thẻ'),
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ],
    );
  }

  void _handleMigration() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang đồng bộ dữ liệu lên Cloud...'),
          ],
        ),
      ),
    );

    try {
      final count = await context.read<DeckProvider>().migrateLocalDataToCloud();
      if (!mounted) return;
      Navigator.pop(context); // Đóng loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0 ? 'Đã đồng bộ thành công $count bộ thẻ!' : 'Không tìm thấy dữ liệu cũ để đồng bộ'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đồng bộ: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
