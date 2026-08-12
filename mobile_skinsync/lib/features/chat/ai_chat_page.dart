import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/models/app_models.dart';
import '../../core/responsive/responsive.dart';
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
    final locale = AppLocale.of(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: GlassHeader(
        currentRoute: AppRoutes.aiChat,
        title: 'SkinSync AI',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _NewChatButton(
              label: locale.tr('ai_chat_new'),
              onPressed: _newChat,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(
                context,
                mobile: double.infinity,
                tablet: 760,
                desktop: 960,
              ),
            ),
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
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load chat sessions',
                      body:
                          context.read<AppState>().errorMessage ??
                          'Please try again in a moment.',
                    );
                  }

                  final conversations = snapshot.data ?? const [];
                  if (conversations.isEmpty) {
                    return _StateMessage(
                      icon: Icons.forum_outlined,
                      title: locale.tr('ai_chat_no_conversations'),
                      body: locale.tr('ai_chat_start'),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      Responsive.responsiveHorizontalPadding(context),
                      18,
                      Responsive.responsiveHorizontalPadding(context),
                      Responsive.contentBottomSpacing(context, extra: 18),
                    ),
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
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemCount: conversations.length,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: const Icon(Icons.add_comment_outlined, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
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
    final preview = (item.lastMessagePreview ?? 'No messages yet.').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.aiSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.7),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.trim().isEmpty ? 'SkinSync AI' : item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(item.lastMessageAt),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceStrong,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    if (isToday) {
      return 'Hôm nay $hour:$minute';
    }

    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Responsive.responsiveHorizontalPadding(context),
        80,
        Responsive.responsiveHorizontalPadding(context),
        24,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.84)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.aiSoft,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 26),
              ),
              const SizedBox(height: 16),
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
