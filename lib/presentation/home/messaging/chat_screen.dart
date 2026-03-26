import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/messaging_bloc/messaging_bloc.dart';
import '../../../bloc/messaging_bloc/messaging_events.dart';
import '../../../bloc/messaging_bloc/messaging_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../injection_container.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = sl<SessionManager>().getUser()?.id ?? '';
    sl<MessagingBloc>().add(StreamMessagesEvent(widget.conversation.id));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      if (widget.conversation.status == ConversationStatus.pending) {
        _showLockedDialogue();
        return;
      }
      sl<MessagingBloc>().add(SendMessageEvent(
        conversationId: widget.conversation.id,
        content: content,
      ));
      _messageController.clear();
      HapticFeedback.lightImpact();
      _scrollToBottom();
    }
  }

  void _showLockedDialogue() {
     showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        final baseTheme = sl<ThemeBloc>().state.baseTheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: baseTheme.background,
              borderRadius: BorderRadius.circular(AppConstants.radius20Px),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Chat Locked'.tr(),
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font18Px,
                    fontWeight: FontWeight.w700,
                    color: baseTheme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This donor initiated contact. Full chat will be unlocked once you accept their offer of help in the request details.'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font14Px,
                    fontWeight: FontWeight.w400,
                    color: baseTheme.textColor.fixedOpacity(0.55),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: baseTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text('Got it'.tr()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = sl<ThemeBloc>().state.baseTheme;

    return Scaffold(
      backgroundColor: baseTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: baseTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
             Stack(
               children: [
                 Container(
                   width: 38,
                   height: 38,
                   decoration: BoxDecoration(
                     color: baseTheme.primary.withOpacity(0.1),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(Icons.person_rounded, color: baseTheme.primary, size: 20),
                 ),
                 if (widget.conversation.status != ConversationStatus.pending)
                   Positioned(
                     right: 0,
                     bottom: 0,
                     child: Container(
                       width: 10,
                       height: 10,
                       decoration: BoxDecoration(
                         color: Colors.green,
                         shape: BoxShape.circle,
                         border: Border.all(color: Colors.white, width: 2),
                       ),
                     ),
                   ),
               ],
             ),
             const SizedBox(width: 12),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   'Chat Help'.tr(),
                   style: TextStyle(
                     fontFamily: AppConstants.fontFamilyLato,
                     fontSize: AppConstants.font16Px,
                     fontWeight: FontWeight.w700,
                     color: baseTheme.textColor,
                   ),
                 ),
                 Text(
                    widget.conversation.status == ConversationStatus.pending ? 'Pending Acceptance' : 'Active Connection',
                   style: TextStyle(
                     fontFamily: AppConstants.fontFamilyLato,
                     fontSize: AppConstants.font12Px,
                     fontWeight: FontWeight.w400,
                     color: baseTheme.textColor.fixedOpacity(0.4),
                   ),
                 ),
               ],
             ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: baseTheme.textColor.fixedOpacity(0.4)),
            onPressed: () {}, 
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<MessagingBloc, MessagingState>(
              bloc: sl<MessagingBloc>(),
              builder: (context, state) {
                if (state is MessagesLoaded) {
                  final messages = state.messages;
                  _scrollToBottom();
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == _currentUserId;
                      final showTime = index == 0 || 
                          msg.createdAt.difference(messages[index-1].createdAt).inMinutes > 30;
                      
                      return _MessageBubble(
                        message: msg,
                        isMe: isMe,
                        baseTheme: baseTheme,
                        showTimestampHeader: showTime,
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          _ChatInputArea(
            controller: _messageController,
            onSend: _sendMessage,
            baseTheme: baseTheme,
            isLocked: widget.conversation.status == ConversationStatus.pending,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final BaseTheme baseTheme;
  final bool showTimestampHeader;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.baseTheme,
    this.showTimestampHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTimestampHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
               _formatHeaderText(message.createdAt),
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: baseTheme.textColor.fixedOpacity(0.35),
                letterSpacing: 0.5,
              ),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              gradient: isMe 
                  ? LinearGradient(
                      colors: [baseTheme.primary, baseTheme.primary.withRed(baseTheme.primary.red + 20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isMe ? null : baseTheme.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isMe ? 0.1 : 0.04),
                  blurRadius: 10,
                  offset: isMe ? const Offset(0, 4) : const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    color: isMe ? Colors.white : baseTheme.textColor,
                    fontSize: AppConstants.font14Px,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    color: (isMe ? Colors.white : baseTheme.textColor).fixedOpacity(0.4),
                    fontSize: AppConstants.font10Px,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatHeaderText(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today'.toUpperCase();
    }
    return DateFormat('MMM dd, yyyy').format(dt).toUpperCase();
  }
}

class _ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final BaseTheme baseTheme;
  final bool isLocked;

  const _ChatInputArea({
    required this.controller,
    required this.onSend,
    required this.baseTheme,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: baseTheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: baseTheme.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: baseTheme.disable.withOpacity(0.08)),
              ),
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontFamily: AppConstants.fontFamilyLato,
                  fontSize: AppConstants.font14Px,
                  color: baseTheme.textColor,
                ),
                decoration: InputDecoration(
                  hintText: isLocked ? 'Chat Locked'.tr() : 'Message...'.tr(),
                  hintStyle: TextStyle(
                    color: baseTheme.textColor.fixedOpacity(0.3),
                    fontSize: AppConstants.font14Px,
                  ),
                  border: InputBorder.none,
                  enabled: !isLocked,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLocked 
                      ? [baseTheme.disable, baseTheme.disable] 
                      : [baseTheme.primary, baseTheme.primary.withRed(baseTheme.primary.red + 30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: isLocked ? null : [
                  BoxShadow(
                    color: baseTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isLocked ? Icons.lock_rounded : Icons.send_rounded, 
                color: Colors.white, 
                size: 20
              ),
            ),
          ),
        ],
      ),
    );
  }
}
