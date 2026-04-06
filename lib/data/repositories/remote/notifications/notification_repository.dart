import '../../../managers/remote/firebase_notification_service.dart';
import '../../../managers/remote/supabase_service.dart';
import '../../../models/conversation_model.dart';
import '../../../models/blood_request_model.dart';
import '../../../models/user_model.dart';

class NotificationRepository {
  final FirebaseNotificationService _notificationService;
  final SupabaseService _supabaseService;

  NotificationRepository(this._notificationService, this._supabaseService);

  Future<void> sendBloodRequestStatusNotification({
    required String recipientId,
    required String requestPatientName,
    required BloodRequestStatus status,
  }) async {
    final recipient = await _supabaseService.getUserById(recipientId);
    final token = recipient?.fcmToken;
    if (token == null || token.isEmpty) return;

    String title = 'Blood Request Update';
    String body = '';

    switch (status) {
      case BloodRequestStatus.inProgress:
        body = 'Someone has offered to help with your request for $requestPatientName!';
        break;
      case BloodRequestStatus.fulfilled:
        body = 'Your blood request for $requestPatientName has been marked as completed.';
        break;
      case BloodRequestStatus.cancelled:
        body = 'A blood request you were involved in ($requestPatientName) has been cancelled.';
        break;
      default:
        return;
    }

    await _notificationService.sendPushNotification(
      recipientToken: token,
      title: title,
      body: body,
      data: {
        'type': 'blood_request_status',
        'status': status.name,
      },
    );
  }

  Future<void> sendMessageRequestNotification({
    required String recipientId,
    required String senderName,
    String? requestId,
  }) async {
    final recipient = await _supabaseService.getUserById(recipientId);
    final token = recipient?.fcmToken;
    if (token == null || token.isEmpty) return;

    await _notificationService.sendPushNotification(
      recipientToken: token,
      title: 'New Message Request',
      body: '$senderName wants to chat with you.',
      data: {
        'type': 'message_request',
        'requestId': requestId ?? '',
      },
    );
  }

  Future<void> sendMessageApprovedNotification({
    required String recipientId,
    required String senderName,
  }) async {
    final recipient = await _supabaseService.getUserById(recipientId);
    final token = recipient?.fcmToken;
    if (token == null || token.isEmpty) return;

    await _notificationService.sendPushNotification(
      recipientToken: token,
      title: 'Chat Request Approved',
      body: '$senderName accepted your chat request. You can now message each other.',
      data: {
        'type': 'message_approved',
      },
    );
  }
}
