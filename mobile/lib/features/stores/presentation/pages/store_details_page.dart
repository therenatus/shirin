import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../domain/entities/store.dart';

class StoreDetailsPage extends StatelessWidget {
  final Store store;

  const StoreDetailsPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(store.name, style: AppTextStyles.heading3),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + kToolbarHeight + 20,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.store,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Address
              _buildInfoRow(
                icon: Icons.location_on_outlined,
                title: 'Адрес',
                value: store.address,
              ),

              // Working hours
              if (store.workingHours != null)
                _buildInfoRow(
                  icon: Icons.access_time,
                  title: 'Режим работы',
                  value: store.workingHours!,
                ),

              // Phone
              if (store.phone != null)
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  title: 'Телефон',
                  value: store.phone!,
                  onTap: () => _callPhone(store.phone!),
                ),

              const SizedBox(height: 32),

              // Call button
              if (store.phone != null)
                AppButton(
                  label: 'Позвонить',
                  icon: Icons.phone,
                  onPressed: () => _callPhone(store.phone!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 20,
        enableBlur: false,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: onTap != null ? AppColors.primary : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
