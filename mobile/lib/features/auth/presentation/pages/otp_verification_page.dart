import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/liquid_glass/liquid_glass_kit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// SMS code entry. Same quiet layout as the phone screen: large title,
/// glass capsule cells, one prominent action.
class OtpVerificationPage extends StatefulWidget {
  final String phone;

  const OtpVerificationPage({super.key, required this.phone});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  Timer? _timer;
  int _secondsRemaining = AppConstants.otpResendSeconds;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = AppConstants.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        t.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _verify(String code) {
    if (code.length != AppConstants.otpLength) return;
    HapticFeedback.mediumImpact();
    setState(() => _hasError = false);
    context.read<AuthBloc>().add(
      VerifyCodeRequested(phone: widget.phone, code: code),
    );
  }

  void _onCodeChanged(String value) {
    if (_hasError) setState(() => _hasError = false);
    // Auto-submit once all digits are in (also covers SMS autofill / paste).
    if (value.length == AppConstants.otpLength) _verify(value);
  }

  void _resend() {
    HapticFeedback.lightImpact();
    _codeController.clear();
    setState(() => _hasError = false);
    context.read<AuthBloc>().add(SendCodeRequested(widget.phone));
    _startTimer();
  }

  void _back() => context.canPop() ? context.pop() : context.go('/login');

  String _prettyPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length == 12) {
      return '+${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6, 8)} ${d.substring(8, 10)} ${d.substring(10)}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          setState(() => _hasError = true);
          HapticFeedback.heavyImpact();
          showGlassToast(
            context,
            state.message,
            icon: Icons.error_outline_rounded,
          );
        }
      },
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GlassIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            iconSize: 19,
                            tooltip: 'Назад',
                            onTap: _back,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          'КОД ИЗ SMS',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Введите код',
                          style: AppTextStyles.display,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Отправили 4 цифры на номер\n',
                              ),
                              TextSpan(
                                text: _prettyPhone(widget.phone),
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 15,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const TextSpan(text: '  '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: _back,
                                  child: Text(
                                    'Изменить',
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 36),
                        _GlassCodeInput(
                          controller: _codeController,
                          focusNode: _codeFocus,
                          length: AppConstants.otpLength,
                          hasError: _hasError,
                          onChanged: _onCodeChanged,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _hasError
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Код не подошёл. Проверьте цифры или запросите новый.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        const SizedBox(height: 28),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final loading = state is AuthLoading;
                            return GlassButton(
                              label: 'Подтвердить',
                              prominent: true,
                              expanded: true,
                              loading: loading,
                              onTap: loading
                                  ? null
                                  : () => _verify(_codeController.text),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _secondsRemaining > 0
                                ? Padding(
                                    key: const ValueKey('timer'),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      'Отправить код ещё раз через $mm:$ss',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  )
                                : GlassChip(
                                    key: const ValueKey('resend'),
                                    label: 'Отправить код ещё раз',
                                    icon: Icons.refresh_rounded,
                                    onTap: _resend,
                                  ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of glass capsule cells over one invisible [TextField], which is the
/// first text field on the page (integration test enters the code into it).
/// The field receives taps, paste and iOS one-time-code autofill.
class _GlassCodeInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _GlassCodeInput({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_GlassCodeInput> createState() => _GlassCodeInputState();
}

class _GlassCodeInputState extends State<_GlassCodeInput> {
  static const double _cellHeight = 72;
  static const double _maxCellWidth = 64;
  static const double _gap = 12;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    widget.focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final focused = widget.focusNode.hasFocus;

    // Fixed height outside the LayoutBuilder: SliverFillRemaining asks for
    // intrinsic height, which LayoutBuilder cannot answer.
    return SizedBox(
      height: _cellHeight,
      child: LayoutBuilder(
        builder: (context, c) {
          final fit = (c.maxWidth - _gap * (widget.length - 1)) / widget.length;
          final cellWidth = fit.clamp(44.0, _maxCellWidth);

          return SizedBox(
            height: _cellHeight,
            child: Stack(
              children: [
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.length; i++) ...[
                        if (i > 0) const SizedBox(width: _gap),
                        _CodeCell(
                          width: cellWidth,
                          height: _cellHeight,
                          digit: i < code.length ? code[i] : null,
                          active:
                              focused &&
                              (i == code.length ||
                                  (code.length == widget.length &&
                                      i == widget.length - 1)),
                          error: widget.hasError,
                        ),
                      ],
                    ],
                  ),
                ),
                // Invisible input on top: receives taps, paste and autofill.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: widget.length,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: widget.onChanged,
                      style: const TextStyle(color: Colors.transparent),
                      decoration: const InputDecoration(
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CodeCell extends StatelessWidget {
  final double width;
  final double height;
  final String? digit;
  final bool active;
  final bool error;

  const _CodeCell({
    required this.width,
    required this.height,
    required this.digit,
    required this.active,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(width / 2);
    final ringColor = error
        ? AppColors.error.withValues(alpha: 0.7)
        : active
        ? AppColors.primary.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0);

    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      scale: active ? 1.05 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: ringColor, width: 1.5),
        ),
        child: LiquidGlass(
          width: width,
          height: height,
          borderRadius: radius,
          style: GlassStyle.regular.copyWith(
            shadowOpacity: active ? 0.16 : 0.08,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: digit != null
                  ? Text(
                      digit!,
                      key: ValueKey('d$digit'),
                      style: AppTextStyles.heading1.copyWith(
                        color: error ? AppColors.error : AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    )
                  : active
                  ? Container(
                      key: const ValueKey('cursor'),
                      width: 2,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    )
                  : Container(
                      key: const ValueKey('dot'),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
