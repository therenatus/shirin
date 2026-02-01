import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/create_order_params.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _authLocalDatasource;

  OrdersRepositoryImpl(this._remoteDatasource, this._authLocalDatasource);

  Future<bool> get _isTestMode async {
    final token = await _authLocalDatasource.getAccessToken();
    return token == 'test-access-token';
  }

  @override
  Future<Either<Failure, List<Order>>> getOrders() async {
    if (await _isTestMode) {
      return Right(_getMockOrders());
    }
    try {
      final models = await _remoteDatasource.getOrders();
      return Right(models.map((m) => m.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrderById(String id) async {
    if (await _isTestMode) {
      final orders = _getMockOrders();
      final order = orders.firstWhere(
        (o) => o.id == id,
        orElse: () => orders.first,
      );
      return Right(order);
    }
    try {
      final model = await _remoteDatasource.getOrderById(id);
      return Right(model.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Order>> createOrder(CreateOrderParams params) async {
    if (await _isTestMode) {
      // Return mock created order for test mode
      final mockOrder = OrderModel(
        id: 'order-${DateTime.now().millisecondsSinceEpoch}',
        orderNumber: 'SH-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        status: 'pending',
        items: const [],
        totalSum: 0,
        createdAt: DateTime.now(),
      ).toEntity();
      return Right(mockOrder);
    }
    try {
      final model = await _remoteDatasource.createOrder(params);
      return Right(model.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  List<Order> _getMockOrders() {
    return [
      OrderModel(
        id: 'order-1',
        orderNumber: 'SH-001245',
        status: 'delivered',
        items: const [
          OrderItemModel(
            productId: 'p1',
            name: 'Торт Наполеон',
            price: 850,
            quantity: 1,
          ),
          OrderItemModel(
            productId: 'p2',
            name: 'Эклеры (3 шт)',
            price: 350,
            quantity: 2,
          ),
        ],
        totalSum: 1550,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        address: 'ул. Киевская, 120',
      ).toEntity(),
      OrderModel(
        id: 'order-2',
        orderNumber: 'SH-001246',
        status: 'preparing',
        items: const [
          OrderItemModel(
            productId: 'p3',
            name: 'Чизкейк Нью-Йорк',
            price: 750,
            quantity: 1,
          ),
        ],
        totalSum: 750,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        address: 'ул. Московская, 55',
      ).toEntity(),
      OrderModel(
        id: 'order-3',
        orderNumber: 'SH-001247',
        status: 'pending',
        items: const [
          OrderItemModel(
            productId: 'p4',
            name: 'Макаруны (6 шт)',
            price: 420,
            quantity: 1,
          ),
          OrderItemModel(
            productId: 'p5',
            name: 'Круассан с шоколадом',
            price: 180,
            quantity: 3,
          ),
        ],
        totalSum: 960,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ).toEntity(),
    ];
  }
}
