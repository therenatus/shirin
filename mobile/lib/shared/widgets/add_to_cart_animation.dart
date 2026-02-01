import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AddToCartAnimationController {
  _AddToCartOverlayState? _overlayState;

  void _attach(_AddToCartOverlayState state) {
    _overlayState = state;
  }

  void _detach() {
    _overlayState = null;
  }

  void animateToCart({
    required GlobalKey productKey,
    required GlobalKey cartKey,
    Widget? productWidget,
  }) {
    _overlayState?.animateToCart(
      productKey: productKey,
      cartKey: cartKey,
      productWidget: productWidget,
    );
  }
}

class AddToCartOverlay extends StatefulWidget {
  final Widget child;
  final AddToCartAnimationController controller;

  const AddToCartOverlay({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<AddToCartOverlay> createState() => _AddToCartOverlayState();
}

class _AddToCartOverlayState extends State<AddToCartOverlay>
    with TickerProviderStateMixin {
  final List<_AnimatingItem> _animatingItems = [];

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    widget.controller._detach();
    for (final item in _animatingItems) {
      item.controller.dispose();
    }
    super.dispose();
  }

  void animateToCart({
    required GlobalKey productKey,
    required GlobalKey cartKey,
    Widget? productWidget,
  }) {
    final productContext = productKey.currentContext;
    final cartContext = cartKey.currentContext;

    if (productContext == null || cartContext == null) return;

    final productBox = productContext.findRenderObject() as RenderBox?;
    final cartBox = cartContext.findRenderObject() as RenderBox?;

    if (productBox == null || cartBox == null) return;

    final productPosition = productBox.localToGlobal(Offset.zero);
    final cartPosition = cartBox.localToGlobal(Offset.zero);
    final cartSize = cartBox.size;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final item = _AnimatingItem(
      id: DateTime.now().millisecondsSinceEpoch,
      startPosition: productPosition,
      endPosition: Offset(
        cartPosition.dx + cartSize.width / 2 - 20,
        cartPosition.dy + cartSize.height / 2 - 20,
      ),
      controller: controller,
      widget: productWidget,
    );

    setState(() {
      _animatingItems.add(item);
    });

    controller.forward().then((_) {
      setState(() {
        _animatingItems.remove(item);
      });
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._animatingItems.map((item) => _buildAnimatingItem(item)),
      ],
    );
  }

  Widget _buildAnimatingItem(_AnimatingItem item) {
    return AnimatedBuilder(
      animation: item.controller,
      builder: (context, child) {
        final progress = Curves.easeInOut.transform(item.controller.value);
        final scaleProgress = Curves.easeIn.transform(item.controller.value);

        // Bezier curve path
        final controlPoint = Offset(
          (item.startPosition.dx + item.endPosition.dx) / 2,
          item.startPosition.dy - 100,
        );

        final currentPosition = _quadraticBezier(
          item.startPosition,
          controlPoint,
          item.endPosition,
          progress,
        );

        final scale = 1.0 - (scaleProgress * 0.6);
        final opacity = 1.0 - (scaleProgress * 0.3);

        return Positioned(
          left: currentPosition.dx,
          top: currentPosition.dy,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: item.widget ?? _defaultAnimationWidget(),
            ),
          ),
        );
      },
    );
  }

  Offset _quadraticBezier(Offset start, Offset control, Offset end, double t) {
    final x = (1 - t) * (1 - t) * start.dx +
        2 * (1 - t) * t * control.dx +
        t * t * end.dx;
    final y = (1 - t) * (1 - t) * start.dy +
        2 * (1 - t) * t * control.dy +
        t * t * end.dy;
    return Offset(x, y);
  }

  Widget _defaultAnimationWidget() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.shopping_cart_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _AnimatingItem {
  final int id;
  final Offset startPosition;
  final Offset endPosition;
  final AnimationController controller;
  final Widget? widget;

  _AnimatingItem({
    required this.id,
    required this.startPosition,
    required this.endPosition,
    required this.controller,
    this.widget,
  });
}

// Helper widget to wrap the main app with the animation overlay
class CartAnimationProvider extends InheritedWidget {
  final AddToCartAnimationController controller;
  final GlobalKey cartIconKey;

  const CartAnimationProvider({
    super.key,
    required this.controller,
    required this.cartIconKey,
    required super.child,
  });

  static CartAnimationProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CartAnimationProvider>();
  }

  @override
  bool updateShouldNotify(CartAnimationProvider oldWidget) {
    return controller != oldWidget.controller ||
        cartIconKey != oldWidget.cartIconKey;
  }
}
