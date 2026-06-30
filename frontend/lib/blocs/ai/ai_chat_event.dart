/// AI Chat Events
library;

import 'package:equatable/equatable.dart';

abstract class AiChatEvent extends Equatable {
  const AiChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessage extends AiChatEvent {
  final String message;
  const SendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class ClearChat extends AiChatEvent {
  const ClearChat();
}

class CheckAiHealth extends AiChatEvent {
  const CheckAiHealth();
}
