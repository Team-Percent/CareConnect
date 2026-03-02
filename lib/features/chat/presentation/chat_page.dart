import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_wallet/core/di/injection.dart';
import 'package:health_wallet/core/navigation/app_router.dart';
import 'package:health_wallet/core/theme/app_insets.dart';
import 'package:health_wallet/core/theme/app_text_style.dart';
import 'package:health_wallet/core/utils/build_context_extension.dart';
import 'package:health_wallet/core/widgets/custom_app_bar.dart';
import 'package:health_wallet/features/chat/domain/entities/chat_message.dart';
import 'package:health_wallet/features/chat/presentation/bloc/chat_bloc.dart';

/// Tab 3 — AI Medical Chat
@RoutePage()
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatBloc _chatBloc;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatBloc = getIt<ChatBloc>();
    _chatBloc.add(const ChatStarted());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _chatBloc.add(const ChatDisposed());
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _chatBloc.add(ChatMessageSent(message: text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'AI Assistant',
          automaticallyImplyLeading: false,
          actions: [
            BlocBuilder<ChatBloc, ChatState>(
              builder: (ctx, state) {
                if (!state.isModelReady) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(Icons.refresh_outlined,
                      color: context.colorScheme.onSurface),
                  onPressed: () => _chatBloc.add(const ChatCleared()),
                  tooltip: 'New conversation',
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state.messages.isNotEmpty) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            switch (state.status) {
              case ChatStatus.initial:
              case ChatStatus.modelChecking:
                return _buildLoading(context, 'Checking AI model...');

              case ChatStatus.modelAbsent:
                return _buildModelAbsent(context);

              case ChatStatus.modelLoading:
                return _buildLoading(context, 'Loading AI model...');

              case ChatStatus.error:
                return _buildError(context, state.error ?? 'Unknown error');

              case ChatStatus.ready:
              case ChatStatus.generating:
                return _buildChat(context, state);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: context.colorScheme.primary,
            ),
          ),
          const SizedBox(height: Insets.medium),
          Text(
            message,
            style: AppTextStyle.bodyMedium.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelAbsent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 56,
                color: context.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: Insets.large),
            Text(
              'AI Model Required',
              style: AppTextStyle.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Insets.small),
            Text(
              'Download the Gemma AI model to use the medical assistant.\nGo to Settings → AI Model to start the download.',
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySmall.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: Insets.large),
            FilledButton.icon(
              onPressed: () async {
                final result = await context.router.push(LoadModelRoute());
                if (result == true && mounted) {
                  _chatBloc.add(const ChatStarted());
                }
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download AI Model'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: Insets.small),
            TextButton.icon(
              onPressed: () => _chatBloc.add(const ChatStarted()),
              icon: const Icon(Icons.refresh_outlined, size: 16),
              label: const Text('Check Again'),
              style: TextButton.styleFrom(
                foregroundColor:
                    context.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: context.colorScheme.error),
            const SizedBox(height: Insets.medium),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySmall.copyWith(
                color: context.colorScheme.error,
              ),
            ),
            const SizedBox(height: Insets.medium),
            FilledButton(
              onPressed: () => _chatBloc.add(const ChatStarted()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat(BuildContext context, ChatState state) {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: state.messages.isEmpty
              ? _buildEmptyChat(context)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                      Insets.normal, Insets.small, Insets.normal, Insets.small),
                  itemCount: state.messages.length +
                      (state.status == ChatStatus.generating ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.messages.length) {
                      return _buildTypingIndicator(context);
                    }
                    return _ChatBubble(
                      message: state.messages[index],
                    );
                  },
                ),
        ),

        // Input bar
        _buildInputBar(context, state),
      ],
    );
  }

  Widget _buildEmptyChat(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: context.colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          const SizedBox(height: Insets.medium),
          Text(
            'Ask me about your health records',
            style: AppTextStyle.bodyMedium.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8, right: 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Thinking...',
              style: AppTextStyle.bodySmall.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ChatState state) {
    final isGenerating = state.status == ChatStatus.generating;

    return Container(
      padding: EdgeInsets.fromLTRB(
        Insets.normal,
        Insets.small,
        Insets.small,
        MediaQuery.of(context).padding.bottom + Insets.small + 60,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: context.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 1,
                enabled: !isGenerating,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: AppTextStyle.bodySmall.copyWith(
                  color: context.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: isGenerating
                      ? 'AI is responding...'
                      : 'Ask about your health...',
                  hintStyle: AppTextStyle.bodySmall.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            child: IconButton(
              onPressed: isGenerating ? null : _sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: isGenerating
                    ? context.colorScheme.primary.withValues(alpha: 0.3)
                    : context.colorScheme.primary,
                foregroundColor: context.colorScheme.onPrimary,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              icon: Icon(
                isGenerating ? Icons.hourglass_top : Icons.send_rounded,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 6,
          bottom: 6,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? context.colorScheme.primary
              : context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            if (!context.isDarkMode)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 12,
                      color: context.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Assistant',
                      style: AppTextStyle.labelSmall.copyWith(
                        color:
                            context.colorScheme.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            SelectableText(
              message.content,
              style: AppTextStyle.bodySmall.copyWith(
                color: isUser
                    ? context.colorScheme.onPrimary
                    : context.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: AppTextStyle.labelSmall.copyWith(
                color: isUser
                    ? context.colorScheme.onPrimary.withValues(alpha: 0.6)
                    : context.colorScheme.onSurface.withValues(alpha: 0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
