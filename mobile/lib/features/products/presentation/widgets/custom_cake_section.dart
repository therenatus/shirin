import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../orders/domain/usecases/upload_reference_photo.dart';
import '../../domain/entities/product.dart';

/// What the customer wants on a made-to-order cake.
class CustomCakeWishes {
  final TextEditingController inscription = TextEditingController();
  final TextEditingController wishes = TextEditingController();
  final ValueNotifier<String?> photoUrl = ValueNotifier(null);

  void clear() {
    inscription.clear();
    wishes.clear();
    photoUrl.value = null;
  }

  void dispose() {
    inscription.dispose();
    wishes.dispose();
    photoUrl.dispose();
  }
}

/// "Made to order" block on the product page: lead time and prepayment
/// terms, an inscription, wishes and an optional reference photo.
class CustomCakeSection extends StatefulWidget {
  final Product product;
  final CustomCakeWishes wishes;

  const CustomCakeSection({
    super.key,
    required this.product,
    required this.wishes,
  });

  @override
  State<CustomCakeSection> createState() => _CustomCakeSectionState();
}

class _CustomCakeSectionState extends State<CustomCakeSection> {
  bool _uploading = false;

  String get _leadTime {
    final h = widget.product.leadTimeHours;
    if (h <= 0) return 'в день заказа';
    if (h % 24 == 0) {
      final d = h ~/ 24;
      return 'за $d ${d == 1 ? 'день' : (d < 5 ? 'дня' : 'дней')}';
    }
    return 'за $h ч';
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    final result = await sl<UploadReferencePhoto>()(picked.path);
    if (!mounted) return;
    setState(() => _uploading = false);
    result.fold(
      (failure) => showGlassToast(context, 'Не удалось загрузить фото: ${failure.message}'),
      (url) => widget.wishes.photoUrl.value = url,
    );
  }

  void _choosePhotoSource() {
    showGlassSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Фото-образец', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            GlassButton(
              label: 'Выбрать из галереи',
              icon: Icons.photo_library_rounded,
              expanded: true,
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
            GlassButton(
              label: 'Сфотографировать',
              icon: Icons.photo_camera_rounded,
              expanded: true,
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final terms = [
      'Готовим $_leadTime',
      if (p.prepaymentPercent > 0) 'предоплата ${p.prepaymentPercent}%',
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.cake_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Торт на заказ. $terms. Дату и время выберете при оформлении.',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        if (p.allowInscription) ...[
          const SizedBox(height: 16),
          GlassTextField(
            controller: widget.wishes.inscription,
            label: 'Надпись на торте',
            hint: 'Например, «С днём рождения, Айгуль!»',
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
          ),
        ],
        const SizedBox(height: 12),
        GlassTextField(
          controller: widget.wishes.wishes,
          label: 'Пожелания',
          hint: 'Цвет крема, начинка, украшения',
          inputFormatters: [LengthLimitingTextInputFormatter(300)],
          maxLines: 3,
        ),
        if (p.allowReferencePhoto) ...[
          const SizedBox(height: 12),
          ValueListenableBuilder<String?>(
            valueListenable: widget.wishes.photoUrl,
            builder: (context, url, _) {
              if (_uploading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              if (url == null) {
                return GlassButton(
                  label: 'Приложить фото-образец',
                  icon: Icons.add_photo_alternate_rounded,
                  expanded: true,
                  onTap: _choosePhotoSource,
                );
              }
              return Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(url, width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Фото-образец приложено', style: AppTextStyles.bodyMedium),
                  ),
                  GlassIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Убрать фото',
                    onTap: () => widget.wishes.photoUrl.value = null,
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
