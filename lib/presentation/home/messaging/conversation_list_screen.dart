import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/messaging_bloc/messaging_bloc.dart';
import '../../../bloc/messaging_bloc/messaging_events.dart';
import '../../../bloc/messaging_bloc/messaging_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../data/models/conversation_model.dart';
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
  @override
  void initState() {
    super.initState();
    sl<MessagingBloc>().add(StreamConversationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = sl<ThemeBloc>().state.baseTheme;

    return Scaffold(
      backgroundColor: baseTheme.background,
      appBar: AppBar(
        title: Text(
          'Messages'.tr(),
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
          if (state is MessagingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ConversationsLoaded) {
            final conversations = state.conversations;
            if (conversations.isEmpty) {
              return _buildEmptyState(baseTheme);
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return _ConversationCard(
                  conversation: conv,
                  baseTheme: baseTheme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(conversation: conv),
                      ),
                    );
                  },
                );
              },
            );
          }
          if (state is MessagingError) {
             return Center(child: Text(state.message));
          }
          return Center(child: Text('Something went wrong'.tr()));
        },
      ),
    );
  }

  Widget _buildEmptyState(BaseTheme baseTheme) {
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
            'No conversations yet'.tr(),
            style: TextStyle(
              fontFamily: AppConstants.fontFamilyLato,
              fontSize: AppConstants.font18Px,
              fontWeight: FontWeight.w600,
              color: baseTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your messages and help requests will appear here.'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font14Px,
                color: baseTheme.textColor.fixedOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ConversationModel conversation;
  final BaseTheme baseTheme;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conversation,
    required this.baseTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = conversation.requestId != null ? 'Help Request Offer' : 'Donor Contact';
    final subtitle = conversation.lastMessage ?? 'No messages yet';
    final isUnread = conversation.status == ConversationStatus.pending;

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
                Stack(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            baseTheme.primary.withOpacity(0.15),
                            baseTheme.primary.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: baseTheme.primary,
                        size: 28,
                      ),
                    ),
                    if (isUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
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
                              title,
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
                      const SizedBox(height: 6),
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
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: baseTheme.textColor.fixedOpacity(0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dt);
    } else if (difference.inDays < 7) {
      return DateFormat('E').format(dt);
    } else {
      return DateFormat('dd/MM').format(dt);
    }
  }
}
