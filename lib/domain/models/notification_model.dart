class NotificationModel {
  final String? id;
  final String? title;
  final String? message;
  final String? createdAt;
  final bool? isRead;
  final String? bookingRef;
  final String? bookingId;

  NotificationModel({
    this.id,
    this.title,
    this.message,
    this.createdAt,
    this.isRead,
    this.bookingRef,
    this.bookingId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? json['body'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      isRead: (json['is_read'] ?? json['isRead'] ?? (json['status'] == 'read') ?? false) as bool,
      bookingRef: (json['bookingRef'] ?? json['booking_ref'] ?? '').toString(),
      bookingId: json['bookingId']?.toString(),
    );
  }

  static List<NotificationModel> fromList(List<dynamic> list) {
    return list.map((item) => NotificationModel.fromJson(item)).toList();
  }
}
