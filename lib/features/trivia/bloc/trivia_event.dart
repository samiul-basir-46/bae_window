import '../models/trivia_model.dart';

abstract class TriviaEvent {
  const TriviaEvent();
}

class WatchTriviaEvent extends TriviaEvent {
  final String coupleId;
  final String dateYmd;

  const WatchTriviaEvent({required this.coupleId, required this.dateYmd});
}

class TriviaUpdatedEvent extends TriviaEvent {
  final TriviaModel? trivia;

  const TriviaUpdatedEvent(this.trivia);
}

class SubmitTriviaAnswerEvent extends TriviaEvent {
  final String coupleId;
  final String dateYmd;
  final String questionText;
  final String uid;
  final String answer;

  const SubmitTriviaAnswerEvent({
    required this.coupleId,
    required this.dateYmd,
    required this.questionText,
    required this.uid,
    required this.answer,
  });
}
