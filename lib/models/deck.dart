class Deck {
  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastStudied;

  Deck({
    this.id,
    required this.name,
    required this.createdAt,
    this.lastStudied,
  });

  // Chuyển đổi từ Map (SQLite) sang Object
  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      lastStudied: map['last_studied'] != null 
          ? DateTime.parse(map['last_studied']) 
          : null,
    );
  }

  // Chuyển đổi từ Object sang Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'last_studied': lastStudied?.toIso8601String(),
    };
  }

  // Tạo bản sao với các thuộc tính thay đổi
  Deck copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastStudied,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastStudied: lastStudied ?? this.lastStudied,
    );
  }
}
