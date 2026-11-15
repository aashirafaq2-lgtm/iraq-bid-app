class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String? message;
  final int? userId;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    this.message,
    this.userId,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Safely parse created_at
    DateTime createdAt;
    try {
      if (json['created_at'] is String) {
        createdAt = DateTime.parse(json['created_at'] as String);
      } else if (json['created_at'] is DateTime) {
        createdAt = json['created_at'] as DateTime;
      } else {
        // Fallback to current time if parsing fails
        createdAt = DateTime.now();
      }
    } catch (e) {
      print('Warning: Failed to parse created_at: ${json['created_at']}, using current time');
      createdAt = DateTime.now();
    }
    
    // Handle both 'read' and 'is_read' fields from backend
    final bool isRead = json['is_read'] as bool? ?? json['read'] as bool? ?? false;
    
    return NotificationModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String?,
      userId: json['user_id'] as int?,
      read: isRead,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'user_id': userId,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

