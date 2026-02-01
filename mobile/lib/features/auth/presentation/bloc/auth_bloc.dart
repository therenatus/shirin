import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/send_code.dart';
import '../../domain/usecases/verify_code.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendCode _sendCode;
  final VerifyCode _verifyCode;
  final GetCurrentUser _getCurrentUser;
  final Logout _logout;

  AuthBloc({
    required SendCode sendCode,
    required VerifyCode verifyCode,
    required GetCurrentUser getCurrentUser,
    required Logout logout,
  })  : _sendCode = sendCode,
        _verifyCode = verifyCode,
        _getCurrentUser = getCurrentUser,
        _logout = logout,
        super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SendCodeRequested>(_onSendCodeRequested);
    on<VerifyCodeRequested>(_onVerifyCodeRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _getCurrentUser();
    result.fold(
      (failure) => emit(const Unauthenticated()),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSendCodeRequested(
    SendCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _sendCode(event.phone);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(CodeSent(event.phone)),
    );
  }

  Future<void> _onVerifyCodeRequested(
    VerifyCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _verifyCode(event.phone, event.code);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _logout();
    emit(const Unauthenticated());
  }
}
