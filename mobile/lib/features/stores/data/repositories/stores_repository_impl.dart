import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/stores_repository.dart';
import '../datasources/stores_remote_datasource.dart';

class StoresRepositoryImpl implements StoresRepository {
  final StoresRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _authLocalDatasource;

  StoresRepositoryImpl(this._remoteDatasource, this._authLocalDatasource);

  Future<bool> get _isTestMode async {
    final token = await _authLocalDatasource.getAccessToken();
    return token == 'test-access-token';
  }

  @override
  Future<Either<Failure, List<Store>>> getStores() async {
    if (await _isTestMode) {
      return Right(_getMockStores());
    }
    try {
      final models = await _remoteDatasource.getStores();
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  List<Store> _getMockStores() {
    return const [
      Store(
        id: 'store-1',
        name: 'Ширин — Центр',
        address: 'ул. Киевская, 120',
        phone: '+996 312 123 456',
        lat: 42.8746,
        lng: 74.5698,
        workingHours: '08:00 - 21:00',
      ),
      Store(
        id: 'store-2',
        name: 'Ширин — Юг',
        address: 'ул. Ахунбаева, 85',
        phone: '+996 312 654 321',
        lat: 42.8560,
        lng: 74.5820,
        workingHours: '09:00 - 22:00',
      ),
      Store(
        id: 'store-3',
        name: 'Ширин — Восток',
        address: 'пр. Жибек Жолу, 200',
        phone: '+996 312 789 012',
        lat: 42.8780,
        lng: 74.6100,
        workingHours: '08:00 - 20:00',
      ),
    ];
  }
}
