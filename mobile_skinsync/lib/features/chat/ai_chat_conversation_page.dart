import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';

class AiChatConversationPage extends StatefulWidget {
  const AiChatConversationPage({super.key, this.conversationId});

  final String? conversationId;

  @override
  State<AiChatConversationPage> createState() => _AiChatConversationPageState();
}

class _AiChatConversationPageState extends State<AiChatConversationPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _quickActions = [];
  List<AiChatMessageItem> _messages = const [];
  String? _conversationId;
  String _title = 'SkinSync AI';
  String? _safetyWarning;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_conversationId == null || _conversationId!.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final detail = await context
          .read<AppState>()
          .fetchAiChatConversationDetail(_conversationId!);
      if (!mounted) {
        return;
      }

      setState(() {
        _title = detail.title;
        _messages = detail.messages;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
      _messages = [
        ..._messages,
        AiChatMessageItem(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          role: 'user',
          content: text,
          createdAt: DateTime.now(),
        ),
      ];
      if (overrideText == null) {
        _controller.clear();
      }
    });
    _scrollToBottom();

    try {
      final reply = await context.read<AppState>().sendAiChatInConversation(
        text,
        conversationId: _conversationId,
      );
      if (!mounted) {
        return;
      }

      _conversationId ??= reply.conversationId;
      _quickActions
        ..clear()
        ..addAll(reply.suggestedActions);
      _safetyWarning = reply.safetyWarning;
      setState(() {
        _messages = [
          ..._messages,
          AiChatMessageItem(
            id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: reply.reply,
            createdAt: DateTime.now(),
          ),
        ];
      });

      if (_conversationId != null) {
        final detail = await context
            .read<AppState>()
            .fetchAiChatConversationDetail(_conversationId!);
        if (!mounted) {
          return;
        }

        setState(() {
          _title = detail.title;
          _messages = detail.messages;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      final message =
          context.read<AppState>().errorMessage ??
          'Could not get a reply right now.';
      setState(() {
        _messages = [
          ..._messages,
          AiChatMessageItem(
            id: 'error-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: message,
            createdAt: DateTime.now(),
          ),
        ];
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.foreground,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if ((_safetyWarning ?? '').trim().isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _safetyWarning!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8E4E18),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message.isUser;
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 360),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.primaryDark
                                  : Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              message.content,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isUser
                                        ? Colors.white
                                        : AppColors.foreground,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_quickActions.isNotEmpty)
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final label = _quickActions[index];
                          return ActionChip(
                            label: Text(label),
                            onPressed: () => _sendMessage(label),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: _quickActions.length,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText:
                                  'Ask about your skin, routine, or products...',
                              filled: true,
                              fillColor: AppColors.secondary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _sending ? null : _sendMessage,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            minimumSize: const Size(52, 52),
                          ),
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
