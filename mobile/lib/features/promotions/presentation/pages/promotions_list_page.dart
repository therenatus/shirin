import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../bloc/promotions_bloc.dart';
import '../widgets/promotion_card.dart';

/// Promotions: large title over the liquid background and a list of
/// promotion cards. Pull to refresh.
class PromotionsListPage extends StatelessWidget {
  const PromotionsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromotionsBloc, PromotionsState>(
      builder: (context, state) {
        return GlassPage(
          title: 'Акции',
          eyebrow: 'Кондитерская Ширин',
          onRefresh: () async =>
              context.read<PromotionsBloc>().add(const LoadPromotions()),
          slivers: _buildBody(context, state),
        );
      },
    );
  }

  List<Widget> _buildBody(BuildContext context, PromotionsState state) {
    if (state is PromotionsError) {
      return [
        SliverToBoxAdapter(
          child: _Message(
            icon: Icons.cloud_off_rounded,
            text: state.message,
            action: GlassButton(
              label: 'Повторить',
              icon: Icons.refresh_rounded,
              onTap: () =>
                  context.read<PromotionsBloc>().add(const LoadPromotions()),
            ),
          ),
        ),
      ];
    }
    if (state is PromotionsLoaded) {
      if (state.promotions.isEmpty) {
        return const [
          SliverToBoxAdapter(
            child: _Message(
              icon: Icons.local_offer_outlined,
              text: 'Нет активных акций',
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: state.promotions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) =>
                PromotionCard(promotion: state.promotions[index]),
          ),
        ),
      ];
    }
    if (state is PromotionsLoading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 96),
            child: LoadingWidget(),
          ),
        ),
      ];
    }
    return const [];
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Message({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 64, 40, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: AppColors.textLight),
          ),
          const SizedBox(height: 20),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}
