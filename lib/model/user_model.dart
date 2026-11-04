class UserModel {
  final int id;
  final String username;
  final String role;

  UserModel({required this.id, required this.username, required this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
    );
  }
}
