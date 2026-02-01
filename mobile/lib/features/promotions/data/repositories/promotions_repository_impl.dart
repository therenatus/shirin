import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/repositories/promotions_repository.dart';
import '../datasources/promotions_remote_datasource.dart';

class PromotionsRepositoryImpl implements PromotionsRepository {
  final PromotionsRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _authLocalDatasource;

  PromotionsRepositoryImpl(this._remoteDatasource, this._authLocalDatasource);

  Future<bool> get _isTestMode async {
    final token = await _authLocalDatasource.getAccessToken();
    return token == 'test-access-token';
  }

  @override
  Future<Either<Failure, List<Promotion>>> getPromotions() async {
    if (await _isTestMode) {
      return Right(_getMockPromotions());
    }
    try {
      final models = await _remoteDatasource.getPromotions();
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  List<Promotion> _getMockPromotions() {
    return [
      Promotion(
        id: 'promo-1',
        title: 'Скидка 20% на торты',
        description:
            'Только до конца месяца! Скидка 20% на все торты при заказе от 1500 сом.',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 25)),
        isActive: true,
      ),
      Promotion(
        id: 'promo-2',
        title: '2+1 на эклеры',
        description:
            'Купите 2 набора эклеров и получите третий в подарок! Акция действует ежедневно.',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 14)),
        isActive: true,
      ),
      Promotion(
        id: 'promo-3',
        title: 'День рождения с Ширин',
        description:
            'Закажите торт на день рождения и получите набор макарунов в подарок. Укажите дату рождения в профиле.',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 60)),
        isActive: true,
      ),
    ];
  }
}
