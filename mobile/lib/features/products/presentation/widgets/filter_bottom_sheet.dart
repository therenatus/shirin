import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/entities/category.dart';

/// Filter content for the catalog. Open it with [showGlassSheet]; it pops
/// with a map of the chosen filters (or nothing when dismissed).
class FilterBottomSheet extends StatefulWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final String? selectedSortBy;
  final bool? isNew;
  final double? minPrice;
  final double? maxPrice;

  const FilterBottomSheet({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    this.selectedSortBy,
    this.isNew,
    this.minPrice,
    this.maxPrice,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  static const double _maxPrice = 5000;

  late String? _categoryId;
  late String? _sortBy;
  late bool _isNew;
  late RangeValues _priceRange;

  static const _sortOptions = <(String, String?)>[
    ('По умолчанию', null),
    ('Цена ↑', 'price_asc'),
    ('Цена ↓', 'price_desc'),
    ('Новинки', 'newest'),
  ];

  @override
  void initState() {
    super.initState();
    _categoryId = widget.selectedCategoryId;
    _sortBy = widget.selectedSortBy;
    _isNew = widget.isNew ?? false;
    _priceRange = RangeValues(
      widget.minPrice ?? 0,
      widget.maxPrice ?? _maxPrice,
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
          Text('Фильтры', style: AppTextStyles.heading2),
          const SizedBox(height: 20),
          _SectionLabel('Категория'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GlassChip(
                label: 'Все',
                selected: _categoryId == null,
                onTap: () => setState(() => _categoryId = null),
              ),
              for (final c in widget.categories)
                GlassChip(
                  label: c.name,
                  selected: _categoryId == c.id,
                  onTap: () => setState(() => _categoryId = c.id),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('Сортировка'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, value) in _sortOptions)
                GlassChip(
                  label: label,
                  selected: _sortBy == value,
                  onTap: () => setState(() => _sortBy = value),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _SectionLabel('Цена', bottom: 0)),
              Text(
                '${_priceRange.start.toInt()} – ${_priceRange.end.toInt()} сом',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.14),
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.08),
              trackHeight: 4,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 13,
                elevation: 3,
              ),
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 0,
              max: _maxPrice,
              divisions: 50,
              onChanged: (values) => setState(() => _priceRange = values),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Только новинки', style: AppTextStyles.bodyMedium),
                ),
                Switch.adaptive(
                  value: _isNew,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => setState(() => _isNew = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Сбросить',
                  expanded: true,
                  onTap: () {
                    Navigator.pop(context, {
                      'categoryId': null,
                      'sortBy': null,
                      'isNew': null,
                      'minPrice': null,
                      'maxPrice': null,
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassButton(
                  label: 'Применить',
                  prominent: true,
                  expanded: true,
                  onTap: () {
                    Navigator.pop(context, {
                      'categoryId': _categoryId,
                      'sortBy': _sortBy,
                      'isNew': _isNew ? true : null,
                      'minPrice':
                          _priceRange.start > 0 ? _priceRange.start : null,
                      'maxPrice':
                          _priceRange.end < _maxPrice ? _priceRange.end : null,
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final double bottom;

  const _SectionLabel(this.text, {this.bottom = 10});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 2, bottom: bottom),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.overline.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
