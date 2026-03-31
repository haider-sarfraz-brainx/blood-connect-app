import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/messaging_bloc/messaging_bloc.dart';
import '../../../bloc/messaging_bloc/messaging_events.dart';
import '../../../bloc/messaging_bloc/messaging_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../injection_container.dart';
import '../../home/messaging/chat_screen.dart';


class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessagingBloc, MessagingState>(
      bloc: sl<MessagingBloc>(),
      builder: (context, state) {
        final baseTheme = sl<ThemeBloc>().state.baseTheme;
        final blockedConversations = state.conversations
            .where((c) => c.status == ConversationStatus.blocked)
            .toList();

        return Scaffold(
          backgroundColor: baseTheme.background,
          appBar: AppBar(
            backgroundColor: baseTheme.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: baseTheme.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              ViewConstants.blockedUsers.tr(),
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font18Px,
                fontWeight: FontWeight.w700,
                color: baseTheme.textColor,
              ),
            ),
          ),
          body: blockedConversations.isEmpty
              ? _buildEmptyState(baseTheme)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: blockedConversations.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final conv = blockedConversations[index];
                    return _BlockedUserTile(
                      conversation: conv,
                      baseTheme: baseTheme,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(baseTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: baseTheme.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.block_rounded,
              size: 48,
              color: baseTheme.textColor.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No blocked users',
            style: TextStyle(
              fontFamily: AppConstants.fontFamilyLato,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: baseTheme.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Users you have blocked will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: 14,
                color: baseTheme.textColor.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final ConversationModel conversation;
  final dynamic baseTheme;

  const _BlockedUserTile({
    required this.conversation,
    required this.baseTheme,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = sl<SessionManager>().getUser()?.id ?? '';
    final name = conversation.initiatorId == currentUserId
        ? (conversation.recipientName ?? 'User')
        : (conversation.initiatorName ?? 'User');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: baseTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: baseTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: baseTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: baseTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  sl<MessagingBloc>().add(UnblockConversationEvent(conversation.id));
                },
                style: TextButton.styleFrom(
                  foregroundColor: baseTheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Unblock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
