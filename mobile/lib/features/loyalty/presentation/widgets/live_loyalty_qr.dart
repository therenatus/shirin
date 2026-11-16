import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/qr_token_cubit.dart';
import 'qr_code_widget.dart';

/// QR for the cash desk that refreshes itself.
///
/// Shows the one-time code (needed to pay with points). Without network it
/// falls back to the permanent [fallbackCode], which still lets the cashier
/// credit cashback, and says so under the code.
class LiveLoyaltyQr extends StatefulWidget {
  final String? fallbackCode;
  final double size;

  const LiveLoyaltyQr({super.key, required this.fallbackCode, this.size = 200});

  @override
  State<LiveLoyaltyQr> createState() => _LiveLoyaltyQrState();
}

class _LiveLoyaltyQrState extends State<LiveLoyaltyQr>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<QrTokenCubit>().start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    final cubit = context.read<QrTokenCubit>();
    if (lifecycle == AppLifecycleState.resumed) {
      cubit.start();
    } else if (lifecycle == AppLifecycleState.paused) {
      cubit.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QrTokenCubit, QrTokenState>(
      builder: (context, state) {
        final live = state.hasLiveCode;
        final code = live ? state.code : widget.fallbackCode;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (code == null)
              SizedBox(
                width: widget.size + 28,
                height: widget.size + 28,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else
              Semantics(
                label: 'QR-код карты лояльности',
                child: LoyaltyQrCodeWidget(data: code, size: widget.size),
              ),
            const SizedBox(height: 10),
            Text(
              live
                  ? 'Код обновляется автоматически'
                  : 'Нет связи: можно только начислить баллы',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        );
      },
    );
  }
}
