import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../auth/state/auth_providers.dart';
import '../auth/state/auth_state.dart';

/// TZ 1-ekran: to'liq Dark Green fon, markazda logo va slogan.
/// Fonda sessiya tekshiriladi va holatga qarab yo'naltiriladi (TZ 27, 37).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Token bo'lsa `/auth/me` orqali holat aniqlanadi:
  /// - PIN mavjud -> PIN unlock
  /// - profil to'liq emas -> profil ekrani
  /// - PIN yaratilmagan -> PIN yaratish
  /// - token yo'q -> Onboarding -> Telefon
  Future<void> _bootstrap() async {
    final Future<void> minSplash =
        Future<void>.delayed(const Duration(milliseconds: 1800));
    await ref.read(authControllerProvider.notifier).restore();
    await minSplash;

    if (!mounted) {
      return;
    }

    final AuthStatus status = ref.read(authControllerProvider).status;
    switch (status) {
      case AuthStatus.locked:
        context.go(AppRoutes.pinUnlock);
      case AuthStatus.needsProfile:
        context.go(AppRoutes.profileSetup);
      case AuthStatus.needsPin:
        context.go(AppRoutes.pinCreate);
      case AuthStatus.authenticated:
        context.go(AppRoutes.home);
      case AuthStatus.unknown:
      case AuthStatus.unauthenticated:
        // Onboarding faqat birinchi ochilishda ko'rsatiladi (TZ 3).
        final bool seen =
            await ref.read(tokenStorageProvider).isOnboardingSeen();
        if (!mounted) {
          return;
        }
        context.go(seen ? AppRoutes.phone : AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Spacer(),
            Container(
              height: 96,
              width: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: AppRadius.large,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              s.appName,
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Text(
                s.slogan,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
