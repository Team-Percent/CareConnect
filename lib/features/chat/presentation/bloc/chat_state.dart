part of 'chat_bloc.dart';

enum ChatStatus {
  initial,
  modelChecking,
  modelAbsent,
  modelLoading,
  ready,
  generating,
  error,
}

class ChatState {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final String? error;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.error,
  });

  bool get isModelReady =>
      status == ChatStatus.ready || status == ChatStatus.generating;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? error,
  }) =>
      ChatState(
        status: status ?? this.status,
        messages: messages ?? this.messages,
        error: error,
      );
}
