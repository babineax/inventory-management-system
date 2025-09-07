import 'package:cloud_firestore/cloud_firestore.dart';

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

  String phone;

  // Notification preferences
  final bool emailNotificationsEnabled;
  final bool smsNotificationsEnabled;
  final bool expiryAlertsEnabled;
  final bool stockAlertsEnabled;
  final bool predictionAlertsEnabled;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
    this.profilePhotoPath,
    required this.phone,
    this.emailNotificationsEnabled = true,
    this.smsNotificationsEnabled = true,
    this.expiryAlertsEnabled = true,
    this.stockAlertsEnabled = true,
    this.predictionAlertsEnabled = true,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseTimestamp(dynamic timestampValue) {
      if (timestampValue == null) return DateTime.now();

      // Handle Firestore Timestamp
      if (timestampValue is Timestamp) {
        return timestampValue.toDate();
      }

      // Handle String timestamp
      if (timestampValue is String) {
        try {
          return DateTime.parse(timestampValue);
        } catch (_) {
          return DateTime.now();
        }
      }

      // Fallback
      return DateTime.now();
    }

    return AppUser(
      id: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? map['display_name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == (map['role'] ?? 'staff'),
        orElse: () => UserRole.staff,
      ),
      createdAt: parseTimestamp(map['createdAt'] ?? map['created_at']),
      lastLoginAt: parseTimestamp(map['lastLoginAt'] ?? map['last_login_at']),
      isActive: _convertToBool(map['isActive'] ?? map['is_active'] ?? true),
      profilePhotoPath:
          map['profilePhotoPath'] ?? map['profile_photo_path'] ?? '',
      phone: map['phone'] ?? '',
      emailNotificationsEnabled: _convertToBool(
          map['emailNotificationsEnabled'] ??
              map['email_notifications_enabled'] ??
              true),
      smsNotificationsEnabled: _convertToBool(map['smsNotificationsEnabled'] ??
          map['sms_notifications_enabled'] ??
          true),
      expiryAlertsEnabled: _convertToBool(
          map['expiryAlertsEnabled'] ?? map['expiry_alerts_enabled'] ?? true),
      stockAlertsEnabled: _convertToBool(
          map['stockAlertsEnabled'] ?? map['stock_alerts_enabled'] ?? true),
      predictionAlertsEnabled: _convertToBool(map['predictionAlertsEnabled'] ??
          map['prediction_alerts_enabled'] ??
          true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.toString().split('.').last,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'isActive': isActive,
      'profilePhotoPath': profilePhotoPath,
      'phone': phone,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'smsNotificationsEnabled': smsNotificationsEnabled,
      'expiryAlertsEnabled': expiryAlertsEnabled,
      'stockAlertsEnabled': stockAlertsEnabled,
      'predictionAlertsEnabled': predictionAlertsEnabled,
    };
  }

  // JSON serialization methods for offline storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isActive': isActive,
      'profilePhotoPath': profilePhotoPath,
      'phone': phone,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'smsNotificationsEnabled': smsNotificationsEnabled,
      'expiryAlertsEnabled': expiryAlertsEnabled,
      'stockAlertsEnabled': stockAlertsEnabled,
      'predictionAlertsEnabled': predictionAlertsEnabled,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.staff,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : DateTime.now(),
      isActive: _convertToBool(json['isActive'] ?? true),
      profilePhotoPath: json['profilePhotoPath'],
      phone: json['phone'] ?? '',
      emailNotificationsEnabled:
          _convertToBool(json['emailNotificationsEnabled'] ?? true),
      smsNotificationsEnabled:
          _convertToBool(json['smsNotificationsEnabled'] ?? true),
      expiryAlertsEnabled: _convertToBool(json['expiryAlertsEnabled'] ?? true),
      stockAlertsEnabled: _convertToBool(json['stockAlertsEnabled'] ?? true),
      predictionAlertsEnabled:
          _convertToBool(json['predictionAlertsEnabled'] ?? true),
    );
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
    String? phone,
    bool? emailNotificationsEnabled,
    bool? smsNotificationsEnabled,
    bool? expiryAlertsEnabled,
    bool? stockAlertsEnabled,
    bool? predictionAlertsEnabled,
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
      phone: phone ?? this.phone,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      smsNotificationsEnabled:
          smsNotificationsEnabled ?? this.smsNotificationsEnabled,
      expiryAlertsEnabled: expiryAlertsEnabled ?? this.expiryAlertsEnabled,
      stockAlertsEnabled: stockAlertsEnabled ?? this.stockAlertsEnabled,
      predictionAlertsEnabled:
          predictionAlertsEnabled ?? this.predictionAlertsEnabled,
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

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final bool isAdmin;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.isAdmin = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      isAdmin: data['isAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
