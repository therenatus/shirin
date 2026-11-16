import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/entities/order.dart';
import '../bloc/orders_bloc.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_style.dart';

class OrdersListPage extends StatefulWidget {
  const OrdersListPage({super.key});

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage> {
  int _selectedFilter = 0;

  static const _filters = ['Все', 'Активные', 'Завершённые'];

  List<Order> _filterOrders(List<Order> orders) {
    switch (_selectedFilter) {
      case 1: // Active
        return orders.where((o) => o.status.isActive).toList();
      case 2: // Completed
        return orders.where((o) => !o.status.isActive).toList();
      default:
        return orders;
    }
  }

  void _reload() => context.read<OrdersBloc>().add(const LoadOrders());

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        final count = state is OrdersLoaded ? state.orders.length : 0;
        return GlassPage(
          title: 'Мои заказы',
          eyebrow: count > 0 ? '$count ${_ordersWord(count)}' : 'История покупок',
          actions: [
            GlassIconButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Обновить',
              onTap: _reload,
            ),
          ],
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            _reload();
          },
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: GlassSegmented<int>(
                  values: const [0, 1, 2],
                  selected: _selectedFilter,
                  labelOf: (i) => _filters[i],
                  onChanged: (i) => setState(() => _selectedFilter = i),
                ),
              ),
            ),
            ..._buildBody(state),
          ],
        );
      },
    );
  }

  List<Widget> _buildBody(OrdersState state) {
    if (state is OrdersLoading) {
      return [_fill(_buildLoadingState())];
    }
    if (state is OrdersError) {
      return [_fill(_buildErrorState(state.message))];
    }
    if (state is OrdersLoaded) {
      if (state.orders.isEmpty) return [_fill(_buildEmptyState())];
      final filtered = _filterOrders(state.orders);
      if (filtered.isEmpty) return [_fill(_buildNoFilterResultsState())];
      return [_buildOrdersList(filtered)];
    }
    return const [];
  }

  Widget _fill(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: child);

  String _ordersWord(int n) {
    final r10 = n % 10, r100 = n % 100;
    if (r10 == 1 && r100 != 11) return 'заказ';
    if (r10 >= 2 && r10 <= 4 && (r100 < 12 || r100 > 14)) return 'заказа';
    return 'заказов';
  }

  Widget _buildOrdersList(List<Order> orders) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return TweenAnimationBuilder<double>(
            key: ValueKey('order-${order.id}-$_selectedFilter'),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 300)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            ),
            child: OrderCard(
              order: order,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/orders/${order.id}');
              },
            ),
          );
        },
      ),
    );
  }

  Widget _emptyIcon(IconData icon, {Color color = AppColors.primary}) {
    return LiquidGlass(
      width: 112,
      height: 112,
      borderRadius: BorderRadius.circular(56),
      child: Center(child: Icon(icon, size: 48, color: color)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _emptyIcon(Icons.receipt_long_rounded),
            const SizedBox(height: 24),
            Text('Заказов пока нет', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Здесь будет отображаться история\nваших заказов',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            GlassButton(
              label: 'Перейти в каталог',
              icon: Icons.shopping_bag_rounded,
              prominent: true,
              onTap: () => context.go('/catalog'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilterResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _emptyIcon(
              _selectedFilter == 1
                  ? Icons.schedule_rounded
                  : Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 20),
            Text(
              _selectedFilter == 1
                  ? 'Нет активных заказов'
                  : 'Нет завершённых заказов',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 6),
            Text('Попробуйте другой фильтр', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text('Загружаем заказы...', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _emptyIcon(Icons.cloud_off_rounded, color: AppColors.error),
            const SizedBox(height: 24),
            Text('Не удалось загрузить', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            GlassButton(
              label: 'Повторить',
              icon: Icons.refresh_rounded,
              onTap: _reload,
            ),
          ],
        ),
      ),
    );
  }
}
