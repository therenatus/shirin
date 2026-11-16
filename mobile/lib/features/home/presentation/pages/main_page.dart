import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/add_to_cart_animation.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_state.dart';

/// App shell: the page with a floating Liquid Glass tab bar above it.
/// Pages extend under the bar and pad their scroll end with
/// [GlassTabBarMetrics.clearance].
class MainPage extends StatefulWidget {
  final Widget child;

  const MainPage({super.key, required this.child});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  final GlobalKey _cartIconKey = GlobalKey();
  final AddToCartAnimationController _animationController =
      AddToCartAnimationController();
  late final AnimationController _bounceController;
  int _currentIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Главная', route: '/home'),
    _NavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded, label: 'Меню', route: '/catalog'),
    _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded, label: 'Корзина', route: '/cart', isCart: true),
    _NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Магазины', route: '/stores'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Профиль', route: '/profile'),
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    context.go(_navItems[index].route);
  }

  int _indexFromRoute(String route) {
    for (var i = 0; i < _navItems.length; i++) {
      if (route.startsWith(_navItems[i].route)) return i;
    }
    return _currentIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.toString();
    final newIndex = _indexFromRoute(location);
    if (newIndex != _currentIndex) {
      setState(() => _currentIndex = newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CartAnimationProvider(
      controller: _animationController,
      cartIconKey: _cartIconKey,
      child: AddToCartOverlay(
        controller: _animationController,
        child: BlocListener<CartBloc, CartState>(
          listener: (context, state) {
            if (state is CartLoaded) {
              _bounceController.forward(from: 0).then((_) => _bounceController.reverse());
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            extendBody: true,
            body: widget.child,
            bottomNavigationBar: _buildBar(),
          ),
        ),
      ),
    );
  }

  Widget _buildBar() {
    return GlassTabBar(
      currentIndex: _currentIndex,
      itemCount: _navItems.length,
      onTap: _onTap,
      itemKeys: [for (final item in _navItems) ValueKey('nav-${item.route}')],
      itemBuilder: (context, i, selected) {
        final item = _navItems[i];
        return _NavButton(
          item: item,
          selected: selected,
          iconKey: item.isCart ? _cartIconKey : null,
          bounce: item.isCart ? _bounceController : null,
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final Key? iconKey;
  final AnimationController? bounce;

  const _NavButton({
    required this.item,
    required this.selected,
    this.iconKey,
    this.bounce,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final baseIcon = Icon(selected ? item.activeIcon : item.icon, size: 25, color: color);
    Widget icon = baseIcon;

    if (item.isCart) {
      icon = BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final count = state is CartLoaded ? state.totalItems : 0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              KeyedSubtree(key: iconKey, child: baseIcon),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.overline.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 0,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
      if (bounce != null) {
        icon = AnimatedBuilder(
          animation: bounce!,
          builder: (_, child) => Transform.scale(
            scale: 1 + bounce!.value * 0.18,
            child: child,
          ),
          child: icon,
        );
      }
    }

    return AnimatedScale(
      scale: selected ? 1.0 : 0.94,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.caption.copyWith(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
              height: 1,
            ),
            child: Text(item.label, maxLines: 1),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isCart;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.isCart = false,
  });
}
