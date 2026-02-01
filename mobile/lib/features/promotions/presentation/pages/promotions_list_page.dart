import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/glass_app_bar.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../bloc/promotions_bloc.dart';
import '../widgets/promotion_card.dart';

class PromotionsListPage extends StatelessWidget {
  const PromotionsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: 'Акции'),
      body: GradientBackground(
        child: BlocBuilder<PromotionsBloc, PromotionsState>(
          builder: (context, state) {
            if (state is PromotionsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PromotionsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<PromotionsBloc>()
                          .add(const LoadPromotions()),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }
            if (state is PromotionsLoaded) {
              if (state.promotions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_offer_outlined,
                          size: 64, color: AppColors.divider),
                      const SizedBox(height: 16),
                      Text(
                        'Нет активных акций',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context
                      .read<PromotionsBloc>()
                      .add(const LoadPromotions());
                },
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    16,
                    32,
                  ),
                  itemCount: state.promotions.length,
                  itemBuilder: (context, index) {
                    return PromotionCard(
                        promotion: state.promotions[index]);
                  },
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
