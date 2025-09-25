part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final User? user;
  @override
  List<Object?> get props => [user?.uid];
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested();
}

class AuthRefreshRequested extends AuthEvent {
  const AuthRefreshRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
