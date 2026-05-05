class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String severity;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? payload;
  final String? screenRoute;
  final String? icon;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
    this.payload,
    this.screenRoute,
    this.icon,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      severity: json['severity'] ?? 'info',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      payload: json['payload'],
      screenRoute: json['screenRoute'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'payload': payload,
      'screenRoute': screenRoute,
      'icon': icon,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? severity,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? payload,
    String? screenRoute,
    String? icon,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
      screenRoute: screenRoute ?? this.screenRoute,
      icon: icon ?? this.icon,
    );
  }
}

class NotificationType {
  static const String toolLife = 'tool_life';
  static const String stockMonitoring = 'stock_monitoring';
  static const String processStatus = 'process_status';
  static const String systemAlert = 'system_alert';
  static const String userMessage = 'user_message';
}

class NotificationSeverity {
  static const String critical = 'critical';
  static const String warning = 'warning';
  static const String info = 'info';
  static const String success = 'success';
}