class User {
  final int? id;
  final String username;
  final String password;
  final String? fullName;

  User({
    this.id,
    required this.username,
    required this.password,
    this.fullName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      fullName: map['full_name'],
    );
  }
}
