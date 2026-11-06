class UserModel {
  final int id;
  final String username;
  final String role;

  UserModel({required this.id, required this.username, required this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      role: json['role'] ?? 'vendor', // ถ้าเป็น null ให้ใส่ default 'vendor'
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'role': role};
  }
}
