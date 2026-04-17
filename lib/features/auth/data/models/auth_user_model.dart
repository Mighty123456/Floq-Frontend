import '../../domain/entities/auth_user_entity.dart';

class AuthUserModel extends AuthUser {
  AuthUserModel({
    required super.id,
    required super.name,
    required super.email,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': name,
      'email': email,
    };
  }
}
