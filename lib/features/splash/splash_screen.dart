import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../auth/state/auth_providers.dart';
import '../auth/state/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Status bar va navigation bar ranglari
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.darkGreen,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Splash kamida 1.5 sekund ko'rinadi
    final Future<void> minSplash = Future<void>.delayed(
      const Duration(milliseconds: 1500),
    );

    // restore 5 sekunddan ko'p kutib qolmasin
    try {
      await Future.any<void>([
        ref.read(authControllerProvider.notifier).restore(),
        Future<void>.delayed(const Duration(seconds: 5)),
      ]);
    } catch (e) {
      debugPrint('Auth restore error: $e');
    }

    // Minimal splash vaqtini kutamiz
    await minSplash;

    if (!mounted) return;

    final AuthStatus status =
        ref.read(authControllerProvider).status;

    switch (status) {
      case AuthStatus.locked:
        context.go(AppRoutes.pinUnlock);
        break;

      case AuthStatus.needsProfile:
        context.go(AppRoutes.profileSetup);
        break;

      case AuthStatus.needsPin:
        context.go(AppRoutes.pinCreate);
        break;

      case AuthStatus.authenticated:
        context.go(AppRoutes.home);
        break;

      case AuthStatus.unknown:
      case AuthStatus.unauthenticated:
        final bool seen =
        await ref.read(tokenStorageProvider).isOnboardingSeen();

        if (!mounted) return;

        context.go(
          seen
              ? AppRoutes.phone
              : AppRoutes.onboarding,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // MARKAZDAGI LOGO VA NOM
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 58,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App nomi
                    Text(
                      s.appName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Slogan
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                      ),
                      child: Text(
                        s.slogan,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // PASTKI LOADER
            Positioned(
              left: 0,
              right: 0,
              bottom: 55,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}