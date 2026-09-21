import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/widgets.dart';
import '../auth/state/auth_providers.dart';

/// TZ 23: PIN kodni almashtirish — joriy PIN, keyin yangi PIN (2 marta).
class PinChangeScreen extends ConsumerStatefulWidget {
  const PinChangeScreen({super.key});

  @override
  ConsumerState<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends ConsumerState<PinChangeScreen> {
  String _pin = '';
  String? _currentPin;
  String? _newPin;
  String? _errorText;
  bool _isBusy = false;

  String _title(AppStrings s) {
    if (_currentPin == null) {
      return s.changePinTitle;
    }
    return _newPin == null ? s.pinCreateTitle : s.pinConfirmTitle;
  }

  String _subtitle(AppStrings s) {
    if (_currentPin == null) {
      return s.pinCurrentSubtitle;
    }
    return _newPin == null ? s.pinCreateSubtitle : s.pinConfirmSubtitle;
  }

  void _onChanged(String value) {
    if (_isBusy) {
      return;
    }
    setState(() {
      _pin = value;
      _errorText = null;
    });
  }

  Future<void> _onCompleted(String value) async {
    if (_isBusy) {
      return;
    }
    final AppStrings s = context.s;

    if (_currentPin == null) {
      setState(() {
        _currentPin = value;
        _pin = '';
      });
      return;
    }

    if (_newPin == null) {
      setState(() {
        _newPin = value;
        _pin = '';
      });
      return;
    }

    if (value != _newPin) {
      setState(() {
        _pin = '';
        _newPin = null;
        _errorText = s.pinMismatch;
      });
      return;
    }

    setState(() => _isBusy = true);
    final bool success = await ref
        .read(authControllerProvider.notifier)
        .setPin(value, currentPin: _currentPin);

    if (!mounted) {
      return;
    }

    if (!success) {
      final Object? error = ref.read(authControllerProvider).error;
      setState(() {
        _isBusy = false;
        _pin = '';
        _currentPin = null;
        _newPin = null;
        _errorText = error == null ? s.errorUnknown : apiErrorText(s, error);
      });
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.pinChanged)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(s.changePinTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.xxl),
              Text(
                _title(s),
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _subtitle(s),
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
                  style:
                      textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              if (_isBusy) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
