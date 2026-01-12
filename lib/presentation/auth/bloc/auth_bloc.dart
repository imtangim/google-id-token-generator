import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/auth/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
    : _repository = repository,
      super(const AuthState.unknown()) {
    on<_AuthUserChanged>(_onAuthUserChanged);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthRefreshRequested>(_onRefresh);

    _subscription = _repository.authStateChanges().listen((user) {
      add(_AuthUserChanged(user));
    });
  }

  final AuthRepository _repository;
  StreamSubscription<User?>? _subscription;

  Future<void> _onAuthUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user == null) {
      emit(const AuthState.signedOut());
    } else {
      emit(AuthState.signedIn(event.user!));
    }
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isBusy: true, errorMessage: null));
    try {
      await _repository.signInWithGoogle();
    } catch (e, stackTrace) {
      debugPrint('Sign-in error: $e');
      debugPrint('Stack trace: $stackTrace');
      emit(state.copyWith(isBusy: false, errorMessage: e.toString()));
      return;
    }
    emit(state.copyWith(isBusy: false));
  }

  Future<void> _onRefresh(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isBusy: true, errorMessage: null));
    try {
      await _repository.refreshTokens();
    } catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.toString()));
      return;
    }
    emit(state.copyWith(isBusy: false));
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isBusy: true, errorMessage: null));
    try {
      await _repository.signOut();
    } catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.toString()));
      return;
    }
    emit(state.copyWith(isBusy: false));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
