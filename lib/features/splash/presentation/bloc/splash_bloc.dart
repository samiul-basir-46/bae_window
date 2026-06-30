import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(const SplashInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());

    await Future.delayed(const Duration(seconds: 3));

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      emit(const AuthenticatedState());
    } else {
      emit(const UnauthenticatedState());
    }
  }
}
