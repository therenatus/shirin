import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shirin_app/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:shirin_app/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:shirin_app/features/cart/presentation/bloc/cart_event.dart';
import 'package:shirin_app/features/cart/presentation/bloc/cart_state.dart';
import 'package:shirin_app/features/products/domain/entities/product.dart';

void main() {
  const cake = Product(id: 'cake', name: 'Торт на заказ', price: 2500, isPreorder: true, leadTimeHours: 48);
  const eclair = Product(id: 'e', name: 'Эклер', price: 150);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<CartLoaded> run(List<CartEvent> events) async {
    final bloc = CartBloc(CartLocalDatasource());
    for (final e in events) {
      bloc.add(e);
      await bloc.stream.first;
    }
    final state = bloc.state as CartLoaded;
    await bloc.close();
    return state;
  }

  test('plain items merge into one line', () async {
    final s = await run([const AddToCart(eclair), const AddToCart(eclair, quantity: 2)]);
    expect(s.items, hasLength(1));
    expect(s.items.single.quantity, 3);
    expect(s.items.single.lineId, 'e');
  });

  test('cakes with different inscriptions stay separate and survive a reload', () async {
    final s = await run([
      const AddToCart(cake, inscription: 'Аня'),
      const AddToCart(cake, inscription: 'Боря'),
      const AddToCart(eclair),
    ]);
    expect(s.items, hasLength(3));
    final cakeLines = s.items.where((i) => i.product.id == 'cake').toList();
    expect(cakeLines.map((i) => i.inscription), ['Аня', 'Боря']);
    expect(cakeLines[0].lineId, isNot(cakeLines[1].lineId));

    final reloaded = await CartLocalDatasource().getCartItems();
    expect(reloaded.where((i) => i.product.isPreorder).map((i) => i.inscription), ['Аня', 'Боря']);
    expect(reloaded.firstWhere((i) => i.product.id == 'cake').product.leadTimeHours, 48);
  });

  test('removing one custom cake keeps the other', () async {
    final bloc = CartBloc(CartLocalDatasource());
    bloc.add(const AddToCart(cake, inscription: 'Аня'));
    await bloc.stream.first;
    bloc.add(const AddToCart(cake, inscription: 'Боря'));
    final added = await bloc.stream.first as CartLoaded;
    bloc.add(RemoveFromCart(added.items.first.lineId));
    final after = await bloc.stream.first as CartLoaded;
    expect(after.items.single.inscription, 'Боря');
    await bloc.close();
  });
}
