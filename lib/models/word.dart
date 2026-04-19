class Word {
  final int? id;
  final int deckId;
  final String front;
  final String back;
  final String? example;
  final bool isLearned;

  Word({
    this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.example,
    this.isLearned = false,
  });

  // Chuyển đổi từ Map (SQLite) sang Object
  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'],
      deckId: map['deck_id'],
      front: map['front'],
      back: map['back'],
      example: map['example'],
      isLearned: map['is_learned'] == 1,
    );
  }

  // Chuyển đổi từ Object sang Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'front': front,
      'back': back,
      'example': example,
      'is_learned': isLearned ? 1 : 0,
    };
  }

  // Tạo bản sao của word với các thuộc tính thay đổi (dùng cho update)
  Word copyWith({
    int? id,
    int? deckId,
    String? front,
    String? back,
    String? example,
    bool? isLearned,
  }) {
    return Word(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      example: example ?? this.example,
      isLearned: isLearned ?? this.isLearned,
    );
  }
}
