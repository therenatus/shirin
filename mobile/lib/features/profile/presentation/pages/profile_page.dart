import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../addresses/presentation/pages/addresses_page.dart';
import '../../../auth/domain/entities/update_profile_params.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/usecases/update_profile.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../loyalty/presentation/bloc/loyalty_bloc.dart';
import '../../../loyalty/presentation/widgets/loyalty_hero_card.dart';
import '../../../loyalty/presentation/widgets/punch_card_strip.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/bloc/orders_bloc.dart';
import '../../../orders/presentation/widgets/order_status_style.dart';

/// Profile: who you are, your card and level, the birthday gift,
/// coffee stamps, recent orders, and iOS Settings-style menu groups.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<OrdersBloc>()..add(const LoadOrders())),
        BlocProvider(
          create: (_) => sl<LoyaltyBloc>()..add(const LoadLoyaltyInfo()),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) context.go('/login');
          if (state is AuthError) {
            showGlassToast(context, state.message, icon: Icons.error_outline_rounded);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (_, s) => s is Authenticated,
          builder: (context, state) {
            final user = state is Authenticated ? state.user : null;
            return GlassPage(
              title: 'Профиль',
              largeTitle: false,
              showBack: false,
              actions: [
                GlassIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Редактировать',
                  onTap: () => _openEditSheet(context, user),
                ),
              ],
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  sliver: SliverList.list(
                    children: [
                      _UserHeader(
                        user: user,
                        onEdit: () => _openEditSheet(context, user),
                      ),
                      const SizedBox(height: 24),
                      _LoyaltyCard(
                        points: user?.loyaltyPoints ?? 0,
                        onTap: () => context.push('/loyalty'),
                        onHistory: () => context.push('/loyalty/history'),
                      ),
                      const SizedBox(height: 16),
                      _BirthdayCard(
                        birthDate: user?.birthDate,
                        onTap: () => _openEditSheet(
                          context,
                          user,
                          focusBirthday: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SettingsGroup(
                        items: [
                          _SettingsEntry(
                            Icons.receipt_long_rounded,
                            'История заказов',
                            AppColors.primary,
                            () => context.push('/orders'),
                          ),
                          _SettingsEntry(
                            Icons.qr_code_2_rounded,
                            'Карта Ширин',
                            AppColors.secondary,
                            () => context.push('/loyalty'),
                          ),
                          _SettingsEntry(
                            Icons.place_rounded,
                            'Мои адреса',
                            AppColors.success,
                            () => Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (_) => const AddressesPage(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text('Кофейные штампы', style: AppTextStyles.heading2),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: PunchCardStrip(onTap: () => context.push('/loyalty')),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                const SliverToBoxAdapter(child: _RecentOrders()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  sliver: SliverList.list(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text('Ещё', style: AppTextStyles.heading2),
                      ),
                      _SettingsGroup(
                        items: [
                          _SettingsEntry(
                            Icons.storefront_rounded,
                            'Наши магазины',
                            AppColors.categoryIconColors[4],
                            () => context.go('/stores'),
                          ),
                          _SettingsEntry(
                            Icons.local_offer_rounded,
                            'Акции',
                            AppColors.warning,
                            () => context.push('/promotions'),
                          ),
                          _SettingsEntry(
                            Icons.support_agent_rounded,
                            'Поддержка',
                            AppColors.categoryIconColors[6],
                            () {
                              Clipboard.setData(
                                const ClipboardData(text: '+996 312 000000'),
                              );
                              showGlassToast(
                                context,
                                'Номер поддержки скопирован: +996 312 000000',
                                icon: Icons.content_copy_rounded,
                              );
                            },
                          ),
                          _SettingsEntry(
                            Icons.info_rounded,
                            'О приложении',
                            AppColors.textSecondary,
                            () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'Ширин',
                                applicationVersion: '1.0.0',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SettingsGroup(
                        items: [
                          _SettingsEntry(
                            Icons.logout_rounded,
                            'Выйти из аккаунта',
                            AppColors.error,
                            () => _confirmLogout(context),
                            destructive: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openEditSheet(
    BuildContext context,
    User? user, {
    bool focusBirthday = false,
  }) {
    final authBloc = context.read<AuthBloc>();
    showGlassSheet<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: authBloc,
        child: _EditProfileSheet(user: user, focusBirthday: focusBirthday),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showGlassSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Выйти из аккаунта?', style: AppTextStyles.heading2),
            const SizedBox(height: 6),
            Text(
              'Бонусы и заказы сохранятся за вашим номером.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Остаться',
                    expanded: true,
                    onTap: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GlassButton(
                    label: 'Выйти',
                    prominent: true,
                    expanded: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<AuthBloc>().add(const LogoutRequested());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPhone(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length == 12 && d.startsWith('996')) {
    return '+996 ${d.substring(3, 6)} ${d.substring(6, 8)} ${d.substring(8, 10)} ${d.substring(10)}';
  }
  return raw;
}

const _months = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String _formatDay(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// Big avatar with initials, the full name and phone, centred like the
/// Apple ID header in Settings.
class _UserHeader extends StatelessWidget {
  final User? user;
  final VoidCallback onEdit;

  const _UserHeader({required this.user, required this.onEdit});

  String get _initials {
    final f = user?.firstName?.trim();
    final l = user?.lastName?.trim();
    if ((f == null || f.isEmpty) && (l == null || l.isEmpty)) return 'Ш';
    return '${f?.isNotEmpty == true ? f![0] : ''}${l?.isNotEmpty == true ? l![0] : ''}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasName = user?.firstName?.trim().isNotEmpty == true;
    final title = hasName ? user!.displayName : 'Гость Ширин';
    return Column(
      children: [
        GlassPressable(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(56),
          glowColor: Colors.white.withValues(alpha: 0.5),
          child: Container(
            width: 112,
            height: 112,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.7),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primarySoft, AppColors.secondaryLight],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: AppTextStyles.display.copyWith(
                  color: AppColors.secondary,
                  fontSize: 38,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: AppTextStyles.heading1,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          user != null ? _formatPhone(user!.phone) : '',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// The loyalty card: balance (from the user profile) and level (from the
/// loyalty API). A clear-glass chip opens the points history.
class _LoyaltyCard extends StatelessWidget {
  final int points;
  final VoidCallback onTap;
  final VoidCallback onHistory;

  const _LoyaltyCard({
    required this.points,
    required this.onTap,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoyaltyBloc, LoyaltyState>(
      builder: (context, state) {
        final info = state is LoyaltyInfoLoaded ? state.info : null;
        return LoyaltyHeroCard(
          points: points,
          level: info?.level,
          onTap: onTap,
          trailing: LiquidGlass.capsule(
            style: GlassStyle.clear.copyWith(foreground: Colors.white),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onTap: onHistory,
            child: Center(
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Мои бонусы',
                    style: AppTextStyles.label.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Покажите карту на кассе, чтобы копить и списывать баллы',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_2_rounded,
                    color: AppColors.textPrimary, size: 30),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A confectionery's own perk: a birthday treat. Asks for the date if unknown.
class _BirthdayCard extends StatelessWidget {
  final DateTime? birthDate;
  final VoidCallback onTap;

  const _BirthdayCard({required this.birthDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final known = birthDate != null;
    return ContentCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cake_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  known
                      ? 'День рождения ${_formatDay(birthDate!)}'
                      : 'Подарок ко дню рождения',
                  style: AppTextStyles.label.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  known
                      ? 'Пирожное в подарок ждёт вас в этот день'
                      : 'Укажите дату, и в этот день пирожное за наш счёт',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Icon(
            known ? Icons.chevron_right_rounded : Icons.add_circle_rounded,
            color: known ? AppColors.textLight : AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        final orders = state is OrdersLoaded
            ? state.orders.take(5).toList()
            : const <Order>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Заказы',
              actionLabel: orders.isEmpty ? null : 'Все',
              onAction: () => context.push('/orders'),
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ContentCard(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Заказов пока нет. Первый торт ждёт в меню.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/catalog'),
                        child: const Text('В меню'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                // Extra room for the card shadow.
                height: 138,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  clipBehavior: Clip.none,
                  physics: const BouncingScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _OrderTile(order: orders[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final d = order.createdAt;
    final date =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    return SizedBox(
      width: 172,
      child: ContentCard(
        onTap: () => context.push('/orders/${order.id}'),
        padding: const EdgeInsets.all(14),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderStatusChip(status: order.status),
            const Spacer(),
            Text(
              '№ ${orderDisplayNumber(order)}',
              style: AppTextStyles.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$date · ${order.items.length} поз.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 4),
            Text(formatPrice(order.totalSum), style: AppTextStyles.price),
          ],
        ),
      ),
    );
  }
}

class _SettingsEntry {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool destructive;

  const _SettingsEntry(
    this.icon,
    this.title,
    this.color,
    this.onTap, {
    this.destructive = false,
  });
}

/// iOS Settings-style group: rows with a coloured icon tile on a glass panel.
class _SettingsGroup extends StatelessWidget {
  final List<_SettingsEntry> items;
  const _SettingsGroup({required this.items});

  static const double _radius = 26;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: _radius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 62),
                    child: Divider(
                      height: 1,
                      thickness: 0.6,
                      color: AppColors.textLight.withValues(alpha: 0.3),
                    ),
                  ),
                _SettingsRow(entry: items[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _SettingsEntry entry;
  const _SettingsRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        entry.onTap();
      },
      splashColor: Colors.white.withValues(alpha: 0.3),
      highlightColor: Colors.white.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: entry.color,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(entry.icon, size: 19, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.title,
                style: AppTextStyles.label.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: entry.destructive ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            if (!entry.destructive)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
              ),
          ],
        ),
      ),
    );
  }
}

/// Name, surname and birthday on a glass sheet. Saves through AuthBloc and
/// closes on success.
class _EditProfileSheet extends StatefulWidget {
  final User? user;
  final bool focusBirthday;

  const _EditProfileSheet({required this.user, this.focusBirthday = false});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _first = TextEditingController(text: widget.user?.firstName ?? '');
    _last = TextEditingController(text: widget.user?.lastName ?? '');
    _birthDate = widget.user?.birthDate;
    if (widget.focusBirthday) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickDate());
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      locale: const Locale('ru'),
      helpText: 'Дата рождения',
      confirmText: 'Готово',
      cancelText: 'Отмена',
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final bloc = context.read<AuthBloc>();
    setState(() => _saving = true);
    final result = await sl<UpdateProfile>()(
      UpdateProfileParams(
        firstName: _first.text.trim().isEmpty ? null : _first.text.trim(),
        lastName: _last.text.trim().isEmpty ? null : _last.text.trim(),
        birthDate: _birthDate,
      ),
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _saving = false);
        showGlassToast(context, failure.message, icon: Icons.error_outline_rounded);
      },
      (user) {
        bloc.add(UserRefreshed(user));
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('О себе', style: AppTextStyles.heading2),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Как к вам обращаться и когда поздравлять',
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
          GlassTextField(
            controller: _first,
            hint: 'Имя',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: _last,
            hint: 'Фамилия',
            icon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 10),
          LiquidGlass.capsule(
            height: 54,
            style: GlassStyle.regular.copyWith(shadowOpacity: 0.05),
            padding: const EdgeInsets.only(left: 14, right: 16),
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(
                  Icons.cake_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _birthDate == null
                        ? 'Дата рождения'
                        : '${_formatDay(_birthDate!)} ${_birthDate!.year}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _birthDate == null
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassButton(
            label: 'Сохранить',
            prominent: true,
            expanded: true,
            loading: _saving,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}
