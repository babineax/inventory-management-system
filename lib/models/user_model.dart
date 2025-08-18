enum UserRole { admin, staff }

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;
  final String? profilePhotoPath;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
    this.profilePhotoPath,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      id: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? map['display_name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.staff,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : (map['created_at'] != null
              ? DateTime.parse(map['created_at'])
              : DateTime.now()),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'])
          : (map['last_login_at'] != null
              ? DateTime.parse(map['last_login_at'])
              : DateTime.now()),
      isActive: _convertToBool(map['isActive'] ?? map['is_active'] ?? true),
      profilePhotoPath: map['profile_photo_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'display_name': displayName,
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'profile_photo_path': profilePhotoPath,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? profilePhotoPath,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;

  // Helper method to convert SQLite integer to boolean
  static bool _convertToBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}
