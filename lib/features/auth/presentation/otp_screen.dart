import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/widgets.dart';
import '../data/auth_models.dart';
import '../state/auth_providers.dart';
import '../state/auth_state.dart';
import 'widgets/otp_field.dart';

/// OTP ekraniga uzatiladigan argumentlar.


/// TZ 6-ekran: SMS kodini tasdiqlash.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.args});

  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.args.resendAfter);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    if (seconds <= 0) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) {
        timer.cancel();
      }
    });
  }

  void _showError(Object? error) {
    if (error == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(apiErrorText(context.s, error))),
    );
  }

  Future<void> _resend() async {
    final OtpSendResult? result = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(phone: widget.args.phone, purpose: widget.args.purpose);

    if (!mounted) {
      return;
    }
    if (result == null) {
      _showError(ref.read(authControllerProvider).error);
      return;
    }
    _codeController.clear();
    setState(() => _hasError = false);
    _startCountdown(result.resendAfter);
  }

  Future<void> _verify() async {
    final AppStrings s = context.s;
    final String code = _codeController.text;

    if (code.length != AppConfig.otpLength) {
      setState(() => _hasError = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.validationOtpInvalid)));
      return;
    }

    final bool success = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(
          phone: widget.args.phone,
          code: code,
          purpose: widget.args.purpose,
        );

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() => _hasError = true);
      _showError(ref.read(authControllerProvider).error);
      return;
    }

    // PIN tiklash oqimi: OTP tasdiqlangach yangi PIN o'rnatiladi (TZ 37).
    if (widget.args.purpose == OtpPurpose.resetPin) {
      context.go(AppRoutes.pinCreate);
      return;
    }

    final AuthStatus status = ref.read(authControllerProvider).status;
    switch (status) {
      case AuthStatus.needsProfile:
        context.go(AppRoutes.profileSetup);
      case AuthStatus.needsPin:
        context.go(AppRoutes.pinCreate);
      case AuthStatus.locked:
      case AuthStatus.authenticated:
        context.go(AppRoutes.home);
      case AuthStatus.unknown:
      case AuthStatus.unauthenticated:
        context.go(AppRoutes.phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AuthState auth = ref.watch(authControllerProvider);
    final bool canResend = _secondsLeft <= 0 && !auth.isBusy;

    return Scaffold(
      appBar: AppBar(title: Text(s.otpTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: <Widget>[
            Text(s.otpSubtitle, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              Phone.formatFull(widget.args.phone),
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xxl),
            OtpField(
              controller: _codeController,
              length: AppConfig.otpLength,
              hasError: _hasError,
              onChanged: (String _) {
                if (_hasError) {
                  setState(() => _hasError = false);
                }
              },
              onCompleted: (String _) => _verify(),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  canResend ? s.otpResend : s.otpResendIn(_secondsLeft),
                  style: textTheme.labelMedium?.copyWith(
                    color: canResend ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: s.continueLabel,
              isLoading: auth.isBusy,
              onPressed: _verify,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  s.back,
                  style: textTheme.labelMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
