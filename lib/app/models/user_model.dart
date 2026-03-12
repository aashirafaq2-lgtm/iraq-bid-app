class UserModel {
  final int id;
  final String name;
  final String? email;
  final String phone;
  final String role;
  final String status;
  final String? city;
  final String? area;
  final String? referralCode;
  final int? bidsCount;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.city,
    this.area,
    this.referralCode,
    this.bidsCount,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      city: json['city'] as String?,
      area: json['area'] as String?,
      referralCode: json['referral_code'] as String?,
      bidsCount: json['bids_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'city': city,
      'area': area,
      'referral_code': referralCode,
      'bids_count': bidsCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

