import 'package:bloc/bloc.dart';
import 'package:health_wallet/features/chat/domain/entities/chat_message.dart';
import 'package:health_wallet/features/chat/domain/services/chat_inference_service.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

part 'chat_event.dart';
part 'chat_state.dart';

@Injectable()
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatInferenceService _chatService;

  ChatBloc(this._chatService) : super(const ChatState()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatCleared>(_onChatCleared);
    on<ChatDisposed>(_onChatDisposed);
  }

  bool _isFirstMessage = true;

  Future<void> _onChatStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.modelChecking));
    try {
      final available = await _chatService.isModelAvailable();
      if (!available) {
        emit(state.copyWith(status: ChatStatus.modelAbsent));
        return;
      }

      emit(state.copyWith(status: ChatStatus.modelLoading));
      await _chatService.initChat();
      _isFirstMessage = true;

      // Add a welcome message from the AI
      final welcomeMessage = ChatMessage(
        id: const Uuid().v4(),
        content:
            'Hello! I\'m your AI medical assistant. I\'ve reviewed your medical records and I\'m ready to help answer your health questions.\n\n'
            '⚕️ **Please note:** I provide general information based on your records. Always consult your doctor for medical decisions.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        status: ChatStatus.ready,
        messages: [welcomeMessage],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to initialize: ${e.toString()}',
      ));
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state.status == ChatStatus.generating) return;

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    emit(state.copyWith(
      status: ChatStatus.generating,
      messages: updatedMessages,
    ));

    try {
      final response = await _chatService.sendMessage(
        event.message,
        isFirstMessage: _isFirstMessage,
      );
      _isFirstMessage = false;

      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        status: ChatStatus.ready,
        messages: [...updatedMessages, aiMessage],
      ));
    } catch (e) {
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        content: '⚠️ Sorry, I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        status: ChatStatus.ready,
        messages: [...updatedMessages, errorMessage],
        error: e.toString(),
      ));
    }
  }

  Future<void> _onChatCleared(
    ChatCleared event,
    Emitter<ChatState> emit,
  ) async {
    _isFirstMessage = true;
    emit(state.copyWith(
      status: ChatStatus.ready,
      messages: [],
    ));
  }

  Future<void> _onChatDisposed(
    ChatDisposed event,
    Emitter<ChatState> emit,
  ) async {
    await _chatService.disposeChat();
    _isFirstMessage = true;
    emit(const ChatState());
  }

  @override
  Future<void> close() {
    _chatService.disposeChat();
    return super.close();
  }
}
