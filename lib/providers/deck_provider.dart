import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deck.dart';
import '../models/word.dart';
import '../services/firestore_service.dart';
import '../data/database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeckProvider with ChangeNotifier {
  FirestoreService? _firestoreService;
  List<Deck> _decks = [];
  List<Word> _currentWords = [];
  int _currentStreak = 0;
  bool _isLoading = false;
  
  StreamSubscription? _decksSubscription;
  StreamSubscription? _wordsSubscription;
  StreamSubscription? _studySessionsSubscription;

  List<Deck> get decks => _decks;
  List<Word> get currentWords => _currentWords;
  int get currentStreak => _currentStreak;
  bool get isLoading => _isLoading;

  // Called when UID changes (using ProxyProvider or manually)
  void updateService(String? uid) {
    if (uid == null) {
      _firestoreService = null;
      _decks = [];
      _currentWords = [];
      _decksSubscription?.cancel();
      _wordsSubscription?.cancel();
    } else {
      _firestoreService = FirestoreService(uid: uid);
      _listenToDecks();
      _listenToStudySessions();
    }
    notifyListeners();
  }

  void _listenToDecks() {
    _decksSubscription?.cancel();
    _isLoading = true;
    _decksSubscription = _firestoreService?.streamDecks().listen((decks) {
      _decks = decks;
      _isLoading = false;
      notifyListeners();
    });
  }

  void fetchWords(String deckId) {
    _wordsSubscription?.cancel();
    _wordsSubscription = _firestoreService?.streamWords(deckId).listen((words) {
      _currentWords = words;
      notifyListeners();
    });
  }

  void _listenToStudySessions() {
    _studySessionsSubscription?.cancel();
    _studySessionsSubscription = _firestoreService?.streamStudySessions().listen((sessions) {
      _calculateStreak(sessions);
      notifyListeners();
    });
  }

  void _calculateStreak(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) {
      _currentStreak = 0;
      return;
    }

    // Lấy danh sách các ngày duy nhất có học (đã sắp xếp giảm dần)
    final dates = sessions.map((s) {
      final timestamp = s['date'] as Timestamp;
      final date = timestamp.toDate();
      return DateTime(date.year, date.month, date.day);
    }).toSet().toList()..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) {
      _currentStreak = 0;
      return;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    // Nếu không học hôm nay VÀ không học hôm qua -> streak = 0
    if (!dates.contains(todayDate) && !dates.contains(yesterdayDate)) {
      _currentStreak = 0;
      return;
    }

    int streak = 0;
    DateTime currentCheck = dates.contains(todayDate) ? todayDate : yesterdayDate;

    for (var date in dates) {
      if (date.isAtSameMomentAs(currentCheck)) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else if (date.isBefore(currentCheck)) {
        // Có khoảng trống -> dừng streak
        break;
      }
    }

    _currentStreak = streak;
  }

  // --- Deck Actions ---

  Future<void> addDeck(String name) async {
    if (_firestoreService == null) return;
    await _firestoreService!.addDeck(name);
  }

  Future<void> updateDeck(String id, String name) async {
    if (_firestoreService == null) return;
    await _firestoreService!.updateDeck(id, name);
  }

  Future<void> deleteDeck(String id) async {
    if (_firestoreService == null) return;
    await _firestoreService!.deleteDeck(id);
  }

  // --- Word Actions ---

  Future<void> addWord(String deckId, String front, String back, String? example) async {
    if (_firestoreService == null) return;
    final word = Word(
      deckId: deckId,
      front: front,
      back: back,
      example: example,
    );
    await _firestoreService!.addWord(deckId, word);
  }

  Future<void> updateWord(String deckId, String wordId, String front, String back, String? example) async {
    if (_firestoreService == null) return;
    await _firestoreService!.updateWord(deckId, wordId, {
      'front': front,
      'back': back,
      'example': example,
    });
  }

  Future<void> deleteWord(String deckId, String wordId) async {
    if (_firestoreService == null) return;
    await _firestoreService!.deleteWord(deckId, wordId);
  }

  Future<void> toggleWordLearned(Word word) async {
    if (_firestoreService == null) return;
    
    // Nếu chuyển từ CHƯA thuộc sang ĐÃ thuộc -> cập nhật learnedAt
    // Nếu chuyển ngược lại -> xóa learnedAt
    final isBecomingLearned = !word.isLearned;
    
    await _firestoreService!.updateWord(word.deckId, word.id!, {
      'is_learned': isBecomingLearned,
      'uid': _firestoreService!.uid, // Đảm bảo luôn có UID để truy vấn Collection Group
      'learned_at': isBecomingLearned ? Timestamp.now() : null,
    });
  }

  // --- Stats ---

  Future<void> recordStudySession(String deckId, int correct, int total) async {
    if (_firestoreService == null) return;
    await _firestoreService!.recordSession(deckId, correct, total);
  }

  // Lấy tất cả phiên học của một bộ thẻ (Firestore version)
  Future<List<Map<String, dynamic>>> getAllStudySessions(String deckId) async {
    if (_firestoreService == null) return [];
    
    final snapshot = await _firestoreService!.db
        .collection('users')
        .doc(_firestoreService!.uid)
        .collection('study_sessions')
        .where('deck_id', isEqualTo: deckId)
        .orderBy('date', descending: false)
        .get();
        
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // --- AI Generation Support ---

  Future<void> addAIGeneratedDeck(String deckName, List<Map<String, dynamic>> aiWords) async {
    if (_firestoreService == null) return;
    
    try {
      // 1. Create the deck
      final deckId = await _firestoreService!.addDeck(deckName);
      
      // 2. Insert all words
      for (var aiWord in aiWords) {
        final newWord = Word(
          deckId: deckId,
          front: aiWord['front'] ?? 'Unknown',
          back: aiWord['back'] ?? 'Nghĩa chưa xác định',
          example: aiWord['example'],
        );
        await _firestoreService!.addWord(deckId, newWord);
      }
    } catch (e) {
      debugPrint('Lỗi khi lưu bộ thẻ AI: $e');
      rethrow;
    }
  }

  // --- Migration Support ---

  Future<int> migrateLocalDataToCloud() async {
    if (_firestoreService == null) return 0;
    
    int deckCount = 0;
    try {
      // 1. Get all local decks
      final localDecks = await DatabaseHelper.instance.getDecks();
      if (localDecks.isEmpty) return 0;

      for (var localDeckMap in localDecks) {
        final localDeckId = localDeckMap['id'] as int;
        final deckName = localDeckMap['name'] as String;

        // 2. Create this deck in Firestore
        final cloudDeckId = await _firestoreService!.addDeck(deckName);
        deckCount++;

        // 3. Get all words for this local deck
        final localWords = await DatabaseHelper.instance.getWordsByDeck(localDeckId);
        
        // 4. Upload each word to Firestore
        for (var localWordMap in localWords) {
          final word = Word.fromMap(localWordMap);
          // Ensure deckId is the new cloud ID
          final cloudWord = word.copyWith(deckId: cloudDeckId);
          await _firestoreService!.addWord(cloudDeckId, cloudWord);
        }
      }
      return deckCount;
    } catch (e) {
      debugPrint('Lỗi khi di cư dữ liệu: $e');
      rethrow;
    }
  }

  // --- Statistics Support ---

  Future<Map<String, int>> getStatistics(String period) async {
    if (_firestoreService == null) return {};

    try {
      final learnedWords = await _firestoreService!.getLearnedWords();
      final Map<String, int> stats = {};

      for (var word in learnedWords) {
        if (word.learnedAt == null) continue;
        
        String key;
        final date = word.learnedAt!;

        switch (period) {
          case 'day':
            key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
            break;
          case 'week':
            // Lấy ngày đầu tuần (Thứ 2)
            final startOfWeek = _getStartOfWeek(date);
            key = "${startOfWeek.year}-W${_getWeekNumber(startOfWeek)}";
            break;
          case 'month':
            key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
            break;
          case 'year':
            key = "${date.year}";
            break;
          default:
            key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        }

        stats[key] = (stats[key] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Lỗi khi lấy thống kê: $e');
      return {};
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  // Note: Streak will need more logic in Cloud Firestore 
  // For now, we focus on the core sync.
  
  @override
  void dispose() {
    _decksSubscription?.cancel();
    _wordsSubscription?.cancel();
    _studySessionsSubscription?.cancel();
    super.dispose();
  }
}
