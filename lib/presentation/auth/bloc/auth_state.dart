part of 'auth_bloc.dart';

class AuthState extends Equatable {
  const AuthState._({
    required this.user,
    required this.isBusy,
    this.errorMessage,
  });

  const AuthState.unknown() : this._(user: null, isBusy: false);
  const AuthState.signedOut() : this._(user: null, isBusy: false);
  const AuthState.signedIn(User user) : this._(user: user, isBusy: false);

  final User? user;
  final bool isBusy;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, bool? isBusy, String? errorMessage}) {
    return AuthState._(
      user: user ?? this.user,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [user?.uid, isBusy, errorMessage];
}
