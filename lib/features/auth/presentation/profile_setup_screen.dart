import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../state/auth_providers.dart';
import '../state/auth_state.dart';

/// TZ 5-ekran (OTP dan keyingi qism): ism, do'kon nomi va savdo turi.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shopController = TextEditingController();
  int _businessTypeIndex = 0;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _shopController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppStrings s = context.s;
    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _nameError = s.validationNameRequired);
      return;
    }
    setState(() => _nameError = null);

    final bool success =
        await ref.read(authControllerProvider.notifier).saveProfile(
              name: name,
              shopName: _shopController.text.trim(),
              businessType: AppStrings.businessTypeKeys[_businessTypeIndex],
              locale: s.localeCode,
            );

    if (!mounted) {
      return;
    }

    if (!success) {
      final Object? error = ref.read(authControllerProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorText(context.s, error))),
        );
      }
      return;
    }

    final AuthStatus status = ref.read(authControllerProvider).status;
    context.go(
      status == AuthStatus.authenticated
          ? AppRoutes.home
          : AppRoutes.pinCreate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AuthState auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.profileTitle), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: <Widget>[
                  Text(s.profileSubtitle, style: textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xxl),
                  AppTextField(
                    label: s.nameLabel,
                    hint: s.nameHint,
                    controller: _nameController,
                    errorText: _nameError,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    prefixIcon: Icons.person_outline_rounded,
                    onChanged: (String _) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: s.shopNameLabel,
                    hint: s.shopNameHint,
                    controller: _shopController,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(s.businessTypeQuestion, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.md),
                  AppFilterChips(
                    labels: s.businessTypes,
                    selectedIndex: _businessTypeIndex,
                    padding: EdgeInsets.zero,
                    onSelected: (int index) =>
                        setState(() => _businessTypeIndex = index),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: AppButton(
                label: s.continueLabel,
                isLoading: auth.isBusy,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
