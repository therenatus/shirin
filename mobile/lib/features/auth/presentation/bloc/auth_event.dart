import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class SendCodeRequested extends AuthEvent {
  final String phone;

  const SendCodeRequested(this.phone);

  @override
  List<Object?> get props => [phone];
}

class VerifyCodeRequested extends AuthEvent {
  final String phone;
  final String code;

  const VerifyCodeRequested({required this.phone, required this.code});

  @override
  List<Object?> get props => [phone, code];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
