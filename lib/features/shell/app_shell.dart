import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/l10n/app_strings.dart';
import '../auth/state/auth_providers.dart';
import '../auth/state/auth_state.dart';
import '../customers/customers_screen.dart';
import '../debts/debts_screen.dart';
import '../home/home_screen.dart';
import '../inventory/inventory_screen.dart';
import '../settings/settings_screen.dart';

/// TZ 26-bo'lim: doimiy ko'rinadigan pastki navigatsiya —
/// Bosh sahifa | Mijozlar | Qarzlar | Ombor | Sozlamalar.
///
/// IndexedStack ishlatiladi: bo'lim almashtirilganda scroll holati saqlanadi.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// TZ 23: ilova fonga o'tganda sessiya bloklanadi — qaytganda PIN so'raladi.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(authControllerProvider.notifier).lock();
      return;
    }
    if (state == AppLifecycleState.resumed &&
        ref.read(authControllerProvider).status == AuthStatus.locked) {
      context.go(AppRoutes.pinUnlock);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;

    // Sessiya bekor bo'lsa (401 / logout) — login oqimiga qaytariladi.
    ref.listen<AuthState>(authControllerProvider,
        (AuthState? previous, AuthState next) {
      if (next.status == AuthStatus.unauthenticated) {
        context.go(AppRoutes.phone);
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          HomeScreen(),
          CustomersScreen(),
          DebtsScreen(),
          InventoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: s.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: s.navCustomers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: s.navDebts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2_rounded),
            label: s.navInventory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: s.navSettings,
          ),
        ],
      ),
    );
  }
}
