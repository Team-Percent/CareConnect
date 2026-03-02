part of 'chat_bloc.dart';

abstract class ChatEvent {
  const ChatEvent();
}

/// Initialize the chat — check model availability and load medical context.
class ChatStarted extends ChatEvent {
  const ChatStarted();
}

/// User sends a message.
class ChatMessageSent extends ChatEvent {
  final String message;
  const ChatMessageSent({required this.message});
}

/// Clear all messages and reset the chat.
class ChatCleared extends ChatEvent {
  const ChatCleared();
}

/// Dispose model when leaving the chat page.
class ChatDisposed extends ChatEvent {
  const ChatDisposed();
}
