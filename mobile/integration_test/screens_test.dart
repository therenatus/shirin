import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shirin_app/main.dart' as app;

/// Walks the main screens and saves a screenshot of each.
///
/// Run on the dedicated "Shirin iPhone 18 Pro" simulator (grants location too):
///   scripts/sim.sh drive
///
/// The backend SMS stub accepts code 9999 in development.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pump in fixed steps; pumpAndSettle never returns because of looping
  /// animations (shimmer, pulse, auto-scroll).
  Future<void> settle(WidgetTester tester, [int ms = 1500]) async {
    final steps = ms ~/ 100;
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester, 600);
    // ignore: avoid_print
    print('[screens] shot $name');
    await binding.takeScreenshot(name);
  }

  Future<bool> tapNav(WidgetTester tester, String route) async {
    final finder = find.byKey(ValueKey('nav-$route'));
    if (finder.evaluate().isEmpty) return false;
    await tester.tap(finder.first);
    await settle(tester, 1200);
    return true;
  }

  testWidgets('screens', (tester) async {
    app.main();
    await settle(tester, 4000); // splash

    if (find.text('Получить код').evaluate().isNotEmpty) {
      await shot(tester, '01-login');
      await tester.enterText(find.byType(TextField).first, '700000001');
      await settle(tester, 500);
      await shot(tester, '01b-login-filled');
      await tester.tap(find.text('Получить код'));
      await settle(tester, 2500);
      await shot(tester, '02-otp');
      await tester.enterText(find.byType(TextField).first, '9999');
      await settle(tester, 3500);
    }

    await settle(tester, 3000); // home data
    await shot(tester, '03-home');

    // Scroll the home page a bit
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -600));
      await shot(tester, '03b-home-scrolled');
      await tester.drag(scrollables.first, const Offset(0, 1200));
      await settle(tester, 500);
    }

    final productCards = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'ProductCard',
    );
    if (await tapNav(tester, '/catalog')) {
      for (var i = 0; i < 10 && productCards.evaluate().isEmpty; i++) {
        await settle(tester, 1000);
      }
      await shot(tester, '04-catalog');
    }

    // Open the first product
    if (productCards.evaluate().isNotEmpty) {
      await tester.tap(productCards.first);
      await settle(tester, 2500);
      await shot(tester, '05-product');
      // Add to cart from the details page
      final addBtn = find.textContaining('В корзину');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn.first);
        await settle(tester, 1500);
      }
      final back = find.byIcon(Icons.arrow_back_rounded);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
        await settle(tester, 1200);
      } else if (find
          .byIcon(Icons.arrow_back_ios_new_rounded)
          .evaluate()
          .isNotEmpty) {
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
        await settle(tester, 1200);
      }
    }

    if (await tapNav(tester, '/cart')) {
      await shot(tester, '06-cart');

      // Checkout: store, date/time (needed for made-to-order cakes), place
      final checkout = find.text('Оформить заказ');
      if (checkout.evaluate().isNotEmpty) {
        await tester.tap(checkout.first);
        await settle(tester, 3000);
        await shot(tester, '06b-checkout');

        final pickStore = find.text('Выберите точку');
        if (pickStore.evaluate().isNotEmpty) {
          await tester.tap(pickStore.first);
          await settle(tester, 1500);
          await shot(tester, '06c-store-sheet');
          // First store tile inside the sheet (the page tile is behind it)
          final storeIcons = find.byIcon(Icons.storefront_rounded);
          await tester.tap(storeIcons.last);
          await settle(tester, 2500);
        }

        final pickDate = find.text('Выберите дату и время');
        if (pickDate.evaluate().isNotEmpty) {
          await tester.tap(pickDate.first);
          await settle(tester, 1500);
          await shot(tester, '06d-date-picker');
          for (final step in ['date', 'time']) {
            final ok = find.byWidgetPredicate(
              (w) =>
                  w is Text &&
                  (w.data == 'ОК' || w.data == 'OK' || w.data == 'ОК'),
            );
            if (ok.evaluate().isEmpty) break;
            await tester.tap(ok.last);
            await settle(tester, step == 'date' ? 1500 : 3000);
          }
        }
        await shot(tester, '06e-checkout-filled');

        final place = find.text('Оформить заказ');
        if (place.evaluate().isNotEmpty) {
          await tester.tap(place.last);
          await settle(tester, 4000);
          await shot(tester, '06f-order-created');
        }
      }
    }
    if (await tapNav(tester, '/profile')) {
      await settle(tester, 1500);
      await shot(tester, '07-profile');
      final edit = find.byIcon(Icons.edit_outlined);
      if (edit.evaluate().isNotEmpty) {
        await tester.tap(edit.first);
        await settle(tester, 1200);
        await shot(tester, '07b-profile-edit');
        final fields = find.byType(TextField);
        if (fields.evaluate().length >= 2) {
          await tester.enterText(fields.at(0), 'Айгерим');
          await tester.enterText(fields.at(1), 'Асанова');
          await settle(tester, 300);
          await tester.tap(find.text('Сохранить'));
          await settle(tester, 2500);
          expect(
            find.text('О себе'),
            findsNothing,
            reason: 'edit sheet should close after saving',
          );
          expect(find.text('Айгерим Асанова'), findsOneWidget);
          await shot(tester, '07c-profile-saved');
        }
      }
    }
    if (await tapNav(tester, '/stores')) {
      await settle(tester, 2000);
      await shot(tester, '08-stores');
      final mapTab = find.text('Карта');
      if (mapTab.evaluate().isNotEmpty) {
        await tester.tap(mapTab.first);
        await settle(tester, 3000);
        await shot(tester, '08b-stores-map');
      }
    }

    // Screens without a tab: open them through the router.
    Future<void> open(String path, String name) async {
      final ctx = tester.element(find.byType(Scaffold).first);
      GoRouter.of(ctx).push(path);
      await settle(tester, 2500);
      await shot(tester, name);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).pop();
      await settle(tester, 1000);
    }

    await open('/orders', '09-orders');
    await open('/loyalty', '10-loyalty');
    await open('/loyalty/history', '10b-points-history');
    await open('/promotions', '11-promotions');
    await open('/notifications', '12-notifications');
  });
}
