import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/messaging_bloc/messaging_bloc.dart';
import '../../../bloc/messaging_bloc/messaging_events.dart';
import '../../../bloc/messaging_bloc/messaging_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../injection_container.dart';
import 'chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  late String _currentUserId;
  bool _showingRequests = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = sl<SessionManager>().getUser()?.id ?? '';
    sl<MessagingBloc>().add(StreamConversationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = sl<ThemeBloc>().state.baseTheme;

    return Scaffold(
      backgroundColor: baseTheme.background,
      appBar: AppBar(
        leading: _showingRequests 
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: baseTheme.textColor),
                onPressed: () => setState(() => _showingRequests = false),
              )
            : null,
        title: Text(
          (_showingRequests ? ViewConstants.requests : ViewConstants.messages).tr(),
          style: TextStyle(
            fontFamily: AppConstants.fontFamilyLato,
            fontSize: AppConstants.font20Px,
            fontWeight: FontWeight.w700,
            color: baseTheme.textColor,
          ),
        ),
        backgroundColor: baseTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: BlocBuilder<MessagingBloc, MessagingState>(
        bloc: sl<MessagingBloc>(),
        builder: (context, state) {
          if (state.isLoading && state.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final allConversations = state.conversations;
          
          final chats = allConversations.where((c) => 
            c.status == ConversationStatus.accepted || 
            (c.status == ConversationStatus.pending && c.initiatorId == _currentUserId)
          ).toList();
          
          final requests = allConversations.where((c) => 
            c.status == ConversationStatus.pending && c.recipientId == _currentUserId
          ).toList();

          if (_showingRequests) {
            return _buildRequestList(requests, baseTheme);
          }

          if (state.error != null && allConversations.isEmpty) {
             return Center(child: Text(state.error!));
          }

          return _buildMainList(chats, requests.length, baseTheme);
        },
      ),
    );
  }

  Widget _buildMainList(List<ConversationModel> conversations, int requestCount, BaseTheme baseTheme) {
    final hasConversations = conversations.isNotEmpty || requestCount > 0;
    
    if (!hasConversations) {
      return _buildEmptyState(baseTheme, ViewConstants.noActiveChats);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: (requestCount > 0 ? 1 : 0) + conversations.length,
      itemBuilder: (context, index) {
        if (requestCount > 0 && index == 0) {
          return _MessageRequestsCard(
            count: requestCount,
            baseTheme: baseTheme,
            onTap: () => setState(() => _showingRequests = true),
          );
        }

        final convIndex = requestCount > 0 ? index - 1 : index;
        final conv = conversations[convIndex];
        return _ConversationCard(
          conversation: conv,
          baseTheme: baseTheme,
          currentUserId: _currentUserId,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestList(List<ConversationModel> requests, BaseTheme baseTheme) {
    if (requests.isEmpty) {
      return _buildEmptyState(baseTheme, ViewConstants.noMessageRequests);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final conv = requests[index];
        return _RequestCard(
          conversation: conv,
          baseTheme: baseTheme,
          currentUserId: _currentUserId,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BaseTheme baseTheme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: baseTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: baseTheme.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message.tr(),
            style: TextStyle(
              fontFamily: AppConstants.fontFamilyLato,
              fontSize: AppConstants.font18Px,
              fontWeight: FontWeight.w600,
              color: baseTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageRequestsCard extends StatelessWidget {
  final int count;
  final BaseTheme baseTheme;
  final VoidCallback onTap;

  const _MessageRequestsCard({
    required this.count,
    required this.baseTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: baseTheme.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        shadowColor: Colors.black.withOpacity(0.05),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radius16Px),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.move_to_inbox_rounded, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ViewConstants.messageRequests.tr(),
                        style: TextStyle(
                          fontFamily: AppConstants.fontFamilyLato,
                          fontSize: AppConstants.font14Px,
                          fontWeight: FontWeight.w700,
                          color: baseTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count ${count > 1 ? ViewConstants.requests.tr() : ViewConstants.requests.tr().substring(0, ViewConstants.requests.tr().length - 1)}',
                        style: TextStyle(
                          fontFamily: AppConstants.fontFamilyLato,
                          fontSize: AppConstants.font13Px,
                          color: baseTheme.textColor.fixedOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: baseTheme.textColor.fixedOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ConversationModel conversation;
  final BaseTheme baseTheme;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conversation,
    required this.baseTheme,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = conversation.initiatorId == currentUserId 
        ? (conversation.recipientName ?? ViewConstants.message.tr()) 
        : (conversation.initiatorName ?? ViewConstants.message.tr());
    
    final subtitle = conversation.lastMessage ?? ViewConstants.noMessages.tr();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: baseTheme.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        shadowColor: Colors.black.withOpacity(0.05),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radius16Px),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: baseTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,),
                  alignment: Alignment.center,
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontFamily: AppConstants.fontFamilyLato,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: baseTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              otherName,
                              style: TextStyle(
                                fontFamily: AppConstants.fontFamilyLato,
                                fontSize: AppConstants.font14Px,
                                fontWeight: FontWeight.w700,
                                color: baseTheme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(conversation.updatedAt),
                            style: TextStyle(
                              fontFamily: AppConstants.fontFamilyLato,
                              fontSize: AppConstants.font10Px,
                              color: baseTheme.textColor.fixedOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppConstants.fontFamilyLato,
                          fontSize: AppConstants.font13Px,
                          color: baseTheme.textColor.fixedOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }
}

class _RequestCard extends StatelessWidget {
  final ConversationModel conversation;
  final BaseTheme baseTheme;
  final String currentUserId;
  final VoidCallback onTap;

  const _RequestCard({
    required this.conversation,
    required this.baseTheme,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = conversation.initiatorId == currentUserId 
        ? (conversation.recipientName ?? ViewConstants.message.tr()) 
        : (conversation.initiatorName ?? ViewConstants.message.tr());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: baseTheme.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        shadowColor: Colors.black.withOpacity(0.04),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radius16Px),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,),
                      alignment: Alignment.center,
                      child: Text(
                        otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontFamily: AppConstants.fontFamilyLato,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange,
                        ),
                      ),
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
                              fontSize: AppConstants.font14Px,
                              fontWeight: FontWeight.w700,
                              color: baseTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateFormat('MMM dd, HH:mm').format(conversation.createdAt),
                            style: TextStyle(
                              fontFamily: AppConstants.fontFamilyLato,
                              fontSize: AppConstants.font10Px,
                              color: baseTheme.textColor.fixedOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  conversation.lastMessage ?? ViewConstants.donorWantsToHelp.tr(),
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font13Px,
                    color: baseTheme.textColor.fixedOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: baseTheme.background,
                              title: Text(
                                'Decline Request',
                                style: TextStyle(color: baseTheme.textColor, fontFamily: AppConstants.fontFamilyLato, fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                'Are you sure you want to decline this request?',
                                style: TextStyle(color: baseTheme.textColor, fontFamily: AppConstants.fontFamilyLato),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(ViewConstants.cancel.tr(), style: TextStyle(color: baseTheme.textColor.withOpacity(0.6))),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: Text(ViewConstants.decline.tr(), style: const TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            sl<MessagingBloc>().add(DeclineConversationEvent(conversation.id));
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(ViewConstants.decline.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: baseTheme.background,
                              title: Text(
                                'Accept Request',
                                style: TextStyle(color: baseTheme.textColor, fontFamily: AppConstants.fontFamilyLato, fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                'Are you sure you want to accept this request?',
                                style: TextStyle(color: baseTheme.textColor, fontFamily: AppConstants.fontFamilyLato),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(ViewConstants.cancel.tr(), style: TextStyle(color: baseTheme.textColor.withOpacity(0.6))),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: baseTheme.primary),
                                  child: Text(ViewConstants.accept.tr(), style: const TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            sl<MessagingBloc>().add(AcceptConversationEvent(conversation.id));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: baseTheme.primary,
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
      ),
    );
  }
}
