import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/category.dart';

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
  late String? _categoryId;
  late String? _sortBy;
  late bool _isNew;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.selectedCategoryId;
    _sortBy = widget.selectedSortBy;
    _isNew = widget.isNew ?? false;
    _priceRange = RangeValues(
      widget.minPrice ?? 0,
      widget.maxPrice ?? 5000,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Фильтры', style: AppTextStyles.heading3),
              const SizedBox(height: 20),

              // Categories
              Text('Категория', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip('Все', null),
                  ...widget.categories.map(
                    (c) => _buildChip(c.name, c.id),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sort
              Text('Сортировка', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSortChip('По умолчанию', null),
                  _buildSortChip('Цена ↑', 'price_asc'),
                  _buildSortChip('Цена ↓', 'price_desc'),
                  _buildSortChip('Новинки', 'newest'),
                ],
              ),
              const SizedBox(height: 20),

              // Price Range
              Text('Цена: ${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} сом',
                  style: AppTextStyles.label),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 5000,
                divisions: 50,
                activeColor: AppColors.primary,
                onChanged: (values) {
                  setState(() => _priceRange = values);
                },
              ),
              const SizedBox(height: 12),

              // New only
              SwitchListTile(
                title: Text('Только новинки', style: AppTextStyles.bodyMedium),
                value: _isNew,
                activeTrackColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _isNew = val),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Сбросить',
                      variant: AppButtonVariant.outlined,
                      onPressed: () {
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Применить',
                      onPressed: () {
                        Navigator.pop(context, {
                          'categoryId': _categoryId,
                          'sortBy': _sortBy,
                          'isNew': _isNew ? true : null,
                          'minPrice': _priceRange.start > 0 ? _priceRange.start : null,
                          'maxPrice': _priceRange.end < 5000 ? _priceRange.end : null,
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, String? categoryId) {
    final isSelected = _categoryId == categoryId;
    return GestureDetector(
      onTap: () => setState(() => _categoryId = categoryId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String? sortBy) {
    final isSelected = _sortBy == sortBy;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = sortBy),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
