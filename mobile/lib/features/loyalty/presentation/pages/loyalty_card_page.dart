import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../bloc/loyalty_bloc.dart';
import '../widgets/qr_code_widget.dart';

class LoyaltyCardPage extends StatelessWidget {
  const LoyaltyCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: 'Карта лояльности'),
      body: GradientBackground(
        child: BlocBuilder<LoyaltyBloc, LoyaltyState>(
          builder: (context, state) {
            if (state is LoyaltyLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LoyaltyError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<LoyaltyBloc>()
                          .add(const LoadLoyaltyInfo()),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }
            if (state is LoyaltyInfoLoaded) {
              final info = state.info;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + kToolbarHeight + 24,
                  20,
                  32,
                ),
                child: Column(
                  children: [
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Уровень: ${info.level}',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Points
                    Text(
                      '${info.points}',
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'баллов',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // QR Code
                    if (info.qrCode != null) ...[
                      LoyaltyQrCodeWidget(data: info.qrCode!),
                      const SizedBox(height: 12),
                      Text(
                        'Покажите QR-код на кассе',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // History button
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'История баллов',
                        variant: AppButtonVariant.outlined,
                        icon: Icons.history,
                        onPressed: () => context.push('/loyalty/history'),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
