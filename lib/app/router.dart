import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/auth/presentation/pin_create_screen.dart';
import '../features/auth/presentation/pin_unlock_screen.dart';
import '../features/auth/presentation/profile_setup_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/data/auth_models.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String phone = '/auth/phone';
  static const String otp = '/auth/otp';
  static const String profileSetup = '/auth/profile';
  static const String pinCreate = '/auth/pin-create';
  static const String pinUnlock = '/auth/pin-unlock';
  static const String home = '/home';
}

/// To'liq oqim (TZ 27-bo'lim):
/// - Birinchi kirish: Splash -> Onboarding -> Telefon -> OTP -> Profil -> PIN -> Home
/// - Qaytgan foydalanuvchi: Splash -> PIN unlock -> Home
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      builder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (BuildContext context, GoRouterState state) =>
          const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.phone,
      builder: (BuildContext context, GoRouterState state) =>
          const PhoneScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (BuildContext context, GoRouterState state) {
        final Object? extra = state.extra;
        // OTP ekrani argumentsiz ochilsa (masalan, deep link) telefon
        // ekraniga qaytaramiz — kod yuborilmasdan OTP kiritib bo'lmaydi.
        if (extra is! OtpArgs) {
          return const PhoneScreen();
        }
        return OtpScreen(args: extra);
      },
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      builder: (BuildContext context, GoRouterState state) =>
          const ProfileSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.pinCreate,
      builder: (BuildContext context, GoRouterState state) =>
          const PinCreateScreen(),
    ),
    GoRoute(
      path: AppRoutes.pinUnlock,
      builder: (BuildContext context, GoRouterState state) =>
          const PinUnlockScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (BuildContext context, GoRouterState state) => const AppShell(),
    ),
  ],
);
