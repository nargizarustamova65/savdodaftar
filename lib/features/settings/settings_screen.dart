import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/locale_provider.dart';
import '../../app/router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/widgets.dart';
import '../auth/data/auth_models.dart';
import '../auth/state/auth_providers.dart';
import '../billing/billing_screen.dart';
import '../customers/customers_screen.dart' show CustomerAvatar;
import '../expenses/expenses_screen.dart';
import '../reports/reports_screen.dart';
import 'pin_change_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _chooseLanguage(BuildContext context, WidgetRef ref) async {
    final AppStrings s = context.s;
    final String current = ref.read(localeControllerProvider).languageCode;
    final String? code = await showModalBottomSheet<String>(context: context, builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      for (final (String value, String label) in <(String, String)>[('uz', s.languageUz), ('ru', s.languageRu)]) ListTile(title: Text(label), trailing: value == current ? const Icon(Icons.check_rounded, color: AppColors.primary) : null, onTap: () => Navigator.of(context).pop(value)),
    ]))));
    if (code != null && code != current) {
      await ref.read(localeControllerProvider.notifier).setLocale(code);
      final AuthUser? user = ref.read(authControllerProvider).user;
      if (user != null && user.name.trim().isNotEmpty) await ref.read(authControllerProvider.notifier).saveProfile(name: user.name, shopName: user.shopName, businessType: user.businessType, locale: code);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final AppStrings s = context.s;
    final bool confirmed = await ConfirmDialog.show(context, title: s.logout, message: s.logoutConfirmBody, confirmLabel: s.logout, destructive: true);
    if (!confirmed || !context.mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.phone);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AuthUser? user = ref.watch(authControllerProvider).user;
    final Locale locale = ref.watch(localeControllerProvider);
    final String languageName = locale.languageCode == 'ru' ? s.languageRu : s.languageUz;
    return Scaffold(
      appBar: AppBar(title: Text(s.navSettings)),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.screen), children: <Widget>[
        if (user != null) ...<Widget>[AppCard(child: Row(children: <Widget>[CustomerAvatar(name: user.name.trim().isEmpty ? '—' : user.name, size: 52), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(user.name, style: Theme.of(context).textTheme.titleMedium), if (user.phone.isNotEmpty) Text(Phone.formatFull(user.phone), style: Theme.of(context).textTheme.bodySmall), if (user.shopName?.isNotEmpty == true) Text(user.shopName!, style: Theme.of(context).textTheme.bodySmall)]))])), const SizedBox(height: AppSpacing.lg)],
        _MenuItem(icon: Icons.workspace_premium_rounded, iconColor: AppColors.darkGreen, iconBackground: AppColors.lightGreen, label: 'Tariflar', trailingText: 'Standart / Pro', onTap: () => _push(context, const BillingScreen())),
        const SizedBox(height: AppSpacing.md),
        _MenuItem(icon: Icons.bar_chart_rounded, iconColor: AppColors.info, iconBackground: AppColors.infoSurface, label: s.navReports, onTap: () => _push(context, const ReportsScreen())),
        const SizedBox(height: AppSpacing.md),
        _MenuItem(icon: Icons.receipt_long_rounded, iconColor: AppColors.warning, iconBackground: AppColors.warningSurface, label: s.navExpenses, onTap: () => _push(context, const ExpensesScreen())),
        const SizedBox(height: AppSpacing.md),
        _MenuItem(icon: Icons.language_rounded, iconColor: AppColors.primary, iconBackground: AppColors.successSurface, label: s.languageLabel, trailingText: languageName, onTap: () => _chooseLanguage(context, ref)),
        const SizedBox(height: AppSpacing.md),
        _MenuItem(icon: Icons.pin_rounded, iconColor: AppColors.info, iconBackground: AppColors.infoSurface, label: s.changePinTitle, onTap: () => _push(context, const PinChangeScreen())),
        const SizedBox(height: AppSpacing.md),
        _MenuItem(icon: Icons.logout_rounded, iconColor: AppColors.danger, iconBackground: AppColors.dangerSurface, label: s.logout, onTap: () => _logout(context, ref)),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.iconColor, required this.iconBackground, required this.label, required this.onTap, this.trailingText});
  final IconData icon; final Color iconColor; final Color iconBackground; final String label; final VoidCallback onTap; final String? trailingText;
  @override
  Widget build(BuildContext context) => AppCard(padding: const EdgeInsets.all(AppSpacing.md), onTap: onTap, child: Row(children: <Widget>[Container(height: 40, width: 40, alignment: Alignment.center, decoration: BoxDecoration(color: iconBackground, borderRadius: AppRadius.field), child: Icon(icon, size: 20, color: iconColor)), const SizedBox(width: AppSpacing.md), Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)), if (trailingText != null) Text(trailingText!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)), const SizedBox(width: AppSpacing.xs), const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary)]));
}
