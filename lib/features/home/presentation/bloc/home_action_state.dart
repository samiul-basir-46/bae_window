abstract class HomeActionState {
  const HomeActionState();
}

class HomeActionInitial extends HomeActionState {
  const HomeActionInitial();
}

class HomeActionLoading extends HomeActionState {
  final String message;

  const HomeActionLoading(this.message);
}

class HomeActionSuccess extends HomeActionState {
  final String message;

  const HomeActionSuccess(this.message);
}

class HomeActionFailure extends HomeActionState {
  final String message;

  const HomeActionFailure(this.message);
}
