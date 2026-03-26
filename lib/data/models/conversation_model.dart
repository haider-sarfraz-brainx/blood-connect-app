import 'package:equatable/equatable.dart';

enum ConversationStatus {
  pending,
  accepted,
  rejected,
}

extension ConversationStatusX on ConversationStatus {
  String toDbString() => name;

  static ConversationStatus fromString(String value) {
    return ConversationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConversationStatus.pending,
    );
  }
}

class ConversationModel extends Equatable {
  final String id;
  final String initiatorId;
  final String recipientId;
  final String? requestId;
  final ConversationStatus status;
  final String? lastMessage;
  final DateTime updatedAt;
  final DateTime createdAt;

  const ConversationModel({
    required this.id,
    required this.initiatorId,
    required this.recipientId,
    this.requestId,
    this.status = ConversationStatus.pending,
    this.lastMessage,
    required this.updatedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'initiator_id': initiatorId,
      'recipient_id': recipientId,
      'request_id': requestId,
      'status': status.toDbString(),
      'last_message': lastMessage,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] as String,
      initiatorId: map['initiator_id'] as String,
      recipientId: map['recipient_id'] as String,
      requestId: map['request_id'] as String?,
      status: ConversationStatusX.fromString(map['status'] as String),
      lastMessage: map['last_message'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ConversationModel copyWith({
    String? id,
    String? initiatorId,
    String? recipientId,
    String? requestId,
    ConversationStatus? status,
    String? lastMessage,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      initiatorId: initiatorId ?? this.initiatorId,
      recipientId: recipientId ?? this.recipientId,
      requestId: requestId ?? this.requestId,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        initiatorId,
        recipientId,
        requestId,
        status,
        lastMessage,
        updatedAt,
        createdAt,
      ];
}
