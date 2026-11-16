import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Splash: the logo floats on the liquid background inside a softly breathing
/// glass halo; a small glass capsule shows progress at the bottom.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _haloAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _haloAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textSlideAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textOpacityAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    // Gentle breathing of the halo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
    });

    // Check auth after splash
    Future.delayed(AppConstants.splashDuration, () {
      if (mounted) {
        context.read<AuthBloc>().add(const CheckAuthStatus());
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
        } else if (state is Unauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LiquidBackground(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge(
                        [_logoController, _pulseController],
                      ),
                      builder: (context, _) {
                        final pulse = Curves.easeInOut
                            .transform(_pulseController.value);
                        return Opacity(
                          opacity: _opacityAnimation.value,
                          child: SizedBox(
                            width: 240,
                            height: 240,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Soft brand glow
                                Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.primary.withValues(
                                          alpha: 0.18 + pulse * 0.06,
                                        ),
                                        AppColors.primary.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                                // Glass halo
                                Transform.scale(
                                  scale: _haloAnimation.value *
                                      (1 + pulse * 0.035),
                                  child: const LiquidGlass(
                                    style: GlassStyle.clear,
                                    width: 184,
                                    height: 184,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(92)),
                                  ),
                                ),
                                // Logo
                                Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: const _Logo(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) => Opacity(
                        opacity: _textOpacityAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlideAnimation.value),
                          child: child,
                        ),
                      ),
                      child: Text(
                        'Сладости с любовью',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Loading capsule at the bottom
              Positioned(
                bottom: bottomInset + 40,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _textOpacityAnimation,
                  child: Center(
                    child: LiquidGlass.capsule(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Загрузка...',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      height: 124,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => const Icon(
          Icons.cake_rounded,
          size: 56,
          color: Colors.white,
        ),
      ),
    );
  }
}
