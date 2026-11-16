import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_qr_token.dart';

class QrTokenState extends Equatable {
  /// One-time code to show; null until the first one arrives.
  final String? code;

  /// When the current code stops working.
  final DateTime? expiresAt;

  /// The last refresh failed (no network); the shown code may be the
  /// permanent one, which works for cashback but not for spending points.
  final bool offline;

  const QrTokenState({this.code, this.expiresAt, this.offline = false});

  bool get hasLiveCode =>
      code != null && expiresAt != null && expiresAt!.isAfter(DateTime.now());

  @override
  List<Object?> get props => [code, expiresAt, offline];
}

/// Keeps a fresh one-time QR code while the loyalty card is on screen.
///
/// The code is refreshed shortly before it expires, and again whenever the
/// app comes back to the foreground. Timers stop while the app is paused.
class QrTokenCubit extends Cubit<QrTokenState> {
  final GetQrToken getQrToken;
  Timer? _timer;
  bool _paused = false;

  /// Refresh this long before expiry so the cashier never scans a dead code.
  static const _refreshMargin = Duration(seconds: 15);
  static const _retryDelay = Duration(seconds: 10);

  QrTokenCubit({required this.getQrToken}) : super(const QrTokenState());

  Future<void> start() async {
    _paused = false;
    await _refresh();
  }

  void pause() {
    _paused = true;
    _timer?.cancel();
  }

  Future<void> _refresh() async {
    _timer?.cancel();
    final result = await getQrToken();
    if (isClosed || _paused) return;

    result.fold(
      (_) {
        emit(QrTokenState(
          code: state.hasLiveCode ? state.code : null,
          expiresAt: state.hasLiveCode ? state.expiresAt : null,
          offline: true,
        ));
        _schedule(_retryDelay);
      },
      (token) {
        emit(QrTokenState(
          code: token.code,
          expiresAt: DateTime.now().add(token.validFor),
        ));
        final next = token.validFor - _refreshMargin;
        _schedule(next > _retryDelay ? next : _retryDelay);
      },
    );
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _refresh);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
