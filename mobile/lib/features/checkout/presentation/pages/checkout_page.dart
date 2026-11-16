import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../addresses/presentation/pages/addresses_page.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../orders/domain/entities/create_order_params.dart';
import '../bloc/checkout_cubit.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// "15.11, 14:30"
String formatDateTime(DateTime d) =>
    '${_two(d.day)}.${_two(d.month)}, ${_two(d.hour)}:${_two(d.minute)}';

/// Checkout: pickup or delivery, store or address, date and time (required
/// for made-to-order cakes), points, comment, and the server-calculated total.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listenWhen: (a, b) =>
          a.createdOrderId != b.createdOrderId ||
          (b.submitError != null && a.submitError != b.submitError),
      listener: (context, state) {
        if (state.createdOrderId != null) {
          context.read<CartBloc>().add(const ClearCart());
          context.go('/orders/${state.createdOrderId}');
        } else if (state.submitError != null) {
          showGlassToast(context, state.submitError!,
              icon: Icons.error_outline_rounded, bottomOffset: 120);
        }
      },
      builder: (context, state) {
        return GlassPage(
          title: 'Оформление',
          bottomBar: state.loading ? null : _SubmitBar(state: state),
          slivers: state.loading
              ? const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ]
              : [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 160),
                    sliver: SliverList.list(children: _sections(context, state)),
                  ),
                ],
        );
      },
    );
  }

  List<Widget> _sections(BuildContext context, CheckoutState state) {
    final cubit = context.read<CheckoutCubit>();
    final isPickup = state.deliveryType == DeliveryType.pickup;
    return [
      GlassSegmented<DeliveryType>(
        values: const [DeliveryType.pickup, DeliveryType.delivery],
        selected: state.deliveryType,
        labelOf: (t) => t == DeliveryType.pickup ? 'Самовывоз' : 'Доставка',
        onChanged: cubit.setDeliveryType,
      ),
      const SizedBox(height: 16),
      if (isPickup)
        _ChoiceTile(
          icon: Icons.storefront_rounded,
          title: state.store?.name ?? 'Выберите точку',
          subtitle: state.store?.address,
          onTap: () => _pickStore(context, state),
        )
      else
        _ChoiceTile(
          icon: Icons.place_rounded,
          title: state.address?.name ?? 'Выберите адрес',
          subtitle: state.address?.fullAddress,
          onTap: () => _pickAddress(context, state),
        ),
      const SizedBox(height: 12),
      _ChoiceTile(
        icon: Icons.event_rounded,
        title: state.dateTime != null
            ? formatDateTime(state.dateTime!)
            : state.hasPreorder
                ? 'Выберите дату и время'
                : 'Как можно скорее',
        subtitle: state.hasPreorder
            ? 'Торт на заказ можно получить не раньше '
                '${formatDateTime(state.preview?.earliestTime ?? state.localEarliestTime!)}'
            : 'Или выберите удобное время',
        onTap: () => _pickDateTime(context, state),
      ),
      if (state.pointsBalance > 0) ...[
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.usePoints && state.preview != null
                      ? 'Списать ${state.preview!.pointsUsed} из ${state.pointsBalance} баллов'
                      : 'Оплатить баллами (есть ${state.pointsBalance})',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              Switch.adaptive(
                value: state.usePoints,
                activeTrackColor: AppColors.primary,
                onChanged: cubit.setUsePoints,
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 12),
      GlassTextField(
        label: 'Комментарий к заказу',
        hint: 'Например, позвонить за 10 минут',
        maxLines: 3,
        inputFormatters: [LengthLimitingTextInputFormatter(500)],
        onChanged: cubit.setComment,
      ),
      const SizedBox(height: 20),
      _Summary(state: state),
    ];
  }

  Future<void> _pickStore(BuildContext context, CheckoutState state) async {
    final cubit = context.read<CheckoutCubit>();
    await showGlassSheet<void>(
      context: context,
      builder: (sheet) => _SheetList(
        title: 'Точка самовывоза',
        empty: 'Нет доступных точек',
        children: [
          for (final s in state.stores)
            _ChoiceTile(
              icon: Icons.storefront_rounded,
              title: s.name,
              subtitle: [s.address, if (s.workingHours != null) s.workingHours!].join(' · '),
              selected: s.id == state.store?.id,
              onTap: () {
                cubit.selectStore(s);
                Navigator.of(sheet).pop();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickAddress(BuildContext context, CheckoutState state) async {
    final cubit = context.read<CheckoutCubit>();
    await showGlassSheet<void>(
      context: context,
      builder: (sheet) => _SheetList(
        title: 'Адрес доставки',
        empty: 'Адресов пока нет',
        footer: GlassButton(
          label: 'Добавить или изменить адреса',
          icon: Icons.add_location_alt_rounded,
          expanded: true,
          onTap: () async {
            Navigator.of(sheet).pop();
            await Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const AddressesPage()),
            );
            cubit.reloadAddresses();
          },
        ),
        children: [
          for (final a in state.addresses)
            _ChoiceTile(
              icon: Icons.place_rounded,
              title: a.name,
              subtitle: a.fullAddress,
              selected: a.id == state.address?.id,
              onTap: () {
                cubit.selectAddress(a);
                Navigator.of(sheet).pop();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context, CheckoutState state) async {
    final cubit = context.read<CheckoutCubit>();
    final now = DateTime.now();
    final earliest = state.preview?.earliestTime ?? state.localEarliestTime ?? now;
    final initial = state.dateTime ?? earliest.add(const Duration(minutes: 30));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(earliest.year, earliest.month, earliest.day),
      lastDate: now.add(const Duration(days: 60)),
      locale: const Locale('ru'),
      helpText: 'Дата получения',
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Время получения',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !context.mounted) return;

    var picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isBefore(earliest)) {
      picked = earliest.add(Duration(minutes: 15 - earliest.minute % 15));
      showGlassToast(
        context,
        'Раньше не успеем — поставили ${formatDateTime(picked)}',
        icon: Icons.schedule_rounded,
        bottomOffset: 120,
      );
    }
    cubit.setDateTime(picked);
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(fontSize: 15)),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            color: selected ? AppColors.primary : AppColors.textLight,
          ),
        ],
      ),
    );
  }
}

class _SheetList extends StatelessWidget {
  final String title;
  final String empty;
  final List<Widget> children;
  final Widget? footer;

  const _SheetList({
    required this.title,
    required this.empty,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(empty, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: children.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => children[i],
                ),
              ),
            if (footer != null) ...[const SizedBox(height: 12), footer!],
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final CheckoutState state;
  const _Summary({required this.state});

  @override
  Widget build(BuildContext context) {
    final p = state.preview;
    final itemsTotal =
        state.items.fold<double>(0, (s, i) => s + i.totalPrice);

    Widget row(String label, String value, {bool bold = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
              Text(
                value,
                style: (bold ? AppTextStyles.heading3 : AppTextStyles.label)
                    .copyWith(color: color),
              ),
            ],
          ),
        );

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row('Товары', formatPrice(p?.subtotal ?? itemsTotal)),
          if (p != null && state.deliveryType == DeliveryType.delivery)
            row('Доставка', p.deliveryFee > 0 ? formatPrice(p.deliveryFee) : 'Бесплатно'),
          if (p != null && p.pointsUsed > 0)
            row('Оплата баллами', '−${formatPrice(p.pointsUsed)}', color: AppColors.success),
          const Divider(height: 20),
          row('Итого', formatPrice(p?.total ?? itemsTotal), bold: true),
          if (p != null && p.prepaymentAmount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Предоплата за торт на заказ: ${formatPrice(p.prepaymentAmount)}. '
              'Реквизиты появятся после оформления; оплатите в течение '
              '${p.paymentTimeoutMinutes} мин, иначе заказ отменится.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
          ],
          if (p != null && p.pointsEarned > 0) ...[
            const SizedBox(height: 8),
            Text('Вернём ${p.pointsEarned} баллов кешбэком после получения',
                style: AppTextStyles.bodySmall),
          ],
          if (state.previewError != null) ...[
            const SizedBox(height: 8),
            Text(state.previewError!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ],
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final CheckoutState state;
  const _SubmitBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final missing = state.missing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassButton(
        label: missing ?? 'Оформить заказ',
        trailing: missing == null && state.preview != null
            ? formatPrice(state.preview!.total)
            : null,
        prominent: missing == null,
        expanded: true,
        loading: state.submitting,
        onTap: missing == null && !state.submitting
            ? () => context.read<CheckoutCubit>().submit()
            : null,
      ),
    );
  }
}
