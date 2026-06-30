/// AI Chat States
library;

import 'package:equatable/equatable.dart';

class ActionResult {
  final String tool;
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ActionResult({
    required this.tool,
    required this.success,
    required this.message,
    this.data,
  });

  factory ActionResult.fromJson(Map<String, dynamic> json) {
    return ActionResult(
      tool: json['tool'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

class ChatMessage {
  final String role; // "user" or "assistant"
  final String content;
  final DateTime timestamp;
  final List<ActionResult>? actions;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.actions,
  }) : timestamp = timestamp ?? DateTime.now();
}

abstract class AiChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isAiAvailable;

  const AiChatState({
    this.messages = const [],
    this.isAiAvailable = false,
  });

  @override
  List<Object?> get props => [messages, isAiAvailable];
}

class AiChatInitial extends AiChatState {
  const AiChatInitial() : super();
}

class AiChatLoading extends AiChatState {
  const AiChatLoading({
    required super.messages,
    required super.isAiAvailable,
  });
}

class AiChatLoaded extends AiChatState {
  const AiChatLoaded({
    required super.messages,
    required super.isAiAvailable,
  });
}

class AiChatError extends AiChatState {
  final String errorMessage;

  const AiChatError({
    required this.errorMessage,
    required super.messages,
    required super.isAiAvailable,
  });

  @override
  List<Object?> get props => [errorMessage, ...super.props];
}
