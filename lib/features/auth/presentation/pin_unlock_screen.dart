import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../data/auth_models.dart';
import '../state/auth_providers.dart';
import 'otp_screen.dart';

/// Keyingi kirishlar: Splash -> PIN -> Home (TZ 38-bo'lim).
class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  String _pin = '';
  String? _errorText;

  Future<void> _onCompleted(String value) async {
    final bool success =
        await ref.read(authControllerProvider.notifier).verifyPin(value);

    if (!mounted) {
      return;
    }

    if (!success) {
      final Object? error = ref.read(authControllerProvider).error;
      setState(() {
        _pin = '';
        _errorText = error == null ? context.s.errorUnknown : apiErrorText(context.s, error);
      });
      return;
    }

    context.go(AppRoutes.home);
  }

  /// TZ 33-bo'lim: PIN kodni unutdim -> SMS OTP -> yangi PIN.
  Future<void> _forgotPin() async {
    final String? phone = ref.read(authControllerProvider).user?.phone;
    if (phone == null || phone.isEmpty) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go(AppRoutes.phone);
      }
      return;
    }

    final OtpSendResult? result = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(phone: phone, purpose: OtpPurpose.resetPin);

    if (!mounted) {
      return;
    }

    if (result == null) {
      final Object? error = ref.read(authControllerProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorText(context.s, error))),
        );
      }
      return;
    }

    context.push(
      AppRoutes.otp,
      extra: OtpArgs(
        phone: phone,
        resendAfter: result.resendAfter,
        expiresIn: result.expiresIn,
        purpose: OtpPurpose.resetPin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? userName = ref.watch(authControllerProvider).user?.name;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.xxxl),
              Container(
                height: 64,
                width: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                userName == null || userName.isEmpty
                    ? s.pinUnlockTitle
                    : '${s.greeting} $userName',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.pinUnlockSubtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              PinInput(
                value: _pin,
                length: AppConfig.pinLength,
                hasError: _errorText != null,
                onChanged: (String value) => setState(() {
                  _pin = value;
                  _errorText = null;
                }),
                onCompleted: _onCompleted,
              ),
              if (_errorText != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: _forgotPin,
                child: Text(
                  s.pinForgot,
                  style: textTheme.labelMedium
                      ?.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
