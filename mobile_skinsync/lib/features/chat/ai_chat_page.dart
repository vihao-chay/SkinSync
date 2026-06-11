import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_header.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  late Future<List<AiChatConversationSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AiChatConversationSummary>> _load() {
    return context.read<AppState>().fetchAiChatConversations();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _newChat() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.aiChatConversation,
      arguments: const AiChatLaunchArgs(entryPoint: 'chat_sessions'),
    );
    if (mounted) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(
        currentRoute: AppRoutes.aiChat,
        title: 'SkinSync AI',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newChat,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New chat'),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: _refresh,
          child: FutureBuilder<List<AiChatConversationSummary>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _StateMessage(
                  title: 'Could not load chat sessions',
                  body:
                      context.read<AppState>().errorMessage ??
                      'Please try again in a moment.',
                );
              }

              final conversations = snapshot.data ?? const [];
              if (conversations.isEmpty) {
                return const _StateMessage(
                  title: 'No chat sessions yet',
                  body:
                      'Start a new chat to ask about your skin, routine, products, or irritation concerns.',
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
                itemBuilder: (context, index) {
                  final item = conversations[index];
                  return _ConversationTile(
                    item: item,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.aiChatConversation,
                        arguments: AiChatLaunchArgs(
                          conversationId: item.conversationId,
                        ),
                      );
                      if (mounted) {
                        _refresh();
                      }
                    },
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemCount: conversations.length,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item, required this.onTap});

  final AiChatConversationSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                (item.lastMessagePreview ?? 'No messages yet.').trim(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatDate(item.lastMessageAt),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} $hour:$minute';
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
