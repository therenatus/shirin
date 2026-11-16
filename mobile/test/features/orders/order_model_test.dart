import 'package:flutter_test/flutter_test.dart';
import 'package:shirin_app/features/orders/data/models/order_model.dart';
import 'package:shirin_app/features/orders/domain/entities/order.dart';
import 'package:shirin_app/features/products/data/models/product_model.dart';

void main() {
  test('OrderModel reads the backend shape (formatOrder)', () {
    final order = OrderModel.fromJson({
      'id': 'o1',
      'orderNumber': 'SHR-20261117-0001',
      'status': 'DELIVERING',
      'deliveryType': 'delivery',
      'deliveryTime': '2026-11-19T10:00:00.000Z',
      'comment': 'Без орехов',
      'subtotal': 2500,
      'deliveryFee': 150,
      'pointsUsed': 100,
      'total': 2550,
      'pointsEarned': 120,
      'paymentStatus': 'PENDING',
      'prepaymentAmount': 1250,
      'paymentDueAt': '2026-11-17T12:00:00.000Z',
      'createdAt': '2026-11-17T11:00:00.000Z',
      'items': [
        {
          'id': 'i1',
          'quantity': 1,
          'price': 2500,
          'total': 2500,
          'inscription': 'С днём рождения!',
          'wishes': null,
          'referencePhotoUrl': null,
          'product': {'id': 'p1', 'name': 'Торт', 'nameRu': 'Торт на заказ', 'images': ['u']},
        },
      ],
      'address': {'id': 'a1', 'name': 'Дом', 'street': 'ул. Киевская, 1', 'apartment': '5'},
      'store': null,
    }).toEntity();

    expect(order.status, OrderStatus.delivering);
    expect(order.totalSum, 2550);
    expect(order.address, 'ул. Киевская, 1, кв. 5');
    expect(order.isDelivery, isTrue);
    expect(order.paymentStatus, PaymentStatus.pending);
    expect(order.prepaymentAmount, 1250);
    expect(order.items.single.productId, 'p1');
    expect(order.items.single.name, 'Торт на заказ');
    expect(order.items.single.inscription, 'С днём рождения!');
  });

  test('ProductModel: the customer pays discountPrice, price is the old one', () {
    final p = ProductModel.fromJson({
      'id': 'p1',
      'name': 'Эклер',
      'price': '200',
      'discountPrice': '150',
      'isPreorder': true,
      'leadTimeHours': 48,
    }).toEntity();
    expect(p.price, 150);
    expect(p.oldPrice, 200);
    expect(p.hasDiscount, isTrue);
    expect(p.isPreorder, isTrue);
    expect(p.leadTimeHours, 48);

    final plain = ProductModel.fromJson({'id': 'p2', 'name': 'Чай', 'price': 80, 'discountPrice': null}).toEntity();
    expect(plain.price, 80);
    expect(plain.oldPrice, isNull);
  });
}
