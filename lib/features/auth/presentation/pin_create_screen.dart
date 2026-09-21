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
import '../state/auth_providers.dart';

/// TZ 7-ekran: PIN yaratish -> PINni qayta kiritish -> Home.
class PinCreateScreen extends ConsumerStatefulWidget {
  const PinCreateScreen({super.key});

  @override
  ConsumerState<PinCreateScreen> createState() => _PinCreateScreenState();
}

class _PinCreateScreenState extends ConsumerState<PinCreateScreen> {
  String _pin = '';
  String? _firstPin;
  String? _errorText;

  bool get _isConfirmStep => _firstPin != null;

  void _onChanged(String value) {
    setState(() {
      _pin = value;
      _errorText = null;
    });
  }

  Future<void> _onCompleted(String value) async {
    final AppStrings s = context.s;

    if (!_isConfirmStep) {
      setState(() {
        _firstPin = value;
        _pin = '';
      });
      return;
    }

    if (value != _firstPin) {
      setState(() {
        _pin = '';
        _firstPin = null;
        _errorText = s.pinMismatch;
      });
      return;
    }

    final bool success =
        await ref.read(authControllerProvider.notifier).setPin(value);

    if (!mounted) {
      return;
    }

    if (!success) {
      final Object? error = ref.read(authControllerProvider).error;
      setState(() {
        _pin = '';
        _firstPin = null;
        _errorText = error == null ? s.errorUnknown : apiErrorText(s, error);
      });
      return;
    }

    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            children: <Widget>[
              Text(
                _isConfirmStep ? s.pinConfirmTitle : s.pinCreateTitle,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _isConfirmStep ? s.pinConfirmSubtitle : s.pinCreateSubtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              PinInput(
                value: _pin,
                length: AppConfig.pinLength,
                hasError: _errorText != null,
                onChanged: _onChanged,
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
              Text(s.pinRemember, style: textTheme.labelSmall),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
