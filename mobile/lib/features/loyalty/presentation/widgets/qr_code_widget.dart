import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// QR code on a crisp white tile so cashier scanners read it reliably.
class LoyaltyQrCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const LoyaltyQrCodeWidget({super.key, required this.data, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.primary,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
