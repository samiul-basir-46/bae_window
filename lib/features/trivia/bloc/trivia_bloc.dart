import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/trivia_service.dart';
import 'trivia_event.dart';
import 'trivia_state.dart';

class TriviaBloc extends Bloc<TriviaEvent, TriviaState> {
  final TriviaService _triviaService;
  StreamSubscription? _subscription;

  TriviaBloc({TriviaService? triviaService})
      : _triviaService = triviaService ?? TriviaService(),
        super(const TriviaInitial()) {
    on<WatchTriviaEvent>(_onWatchTrivia);
    on<TriviaUpdatedEvent>(_onTriviaUpdated);
    on<SubmitTriviaAnswerEvent>(_onSubmitTriviaAnswer);
  }

  void _onWatchTrivia(
    WatchTriviaEvent event,
    Emitter<TriviaState> emit,
  ) {
    emit(const TriviaLoading());
    _subscription?.cancel();
    _subscription = _triviaService.watchTrivia(event.coupleId, event.dateYmd).listen(
      (trivia) {
        add(TriviaUpdatedEvent(trivia));
      },
      onError: (e) {
        add(const TriviaUpdatedEvent(null));
      },
    );
  }

  void _onTriviaUpdated(
    TriviaUpdatedEvent event,
    Emitter<TriviaState> emit,
  ) {
    emit(TriviaLoaded(event.trivia));
  }

  Future<void> _onSubmitTriviaAnswer(
    SubmitTriviaAnswerEvent event,
    Emitter<TriviaState> emit,
  ) async {
    emit(const TriviaSubmitting());
    try {
      await _triviaService.submitAnswer(
        event.coupleId,
        event.dateYmd,
        event.questionText,
        event.uid,
        event.answer,
      );
      emit(const TriviaSuccess("Answer submitted successfully!"));
    } catch (e) {
      emit(TriviaFailure("Failed to submit answer: $e"));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
