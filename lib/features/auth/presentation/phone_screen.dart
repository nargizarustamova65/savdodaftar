import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_models.dart';
import '../../../app/router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/widgets.dart';
import '../data/auth_models.dart';
import '../state/auth_providers.dart';
import '../state/auth_state.dart';

/// TZ 5-ekran: telefon raqami orqali ro'yxatdan o'tish / kirish.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final AppStrings s = context.s;
    final String input = _phoneController.text;

    if (!Phone.isValid(input)) {
      setState(() => _validationError = s.validationPhoneInvalid);
      return;
    }
    setState(() => _validationError = null);

    final OtpSendResult? result = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(phone: input);

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
        phone: Phone.national(input),
        resendAfter: result.resendAfter,
        expiresIn: result.expiresIn,
        purpose: OtpPurpose.login,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AuthState auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.authTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: <Widget>[
            Text(s.authSubtitle, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xxl),
            AppTextField(
              label: s.phoneLabel,
              hint: s.phoneHint,
              controller: _phoneController,
              errorText: _validationError,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofocus: true,
              inputFormatters: <TextInputFormatter>[PhoneTextInputFormatter()],
              prefixIcon: Icons.phone_outlined,
              onChanged: (String _) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                }
              },
              onSubmitted: (String _) => _sendCode(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(Phone.countryCode, style: textTheme.labelSmall),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: s.sendSmsCode,
              isLoading: auth.isBusy,
              onPressed: _sendCode,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: <Widget>[
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(s.orDivider, style: textTheme.labelSmall),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            // Google orqali kirish keyingi bosqichda yoqiladi (TZ 4-bo'lim).
            AppButton(
              label: s.continueWithGoogle,
              variant: AppButtonVariant.outline,
              icon: Icons.g_mobiledata_rounded,
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}
