class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.shopName,
    required this.realName,
    required this.phone,
    this.profileImage,
    this.createdAt,
  });

  final int? id;
  final String username;
  final String role;
  final String shopName;
  final String realName;
  final String phone;
  final String? profileImage;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id']),
      username: (json['username'] ?? '').toString(),
      role: (json['role'] ?? 'vendor').toString(),
      shopName: (json['shop_name'] ?? json['shopName'] ?? '').toString(),
      realName: (json['real_name'] ?? json['realName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      profileImage: _nullableString(
        json['profile_image'] ?? json['profileImage'],
      ),
      createdAt: _toDate(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'role': role,
    'shop_name': shopName,
    'real_name': realName,
    'phone': phone,
    'profile_image': profileImage,
    'created_at': createdAt?.toIso8601String(),
  };

  static int? _toInt(Object? value) =>
      value == null ? null : int.tryParse(value.toString());

  static DateTime? _toDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  static String? _nullableString(Object? value) =>
      value == null || value.toString().isEmpty ? null : value.toString();
}
