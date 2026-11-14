class SupportConversation {
  final int convId;
  final String custId;
  final String subject;
  final String? category;
  final String status;
  final String? assignedAgent;
  final int unreadCustomer;
  final int unreadAgent;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastMessagePreview;

  SupportConversation({
    required this.convId,
    required this.custId,
    required this.subject,
    this.category,
    required this.status,
    this.assignedAgent,
    this.unreadCustomer = 0,
    this.unreadAgent = 0,
    this.lastMessageAt,
    required this.createdAt,
    this.updatedAt,
    this.lastMessagePreview,
  });

  factory SupportConversation.fromJson(Map<String, dynamic> json) {
    return SupportConversation(
      convId: _asInt(json['conv_id'] ?? json['convId']),
      custId: (json['cust_id'] ?? json['custId'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      category: json['category']?.toString(),
      status: (json['status'] ?? 'open').toString(),
      assignedAgent: json['assigned_agent']?.toString() ??
          json['assignedAgent']?.toString(),
      unreadCustomer: _asInt(
        json['unread_customer'] ?? json['unreadCustomer'] ?? 0,
      ),
      unreadAgent: _asInt(json['unread_agent'] ?? json['unreadAgent'] ?? 0),
      lastMessageAt: _asDateTime(
        json['last_message_at'] ?? json['lastMessageAt'],
      ),
      createdAt:
          _asDateTime(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      updatedAt: _asDateTime(json['updated_at'] ?? json['updatedAt']),
      lastMessagePreview: json['last_message_preview']?.toString() ??
          json['lastMessagePreview']?.toString(),
    );
  }

  bool get hasUnread => unreadCustomer > 0;
  bool get isClosed => status == 'closed';
}

class SupportMessage {
  final int msgId;
  final int convId;
  final String senderType;
  final String? senderId;
  final String body;
  final String? attachmentUrl;
  final DateTime createdAt;
  final DateTime? readAt;

  SupportMessage({
    required this.msgId,
    required this.convId,
    required this.senderType,
    this.senderId,
    required this.body,
    this.attachmentUrl,
    required this.createdAt,
    this.readAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      msgId: _asInt(json['msg_id'] ?? json['msgId']),
      convId: _asInt(json['conv_id'] ?? json['convId']),
      senderType: (json['sender_type'] ?? json['senderType'] ?? 'system')
          .toString(),
      senderId: json['sender_id']?.toString() ?? json['senderId']?.toString(),
      body: (json['body'] ?? '').toString(),
      attachmentUrl: json['attachment_url']?.toString() ??
          json['attachmentUrl']?.toString(),
      createdAt:
          _asDateTime(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      readAt: _asDateTime(json['read_at'] ?? json['readAt']),
    );
  }

  bool get isMine => senderType == 'customer';
  bool get hasImage =>
      attachmentUrl != null && attachmentUrl!.trim().isNotEmpty;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is num) {
    final n = value.toDouble();
    if (n > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(n.toInt());
    }
    return DateTime.fromMillisecondsSinceEpoch((n * 1000).toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
