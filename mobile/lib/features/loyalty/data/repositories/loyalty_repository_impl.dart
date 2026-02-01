import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/loyalty_info.dart';
import '../../domain/entities/loyalty_transaction.dart';
import '../../domain/entities/punch_card.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../datasources/loyalty_remote_datasource.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final LoyaltyRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _authLocalDatasource;

  LoyaltyRepositoryImpl(this._remoteDatasource, this._authLocalDatasource);

  Future<bool> get _isTestMode async {
    final token = await _authLocalDatasource.getAccessToken();
    return token == 'test-access-token';
  }

  @override
  Future<Either<Failure, LoyaltyInfo>> getLoyaltyInfo() async {
    if (await _isTestMode) {
      return const Right(LoyaltyInfo(
        points: 150,
        qrCode: 'SHIRIN-LOYALTY-TEST-USER-ID',
        level: 'Silver',
      ));
    }
    try {
      final model = await _remoteDatasource.getLoyaltyInfo();
      return Right(model.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<LoyaltyTransaction>>> getLoyaltyHistory() async {
    if (await _isTestMode) {
      return Right(_getMockHistory());
    }
    try {
      final models = await _remoteDatasource.getLoyaltyHistory();
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  List<LoyaltyTransaction> _getMockHistory() {
    return [
      LoyaltyTransaction(
        id: 'lt-1',
        amount: 50,
        type: LoyaltyTransactionType.earned,
        date: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Покупка: Торт Наполеон',
      ),
      LoyaltyTransaction(
        id: 'lt-2',
        amount: 30,
        type: LoyaltyTransactionType.spent,
        date: DateTime.now().subtract(const Duration(days: 3)),
        description: 'Скидка на заказ',
      ),
      LoyaltyTransaction(
        id: 'lt-3',
        amount: 80,
        type: LoyaltyTransactionType.earned,
        date: DateTime.now().subtract(const Duration(days: 7)),
        description: 'Покупка: Чизкейк + Эклеры',
      ),
      LoyaltyTransaction(
        id: 'lt-4',
        amount: 50,
        type: LoyaltyTransactionType.earned,
        date: DateTime.now().subtract(const Duration(days: 14)),
        description: 'Бонус за регистрацию',
      ),
    ];
  }

  @override
  Future<Either<Failure, List<PunchCard>>> getPunchCards() async {
    if (await _isTestMode) {
      return Right(_getMockPunchCards());
    }
    try {
      final models = await _remoteDatasource.getPunchCards();
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, PunchCard>> claimFreeCoffee(CoffeeSize size) async {
    if (await _isTestMode) {
      return Left(const ServerFailure('Test mode: cannot claim'));
    }
    try {
      final model = await _remoteDatasource.claimFreeCoffee(size.name);
      return Right(model.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  List<PunchCard> _getMockPunchCards() {
    return [
      PunchCard(
        id: 'pc-s',
        size: CoffeeSize.S,
        sizeName: 'Кофе S',
        currentPunches: 3,
        maxPunches: 6,
        isComplete: false,
        freeItemClaimed: false,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      PunchCard(
        id: 'pc-m',
        size: CoffeeSize.M,
        sizeName: 'Кофе M',
        currentPunches: 6,
        maxPunches: 6,
        isComplete: true,
        freeItemClaimed: false,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      PunchCard(
        id: 'pc-l',
        size: CoffeeSize.L,
        sizeName: 'Кофе L',
        currentPunches: 1,
        maxPunches: 6,
        isComplete: false,
        freeItemClaimed: false,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }
}
