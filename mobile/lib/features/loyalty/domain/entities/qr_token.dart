import 'package:equatable/equatable.dart';

/// One-time code for the QR shown at the cash desk. Spending points in a
/// store requires it, so it is short-lived and refreshed by the app.
class QrToken extends Equatable {
  final String code;
  final Duration validFor;

  const QrToken({required this.code, required this.validFor});

  @override
  List<Object?> get props => [code, validFor];
}
