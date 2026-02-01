import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/create_address_params.dart';
import '../../domain/repositories/addresses_repository.dart';
import '../datasources/addresses_remote_datasource.dart';
import '../models/address_model.dart';

class AddressesRepositoryImpl implements AddressesRepository {
  final AddressesRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _authLocalDatasource;

  AddressesRepositoryImpl(this._remoteDatasource, this._authLocalDatasource);

  Future<bool> get _isTestMode async {
    final token = await _authLocalDatasource.getAccessToken();
    return token == 'test-access-token';
  }

  @override
  Future<Either<Failure, List<Address>>> getAddresses() async {
    if (await _isTestMode) {
      return Right(_getMockAddresses());
    }
    try {
      final models = await _remoteDatasource.getAddresses();
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Address>> getAddressById(String id) async {
    if (await _isTestMode) {
      final addresses = _getMockAddresses();
      final address = addresses.firstWhere(
        (a) => a.id == id,
        orElse: () => addresses.first,
      );
      return Right(address);
    }
    try {
      final model = await _remoteDatasource.getAddressById(id);
      return Right(model.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Address>> createAddress(CreateAddressParams params) async {
    if (await _isTestMode) {
      final mockAddress = AddressModel(
        id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
        name: params.name,
        street: params.street,
        apartment: params.apartment,
        entrance: params.entrance,
        floor: params.floor,
        intercom: params.intercom,
        latitude: params.latitude,
        longitude: params.longitude,
        isDefault: params.isDefault ?? false,
      ).toEntity();
      return Right(mockAddress);
    }
    try {
      final model = await _remoteDatasource.createAddress(params);
      return Right(model.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Address>> updateAddress(
      String id, UpdateAddressParams params) async {
    if (await _isTestMode) {
      final addresses = _getMockAddresses();
      final existingAddress = addresses.firstWhere(
        (a) => a.id == id,
        orElse: () => addresses.first,
      );
      final updatedAddress = Address(
        id: existingAddress.id,
        name: params.name ?? existingAddress.name,
        street: params.street ?? existingAddress.street,
        apartment: params.apartment ?? existingAddress.apartment,
        entrance: params.entrance ?? existingAddress.entrance,
        floor: params.floor ?? existingAddress.floor,
        intercom: params.intercom ?? existingAddress.intercom,
        latitude: params.latitude ?? existingAddress.latitude,
        longitude: params.longitude ?? existingAddress.longitude,
        isDefault: existingAddress.isDefault,
      );
      return Right(updatedAddress);
    }
    try {
      final model = await _remoteDatasource.updateAddress(id, params);
      return Right(model.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAddress(String id) async {
    if (await _isTestMode) {
      return const Right(null);
    }
    try {
      await _remoteDatasource.deleteAddress(id);
      return const Right(null);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Address>> setDefaultAddress(String id) async {
    if (await _isTestMode) {
      final addresses = _getMockAddresses();
      final address = addresses.firstWhere(
        (a) => a.id == id,
        orElse: () => addresses.first,
      );
      return Right(Address(
        id: address.id,
        name: address.name,
        street: address.street,
        apartment: address.apartment,
        entrance: address.entrance,
        floor: address.floor,
        intercom: address.intercom,
        latitude: address.latitude,
        longitude: address.longitude,
        isDefault: true,
      ));
    }
    try {
      final model = await _remoteDatasource.setDefaultAddress(id);
      return Right(model.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  List<Address> _getMockAddresses() {
    return const [
      Address(
        id: 'addr-1',
        name: 'Дом',
        street: 'ул. Киевская, 120',
        apartment: '45',
        entrance: '2',
        floor: '5',
        isDefault: true,
      ),
      Address(
        id: 'addr-2',
        name: 'Работа',
        street: 'пр. Чуй, 55',
        apartment: '301',
        floor: '3',
        isDefault: false,
      ),
    ];
  }
}
