import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Login: big friendly title, a glass phone capsule with the +996 prefix chip
/// inside, one prominent glass action and small legal text at the bottom.
class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isValid = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    setState(() => _isValid = value.length == AppConstants.phoneLength);
  }

  void _onSendCode() {
    if (!_isValid) return;
    HapticFeedback.mediumImpact();
    final phone = '${AppConstants.phonePrefix}${_phoneController.text}';
    context.read<AuthBloc>().add(SendCodeRequested(phone));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is CodeSent) {
          context.push('/otp', extra: state.phone);
        } else if (state is AuthError) {
          showGlassToast(
            context,
            state.message,
            icon: Icons.error_outline_rounded,
          );
        }
      },
      // Background sits outside the Scaffold so it stays full-screen while
      // the Scaffold body resizes for the keyboard.
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  // No scrolling: when the keyboard opens the hero scales
                  // down so the sign-in panel always stays above it.
                  child: Column(
                    children: [
                      // Brand hero, centred in the space above the form.
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: MediaQuery.sizeOf(context).width - 56,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 12),
                                    const _HeroMark(),
                                    const SizedBox(height: 20),
                                    Text(
                                      'КОНДИТЕРСКАЯ ШИРИН',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.overline.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Добро пожаловать',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.display,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Заказывайте любимые десерты и копите '
                                      'бонусы за каждую покупку',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Sign-in panel docked at the bottom (iOS sheet style).
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: LiquidGlass(
                          style: GlassStyle.thick,
                          borderRadius: BorderRadius.circular(34),
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PhoneField(
                                controller: _phoneController,
                                focusNode: _focusNode,
                                isFocused: _isFocused,
                                isValid: _isValid,
                                onChanged: _onPhoneChanged,
                                onSubmitted: (_) => _onSendCode(),
                              ),
                              const SizedBox(height: 14),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is AuthLoading;
                                  return GlassButton(
                                    label: 'Получить код',
                                    prominent: true,
                                    expanded: true,
                                    loading: isLoading,
                                    onTap: _isValid && !isLoading
                                        ? _onSendCode
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              const _TermsNote(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shirin logo in a glass halo with a soft brand glow, surrounded by small
/// glass bubbles that drift slowly.
class _HeroMark extends StatefulWidget {
  const _HeroMark();

  @override
  State<_HeroMark> createState() => _HeroMarkState();
}

class _HeroMarkState extends State<_HeroMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  // (offset from centre, diameter, phase)
  static const _bubbles = [
    (Offset(-96, -54), 30.0, 0.0),
    (Offset(102, -30), 44.0, 0.35),
    (Offset(-108, 48), 20.0, 0.6),
    (Offset(88, 64), 24.0, 0.8),
    (Offset(-40, -92), 14.0, 0.2),
  ];

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 220,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, _) {
          final t = _float.value * 2 * math.pi;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Brand glow.
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.32),
                      AppColors.primaryLight.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              for (final (offset, size, phase) in _bubbles)
                Transform.translate(
                  offset:
                      offset +
                      Offset(
                        math.sin(t + phase * 2 * math.pi) * 4,
                        math.cos(t + phase * 2 * math.pi) * 7,
                      ),
                  child: LiquidGlass(
                    style: GlassStyle.clear.copyWith(shadowOpacity: 0.10),
                    width: size,
                    height: size,
                    borderRadius: BorderRadius.circular(size / 2),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, math.sin(t) * 3),
                child: LiquidGlass(
                  style: GlassStyle.clear.copyWith(shadowOpacity: 0.22),
                  width: 132,
                  height: 132,
                  borderRadius: const BorderRadius.all(Radius.circular(42)),
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      // Concentric: 42 − 12.
                      borderRadius: BorderRadius.circular(30),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.cake_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Glass capsule: [🇰🇬 +996] chip, digits field, success check.
/// The [TextField] here is the first one on the page (integration test).
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isValid;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isValid,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final digitStyle = AppTextStyles.heading3.copyWith(
      fontSize: 20,
      letterSpacing: 1.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text('Номер телефона', style: AppTextStyles.label),
        ),
        AnimatedContainer(
          duration: AppConstants.animationFast,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isFocused
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0),
              width: 1.5,
            ),
          ),
          // Solid field inside the glass panel: no glass on glass.
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(
                    alpha: isFocused ? 0.10 : 0.05,
                  ),
                  blurRadius: 16,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: focusNode.requestFocus,
              child: Row(
                children: [
                  // Country prefix chip (solid, no glass-on-glass).
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🇰🇬', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          AppConstants.phonePrefix,
                          style: digitStyle.copyWith(
                            fontSize: 16,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumberLocal],
                      maxLength: AppConstants.phoneLength,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: digitStyle,
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: '--- -- -- --',
                        hintStyle: digitStyle.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: isValid ? 1 : 0,
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsNote extends StatelessWidget {
  const _TermsNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => launchUrl(
          Uri.parse(ApiEndpoints.privacyUrl),
          mode: LaunchMode.inAppBrowserView,
        ),
        child: Text.rich(
          TextSpan(
            style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
            children: [
              const TextSpan(
                  text: 'Нажимая «Получить код», вы соглашаетесь\nс '),
              TextSpan(
                text: 'политикой конфиденциальности',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
