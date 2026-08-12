import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';

class AiChatConversationPage extends StatefulWidget {
  const AiChatConversationPage({super.key, this.launchArgs});

  final AiChatLaunchArgs? launchArgs;

  @override
  State<AiChatConversationPage> createState() => _AiChatConversationPageState();
}

class _AiChatConversationPageState extends State<AiChatConversationPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiSuggestedAction> _quickActions = [];
  List<AiChatMessageItem> _messages = const [];
  String? _conversationId;
  String _title = 'SkinSync AI';
  String? _safetyWarning;
  String? _entryPoint;
  String? _referenceId;
  String? _prefillContext;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.launchArgs?.conversationId;
    _entryPoint = widget.launchArgs?.entryPoint;
    _referenceId = widget.launchArgs?.referenceId;
    _prefillContext = widget.launchArgs?.prefillContext;
    if ((widget.launchArgs?.prefillMessage ?? '').trim().isNotEmpty) {
      _controller.text = widget.launchArgs!.prefillMessage!;
    }
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
        entryPoint: _entryPoint,
        referenceId: _referenceId,
        prefillContext: _prefillContext,
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
          AppLocale.of(context, listen: false).tr('ai_chat_error');
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
      resizeToAvoidBottomInset: true,
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
            : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.maxContentWidth(
                      context,
                      mobile: double.infinity,
                      tablet: 760,
                      desktop: 960,
                    ),
                  ),
                  child: Column(
                    children: [
                      if ((_safetyWarning ?? '').trim().isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.fromLTRB(
                            Responsive.responsiveHorizontalPadding(context),
                            8,
                            Responsive.responsiveHorizontalPadding(context),
                            0,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _safetyWarning!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF8E4E18)),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            Responsive.responsiveHorizontalPadding(context),
                            14,
                            Responsive.responsiveHorizontalPadding(context),
                            12,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isUser = message.isUser;
                            final maxBubbleWidth =
                                Responsive.responsiveValue<double>(
                                  context,
                                  mobileSmall:
                                      MediaQuery.sizeOf(context).width * 0.85,
                                  mobile:
                                      MediaQuery.sizeOf(context).width * 0.82,
                                  tablet: 520,
                                  desktop: 600,
                                );
                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: maxBubbleWidth,
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppColors.primaryDark
                                      : Colors.white.withValues(alpha: 0.96),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: SelectableText(
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
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  Responsive.responsiveHorizontalPadding(
                                    context,
                                  ),
                            ),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final action = _quickActions[index];
                              return ActionChip(
                                label: Text(action.label),
                                onPressed: () => _handleAction(action),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemCount: _quickActions.length,
                          ),
                        ),
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          Responsive.responsiveHorizontalPadding(context),
                          10,
                          Responsive.responsiveHorizontalPadding(context),
                          16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          border: Border(
                            top: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final stack = constraints.maxWidth < 360;
                            final field = TextField(
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
                            );
                            final sendButton = FilledButton(
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
                            );

                            if (stack) {
                              return Column(
                                children: [
                                  field,
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: sendButton,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: field),
                                const SizedBox(width: 10),
                                sendButton,
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _handleAction(AiSuggestedAction action) async {
    if (action.route.isEmpty) {
      return;
    }

    if (action.route == AppRoutes.aiIngredientCheck ||
        action.route == AppRoutes.routine ||
        action.route == AppRoutes.progress ||
        action.route == AppRoutes.upload ||
        action.route == AppRoutes.aiReports) {
      await Navigator.pushNamed(context, action.route);
      return;
    }

    if (action.route == AppRoutes.products) {
      await Navigator.pushNamed(
        context,
        AppRoutes.aiProductRecommend,
        arguments: ProductsPageArgs(referenceId: action.referenceId),
      );
    }
  }
}
