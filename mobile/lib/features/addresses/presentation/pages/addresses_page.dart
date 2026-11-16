import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/create_address_params.dart';
import '../bloc/addresses_bloc.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddressesBloc>()..add(const LoadAddresses()),
      child: const _AddressesPageContent(),
    );
  }
}

/// "Мои адреса": address cards on the liquid background, add/edit in a glass
/// sheet, the add action floating at the bottom as the one prominent button.
/// Pushed on the root navigator, so there is no tab bar under it.
class _AddressesPageContent extends StatelessWidget {
  const _AddressesPageContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddressesBloc, AddressesState>(
      listener: (context, state) {
        if (state is AddressesActionSuccess) {
          showGlassToast(
            context,
            state.message,
            icon: Icons.check_circle_rounded,
          );
        } else if (state is AddressesError) {
          showGlassToast(
            context,
            state.message,
            icon: Icons.error_outline_rounded,
          );
        }
      },
      builder: (context, state) {
        final List<Widget> slivers;
        if (state is AddressesLoading) {
          slivers = const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ];
        } else {
          List<Address> addresses = [];
          if (state is AddressesLoaded) {
            addresses = state.addresses;
          } else if (state is AddressesActionSuccess) {
            addresses = state.addresses;
          }
          slivers = addresses.isEmpty
              ? const [SliverToBoxAdapter(child: _EmptyState())]
              : [_buildAddressList(context, addresses)];
        }

        return GlassPage(
          title: 'Мои адреса',
          hasTabBar: false,
          backgroundIntensity: 0.8,
          onBack: () => Navigator.of(context).pop(),
          bottomBar: GlassButton(
            label: 'Добавить адрес',
            icon: Icons.add_location_alt_rounded,
            prominent: true,
            expanded: true,
            onTap: () => _showAddAddressSheet(context),
          ),
          slivers: slivers,
        );
      },
    );
  }

  Widget _buildAddressList(BuildContext context, List<Address> addresses) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.builder(
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final address = addresses[index];
          return _AddressCard(
            address: address,
            onEdit: () => _showEditAddressSheet(context, address),
            onMore: () => _showActionsSheet(context, address),
          );
        },
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showGlassSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AddressesBloc>(),
        child: const _AddressFormSheet(),
      ),
    );
  }

  void _showEditAddressSheet(BuildContext context, Address address) {
    HapticFeedback.lightImpact();
    showGlassSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AddressesBloc>(),
        child: _AddressFormSheet(address: address),
      ),
    );
  }

  /// Action sheet replacing the old popup menu: default / edit / delete.
  void _showActionsSheet(BuildContext context, Address address) {
    HapticFeedback.lightImpact();
    showGlassSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                children: [
                  Text(
                    address.name,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.fullAddress,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            if (!address.isDefault)
              _SheetAction(
                icon: Icons.check_circle_outline_rounded,
                label: 'Сделать адресом по умолчанию',
                onTap: () {
                  Navigator.pop(sheetContext);
                  HapticFeedback.lightImpact();
                  context.read<AddressesBloc>().add(SetDefault(address.id));
                },
              ),
            _SheetAction(
              icon: Icons.edit_rounded,
              label: 'Редактировать',
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditAddressSheet(context, address);
              },
            ),
            _SheetAction(
              icon: Icons.delete_outline_rounded,
              label: 'Удалить',
              destructive: true,
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteConfirmation(context, address);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Address address) {
    HapticFeedback.mediumImpact();
    showGlassSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Удалить адрес?',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 6),
            Text(
              'Адрес "${address.name}" будет удалён без возможности восстановления.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            _DestructiveButton(
              label: 'Удалить',
              onTap: () {
                Navigator.pop(sheetContext);
                context.read<AddressesBloc>().add(RemoveAddress(address.id));
              },
            ),
            const SizedBox(height: 8),
            GlassButton(
              label: 'Отмена',
              expanded: true,
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Нет сохранённых адресов',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 6),
          Text(
            'Добавьте адрес для быстрого оформления заказа',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onMore,
  });

  IconData get _icon {
    final name = address.name.toLowerCase();
    if (name.contains('дом')) return Icons.home_rounded;
    if (name.contains('работ')) return Icons.work_rounded;
    return Icons.location_on_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      onTap: onEdit,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: address.isDefault
                  ? AppColors.primary
                  : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _icon,
              color: address.isDefault ? Colors.white : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      address.name,
                      style: AppTextStyles.heading3.copyWith(fontSize: 16),
                    ),
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'По умолчанию',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address.fullAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
                if (address.intercom != null &&
                    address.intercom!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.dialpad_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Домофон: ${address.intercom}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onMore,
            tooltip: 'Действия',
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Row in the glass action sheet.
class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GlassPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: destructive ? AppColors.error : AppColors.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Solid red capsule for the destructive confirmation.
class _DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DestructiveButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      glowColor: Colors.white.withValues(alpha: 0.35),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.button),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final Address? address;

  const _AddressFormSheet({this.address});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _streetController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _entranceController;
  late final TextEditingController _floorController;
  late final TextEditingController _intercomController;

  bool _isDefault = false;
  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.name);
    _streetController = TextEditingController(text: widget.address?.street);
    _apartmentController = TextEditingController(text: widget.address?.apartment);
    _entranceController = TextEditingController(text: widget.address?.entrance);
    _floorController = TextEditingController(text: widget.address?.floor);
    _intercomController = TextEditingController(text: widget.address?.intercom);
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _apartmentController.dispose();
    _entranceController.dispose();
    _floorController.dispose();
    _intercomController.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();

    if (_isEditing) {
      context.read<AddressesBloc>().add(
            EditAddress(
              widget.address!.id,
              UpdateAddressParams(
                name: _nameController.text.trim(),
                street: _streetController.text.trim(),
                apartment: _optional(_apartmentController),
                entrance: _optional(_entranceController),
                floor: _optional(_floorController),
                intercom: _optional(_intercomController),
              ),
            ),
          );
    } else {
      context.read<AddressesBloc>().add(
            AddAddress(
              CreateAddressParams(
                name: _nameController.text.trim(),
                street: _streetController.text.trim(),
                apartment: _optional(_apartmentController),
                entrance: _optional(_entranceController),
                floor: _optional(_floorController),
                intercom: _optional(_intercomController),
                isDefault: _isDefault,
              ),
            ),
          );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Keep the sheet below the status bar even with the keyboard open.
    final maxHeight =
        mq.size.height - mq.padding.top - mq.viewInsets.bottom - 48;
    final name = _nameController.text;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight.clamp(200.0, 2000.0)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Редактировать адрес' : 'Новый адрес',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 20),

              // Quick select name
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 8),
                child: Text('Название', style: AppTextStyles.label),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GlassChip(
                    label: 'Дом',
                    icon: Icons.home_rounded,
                    selected: name == 'Дом',
                    onTap: () => setState(() => _nameController.text = 'Дом'),
                  ),
                  GlassChip(
                    label: 'Работа',
                    icon: Icons.work_rounded,
                    selected: name == 'Работа',
                    onTap: () =>
                        setState(() => _nameController.text = 'Работа'),
                  ),
                  GlassChip(
                    label: 'Другое',
                    icon: Icons.location_on_rounded,
                    selected:
                        name != 'Дом' && name != 'Работа' && name.isNotEmpty,
                    onTap: () => setState(() => _nameController.text = ''),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: _nameController,
                hint: 'Например: Дом, Работа',
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                validator: (v) => v!.isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),

              GlassTextField(
                controller: _streetController,
                label: 'Улица и дом',
                hint: 'ул. Киевская, 120',
                icon: Icons.location_on_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) => v!.isEmpty ? 'Введите адрес' : null,
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: _apartmentController,
                      label: 'Квартира',
                      hint: '45',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassTextField(
                      controller: _entranceController,
                      label: 'Подъезд',
                      hint: '2',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GlassTextField(
                      controller: _floorController,
                      label: 'Этаж',
                      hint: '5',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassTextField(
                      controller: _intercomController,
                      label: 'Домофон',
                      hint: '45K1234',
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Default switch
              if (!_isEditing)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: _isDefault
                            ? AppColors.warning
                            : AppColors.textLight,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Адрес по умолчанию',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _isDefault,
                        onChanged: (v) => setState(() => _isDefault = v),
                        activeTrackColor: AppColors.primary,
                        thumbColor: WidgetStateProperty.all(Colors.white),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              GlassButton(
                label: _isEditing ? 'Сохранить' : 'Добавить адрес',
                prominent: true,
                expanded: true,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
