import 'dart:async';
import 'package:health_wallet/features/scan/data/data_source/network/scan_network_data_source.dart';
import 'package:health_wallet/features/scan/domain/services/ai_model_download_service.dart';
import 'package:health_wallet/features/chat/domain/services/medical_context_builder.dart';
import 'package:injectable/injectable.dart';

/// Manages the on-device Gemma model for interactive chat sessions.
///
/// Unlike the scan pipeline (which disposes the model after each mapping session),
/// the chat service keeps the model loaded for the duration of the conversation.
@LazySingleton()
class ChatInferenceService {
  final ScanNetworkDataSource _dataSource;
  final AiModelDownloadService _downloadService;
  final MedicalContextBuilder _contextBuilder;

  ChatInferenceService(
    this._dataSource,
    this._downloadService,
    this._contextBuilder,
  );

  bool _isModelReady = false;
  String? _medicalContext;

  bool get isModelReady => _isModelReady;

  /// Check if the Gemma model file exists on disk.
  Future<bool> isModelAvailable() async {
    return _downloadService.checkModelExists();
  }

  /// Initialize the model for chat and load medical context.
  Future<void> initChat() async {
    if (_isModelReady) return;

    await _dataSource.initModel();
    _isModelReady = true;

    // Pre-load medical context
    _medicalContext = await _contextBuilder.buildContext();
  }

  /// Send a message and get a response from the model.
  ///
  /// The first message includes the full medical context as a system instruction.
  Future<String> sendMessage(String userMessage,
      {bool isFirstMessage = false}) async {
    if (!_isModelReady) {
      throw StateError('Chat model not initialized. Call initChat() first.');
    }

    String prompt;
    if (isFirstMessage || _medicalContext != null) {
      prompt = _buildPromptWithContext(userMessage);
      // Clear context after first use — subsequent messages are follow-ups
      _medicalContext = null;
    } else {
      prompt = userMessage;
    }

    final response = await _dataSource.runPrompt(prompt: prompt);
    return response ?? 'I could not generate a response. Please try again.';
  }

  String _buildPromptWithContext(String userMessage) {
    final context = _medicalContext ?? 'No medical records available.';
    return '''You are a helpful, empathetic medical assistant for a patient. You have access to the patient's medical records summarized below. Use this information to answer their questions clearly and accurately. Always remind them to consult their doctor for medical decisions.

$context

Patient's question: $userMessage

Please provide a helpful, clear, and compassionate response:''';
  }

  /// Dispose the model after the chat session ends.
  Future<void> disposeChat() async {
    if (!_isModelReady) return;
    _isModelReady = false;
    _medicalContext = null;
    await _dataSource.disposeModel();
  }
}
