import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shirin_app/core/error/failures.dart';
import 'package:shirin_app/features/loyalty/data/models/loyalty_transaction_model.dart';
import 'package:shirin_app/features/loyalty/domain/entities/loyalty_info.dart';
import 'package:shirin_app/features/loyalty/domain/entities/loyalty_transaction.dart';
import 'package:shirin_app/features/loyalty/domain/entities/punch_card.dart';
import 'package:shirin_app/features/loyalty/domain/entities/qr_token.dart';
import 'package:shirin_app/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:shirin_app/features/loyalty/domain/usecases/get_qr_token.dart';
import 'package:shirin_app/features/loyalty/presentation/bloc/qr_token_cubit.dart';

/// Returns the queued results of getQrToken in order.
class _FakeRepo implements LoyaltyRepository {
  final List<Either<Failure, QrToken>> results;
  _FakeRepo(this.results);

  @override
  Future<Either<Failure, QrToken>> getQrToken() async => results.removeAt(0);

  @override
  Future<Either<Failure, LoyaltyInfo>> getLoyaltyInfo() => throw UnimplementedError();
  @override
  Future<Either<Failure, List<LoyaltyTransaction>>> getLoyaltyHistory() =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, List<PunchCard>>> getPunchCards() => throw UnimplementedError();
}

void main() {
  group('LoyaltyTransactionModel', () {
    test('reads the backend shape: signed points and createdAt', () {
      final debit = LoyaltyTransactionModel.fromJson({
        'id': 'tx-1',
        'type': 'used',
        'points': -120,
        'description': 'Оплата баллами',
        'createdAt': '2026-11-16T10:00:00.000Z',
      }).toEntity();
      expect(debit.amount, 120);
      expect(debit.type, LoyaltyTransactionType.spent);

      final refund = LoyaltyTransactionModel.fromJson({
        'id': 'tx-2',
        'type': 'refunded',
        'points': 80,
        'description': null,
        'createdAt': '2026-11-16T10:00:00.000Z',
      }).toEntity();
      expect(refund.type, LoyaltyTransactionType.earned);
      expect(refund.description, '');
    });
  });

  group('QrTokenCubit', () {
    test('shows the one-time code when online', () async {
      final cubit = QrTokenCubit(
        getQrToken: GetQrToken(_FakeRepo([
          const Right(QrToken(code: 'T:abc', validFor: Duration(seconds: 60))),
        ])),
      );
      await cubit.start();
      expect(cubit.state.code, 'T:abc');
      expect(cubit.state.hasLiveCode, isTrue);
      expect(cubit.state.offline, isFalse);
      await cubit.close();
    });

    test('keeps a still-valid code and flags offline when a refresh fails', () async {
      final cubit = QrTokenCubit(
        getQrToken: GetQrToken(_FakeRepo([
          const Right(QrToken(code: 'T:abc', validFor: Duration(seconds: 60))),
          const Left(NetworkFailure()),
        ])),
      );
      await cubit.start();
      await cubit.start(); // e.g. app resumed without network
      expect(cubit.state.code, 'T:abc');
      expect(cubit.state.offline, isTrue);
      await cubit.close();
    });

    test('has no live code when the first request fails', () async {
      final cubit = QrTokenCubit(
        getQrToken: GetQrToken(_FakeRepo([const Left(NetworkFailure())])),
      );
      await cubit.start();
      expect(cubit.state.hasLiveCode, isFalse);
      expect(cubit.state.offline, isTrue);
      await cubit.close();
    });
  });
}
