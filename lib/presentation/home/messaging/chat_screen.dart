import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/messaging_bloc/messaging_bloc.dart';
import '../../../bloc/messaging_bloc/messaging_events.dart';
import '../../../bloc/messaging_bloc/messaging_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
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
    sl<MessagingBloc>().add(StopStreamMessagesEvent());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MessagingBloc, MessagingState>(
      bloc: sl<MessagingBloc>(),
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      },
      builder: (context, state) {
        final conv = state.conversations.firstWhere(
          (c) => c.id == widget.conversation.id,
          orElse: () => widget.conversation,
        );

        final baseTheme = sl<ThemeBloc>().state.baseTheme;

        return Scaffold(
          backgroundColor: baseTheme.background,
          appBar: _buildAppBar(conv, baseTheme),
          body: Column(
            children: [
              Expanded(
                child: _buildMessageList(conv, baseTheme, state),
              ),
              if (conv.status == ConversationStatus.blocked)
                _buildBlockedBanner(conv, baseTheme)
              else
                _ChatInputArea(
                  controller: _messageController,
                  onSend: () => _sendMessage(conv),
                  baseTheme: baseTheme,
                  isLocked: conv.status != ConversationStatus.accepted && conv.recipientId == _currentUserId,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockedBanner(ConversationModel conv, BaseTheme baseTheme) {
    return Container(
      width: double.infinity,
      color: baseTheme.primary.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You blocked this contact. You can\'t message or call each other in this chat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppConstants.fontFamilyLato,
              fontSize: 13,
              color: baseTheme.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _handleMenuAction('unblock', conv),
            style: TextButton.styleFrom(
              foregroundColor: baseTheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ConversationModel conv, BaseTheme baseTheme) {
    final otherName = conv.initiatorId == _currentUserId 
        ? (conv.recipientName ?? ViewConstants.message.tr()) 
        : (conv.initiatorName ?? ViewConstants.message.tr());

    return AppBar(
      titleSpacing: 0,
      backgroundColor: baseTheme.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: baseTheme.textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: baseTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,),
                alignment: Alignment.center,
                child: Text(
                  otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: baseTheme.primary,
                  ),
                ),
              ),
              if (conv.status == ConversationStatus.accepted)
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherName,
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font16Px,
                    fontWeight: FontWeight.w700,
                    color: baseTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getStatusLabel(conv.status),
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font12Px,
                    fontWeight: FontWeight.w400,
                    color: baseTheme.textColor.fixedOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: baseTheme.textColor.fixedOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) => _handleMenuAction(value, conv),
          color: Colors.white,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  const Icon(Icons.report_problem_outlined, size: 20, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text(ViewConstants.reportUser.tr(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            if (conv.status == ConversationStatus.blocked)
              PopupMenuItem(
                value: 'unblock',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 20, color: baseTheme.primary),
                    const SizedBox(width: 12),
                    Text('Unblock', style: TextStyle(color: baseTheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    const Icon(Icons.block_flipped, size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(ViewConstants.blockUser.tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(ViewConstants.deleteChat.tr(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _handleMenuAction(String value, ConversationModel conv) {
    switch (value) {
      case 'report':
        _showReportBottomSheet(conv);
        break;
      case 'block':
        _showConfirmationDialog(
          title: ViewConstants.blockUser,
          content: 'Are you sure you want to block this user?',
          confirmText: 'Block',
          confirmColor: Colors.red,
          onConfirm: () {
            sl<MessagingBloc>().add(BlockConversationEvent(conv.id));
          },
        );
        break;
      case 'unblock':
        _showConfirmationDialog(
          title: 'Unblock User',
          content: 'Are you sure you want to unblock this user?',
          confirmText: 'Unblock',
          confirmColor: sl<ThemeBloc>().state.baseTheme.primary,
          onConfirm: () {
            sl<MessagingBloc>().add(UnblockConversationEvent(conv.id));
          },
        );
        break;
      case 'delete':
        _showConfirmationDialog(
          title: ViewConstants.deleteChat,
          content: 'Are you sure you want to delete this chat? This action cannot be undone and will permanently remove all data from our servers.',
          confirmText: 'Delete Forever',
          confirmColor: Colors.red,
          onConfirm: () {
            sl<MessagingBloc>().add(DeleteConversationEvent(conv.id));
            Navigator.pop(context);
          },
        );
        break;
    }
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmText = 'Confirm',
    Color? confirmColor,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final baseTheme = sl<ThemeBloc>().state.baseTheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: baseTheme.background,
              borderRadius: BorderRadius.circular(AppConstants.radius20Px),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.tr(),
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font18Px,
                    fontWeight: FontWeight.w800,
                    color: baseTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  content.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font14Px,
                    color: baseTheme.textColor.fixedOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          ViewConstants.cancel.tr(),
                          style: TextStyle(
                            color: baseTheme.textColor.fixedOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor ?? baseTheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageList(ConversationModel conv, BaseTheme baseTheme, MessagingState state) {
    if (state.error != null && state.messages.isEmpty) {
      return Center(child: Text(state.error!));
    }

    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final messages = state.messages;
    
    return Column(
      children: [
        if ((conv.status == ConversationStatus.pending || conv.status == ConversationStatus.rejected) && conv.recipientId == _currentUserId)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    ViewConstants.donorWantsToHelp.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppConstants.fontFamilyLato,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _showConfirmationDialog(
                              title: ViewConstants.decline,
                              content: 'Are you sure you want to decline this request?',
                              onConfirm: () {
                                sl<MessagingBloc>().add(DeclineConversationEvent(conv.id));
                              },
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(color: Colors.red.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(ViewConstants.decline.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            sl<MessagingBloc>().add(AcceptConversationEvent(conv.id));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: baseTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(ViewConstants.accept.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg.senderId == _currentUserId;
              final showTime = index == 0 ||
                  msg.createdAt.difference(messages[index - 1].createdAt).inMinutes > 30;

              return _MessageBubble(
                message: msg,
                isMe: isMe,
                baseTheme: baseTheme,
                showTimestampHeader: showTime,
              );
            },
          ),
        ),
      ],
    );
  }

  void _sendMessage(ConversationModel conv) {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      if (conv.status == ConversationStatus.pending) {
        _showLockedDialogue();
        return;
      }
      sl<MessagingBloc>().add(SendMessageEvent(
        conversationId: conv.id,
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
                  ViewConstants.chatLocked.tr(),
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font18Px,
                    fontWeight: FontWeight.w700,
                    color: baseTheme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  ViewConstants.chatLockedSubtitle.tr(),
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
                    child: Text(ViewConstants.gotIt.tr()),
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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showReportBottomSheet(ConversationModel conv) {
    final baseTheme = sl<ThemeBloc>().state.baseTheme;
    String selectedReason = ViewConstants.harassment.tr();
    final reasons = [
      ViewConstants.harassment.tr(),
      ViewConstants.falseInfo.tr(),
      ViewConstants.suspicious.tr(),
      ViewConstants.spam.tr(),
      ViewConstants.other.tr(),
    ];
    final detailsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: baseTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: baseTheme.textColor.fixedOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  ViewConstants.reportUser.tr(),
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font18Px,
                    fontWeight: FontWeight.w700,
                    color: baseTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...reasons.map((reason) => Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      reason,
                      style: TextStyle(
                        fontFamily: AppConstants.fontFamilyLato,
                        fontSize: AppConstants.font14Px,
                        color: baseTheme.textColor,
                      ),
                    ),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: baseTheme.primary,
                    onChanged: (val) => setModalState(() => selectedReason = val!),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                )),
                if (selectedReason == ViewConstants.other.tr())
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: detailsController,
                      style: TextStyle(color: baseTheme.textColor),
                      decoration: InputDecoration(
                        hintText: ViewConstants.reasonPlaceholder.tr(),
                        hintStyle: TextStyle(color: baseTheme.textColor.fixedOpacity(0.4)),
                        fillColor: baseTheme.textColor.fixedOpacity(0.05),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 3,
                    ),
                  ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      sl<MessagingBloc>().add(ReportConversationEvent(
                        conversationId: conv.id,
                        reason: selectedReason,
                        details: selectedReason == ViewConstants.other.tr()
                            ? detailsController.text
                            : null,
                      ));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ViewConstants.reportSuccess.tr()),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: baseTheme.primary,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      ViewConstants.submitReport.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(ConversationStatus status) {
    switch (status) {
      case ConversationStatus.pending:
        return ViewConstants.pendingAcceptance.tr();
      case ConversationStatus.rejected:
        return ViewConstants.rejected.tr();
      case ConversationStatus.accepted:
        return ViewConstants.activeConnection.tr();
      case ConversationStatus.blocked:
        return 'Blocked';
      case ConversationStatus.reported:
        return 'Reported';
    }
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
      return 'TODAY';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'YESTERDAY';
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
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: baseTheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: baseTheme.textColor.fixedOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                enabled: !isLocked,
                style: TextStyle(
                  fontFamily: AppConstants.fontFamilyLato,
                  fontSize: AppConstants.font14Px,
                  color: baseTheme.textColor,
                ),
                decoration: InputDecoration(
                  hintText: isLocked ? 'Wait for acceptance...' : ViewConstants.typeYourMessage.tr(),
                  hintStyle: TextStyle(
                    color: baseTheme.textColor.fixedOpacity(0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isLocked ? null : onSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLocked ? baseTheme.textColor.fixedOpacity(0.1) : baseTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
