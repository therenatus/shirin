import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../../domain/entities/loyalty_transaction.dart';
import '../bloc/loyalty_bloc.dart';

/// Points history: earned / spent totals and a list of transactions on a
/// content card, iOS grouped-list style.
class PointsHistoryPage extends StatelessWidget {
  const PointsHistoryPage({super.key});

  void _reload(BuildContext context) =>
      context.read<LoyaltyBloc>().add(const LoadLoyaltyHistory());

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoyaltyBloc, LoyaltyState>(
      builder: (context, state) {
        return GlassPage(
          title: 'История баллов',
          onRefresh: () async => _reload(context),
          slivers: _buildBody(context, state),
        );
      },
    );
  }

  Widget _fill(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: child);

  Widget _message(IconData icon, String text, {Color color = AppColors.primary, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LiquidGlass(
              width: 112,
              height: 112,
              borderRadius: BorderRadius.circular(56),
              child: Center(child: Icon(icon, size: 48, color: color)),
            ),
            const SizedBox(height: 20),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, LoyaltyState state) {
    if (state is LoyaltyLoading) {
      return [
        _fill(const Center(child: CircularProgressIndicator(color: AppColors.primary))),
      ];
    }
    if (state is LoyaltyError) {
      return [
        _fill(_message(
          Icons.cloud_off_rounded,
          state.message,
          color: AppColors.error,
          action: GlassButton(
            label: 'Повторить',
            icon: Icons.refresh_rounded,
            onTap: () => _reload(context),
          ),
        )),
      ];
    }
    if (state is! LoyaltyHistoryLoaded) return const [];
    if (state.transactions.isEmpty) {
      return [_fill(_message(Icons.stars_rounded, 'Нет истории баллов'))];
    }

    final txs = state.transactions;
    final earned = txs
        .where((t) => t.type == LoyaltyTransactionType.earned)
        .fold<int>(0, (s, t) => s + t.amount);
    final spent = txs
        .where((t) => t.type == LoyaltyTransactionType.spent)
        .fold<int>(0, (s, t) => s + t.amount);

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.list(
          children: [
            Row(
              children: [
                Expanded(
                  child: _TotalTile(
                    label: 'Начислено',
                    value: '+$earned',
                    color: AppColors.success,
                    icon: Icons.add_circle_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TotalTile(
                    label: 'Списано',
                    value: '-$spent',
                    color: AppColors.error,
                    icon: Icons.remove_circle_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ContentCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < txs.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.only(left: 68),
                        child: Divider(height: 1, color: AppColors.divider),
                      ),
                    _TransactionRow(tx: txs[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _TotalTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TotalTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.price.copyWith(fontSize: 22, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final LoyaltyTransaction tx;
  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isEarned = tx.type == LoyaltyTransactionType.earned;
    final color = isEarned ? AppColors.success : AppColors.error;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(
              isEarned ? Icons.add_rounded : Icons.remove_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description, style: AppTextStyles.label.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(_formatDate(tx.date), style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isEarned ? '+' : '-'}${tx.amount}',
            style: AppTextStyles.price.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
