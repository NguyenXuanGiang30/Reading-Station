/// AI Chat BLoC
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/ai_service.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AiService _aiService = AiService();

  AiChatBloc() : super(const AiChatInitial()) {
    on<CheckAiHealth>(_onCheckHealth);
    on<SendMessage>(_onSendMessage);
    on<ClearChat>(_onClearChat);
  }

  Future<void> _onCheckHealth(
    CheckAiHealth event,
    Emitter<AiChatState> emit,
  ) async {
    final health = await _aiService.checkHealth();
    final available = health['available'] == true;
    emit(AiChatLoaded(
      messages: List.from(state.messages),
      isAiAvailable: available,
    ));
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AiChatState> emit,
  ) async {
    // Add user message
    final userMsg = ChatMessage(role: 'user', content: event.message);
    final updatedMessages = List<ChatMessage>.from(state.messages)..add(userMsg);

    emit(AiChatLoading(
      messages: updatedMessages,
      isAiAvailable: state.isAiAvailable,
    ));

    try {
      // Build history for context
      final history = updatedMessages
          .where((m) => m != userMsg)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final result = await _aiService.chat(event.message, history: history);

      final aiMsg = ChatMessage(
        role: 'assistant',
        content: result['reply'] as String,
        actions: result['actions'] as List<ActionResult>?,
      );
      final allMessages = List<ChatMessage>.from(updatedMessages)..add(aiMsg);

      emit(AiChatLoaded(
        messages: allMessages,
        isAiAvailable: true,
      ));
    } catch (e) {
      emit(AiChatError(
        errorMessage: e.toString(),
        messages: updatedMessages,
        isAiAvailable: state.isAiAvailable,
      ));
    }
  }

  void _onClearChat(ClearChat event, Emitter<AiChatState> emit) {
    emit(AiChatLoaded(
      messages: [],
      isAiAvailable: state.isAiAvailable,
    ));
  }
}
