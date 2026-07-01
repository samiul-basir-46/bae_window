import '../models/trivia_model.dart';

abstract class TriviaState {
  const TriviaState();
}

class TriviaInitial extends TriviaState {
  const TriviaInitial();
}

class TriviaLoading extends TriviaState {
  const TriviaLoading();
}

class TriviaLoaded extends TriviaState {
  final TriviaModel? trivia;

  const TriviaLoaded(this.trivia);
}

class TriviaSubmitting extends TriviaState {
  const TriviaSubmitting();
}

class TriviaSuccess extends TriviaState {
  final String message;

  const TriviaSuccess(this.message);
}

class TriviaFailure extends TriviaState {
  final String error;

  const TriviaFailure(this.error);
}
