import 'dart:async';
import 'package:flutter/material.dart';
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
    await _firestoreService!.updateWord(word.deckId, word.id!, {
      'is_learned': !word.isLearned,
      'learned_at': !word.isLearned ? Timestamp.now() : null,
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

  // Note: Streak will need more logic in Cloud Firestore 
  // For now, we focus on the core sync.
  
  @override
  void dispose() {
    _decksSubscription?.cancel();
    _wordsSubscription?.cancel();
    super.dispose();
  }
}
