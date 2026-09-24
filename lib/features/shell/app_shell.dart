import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme_provider.dart';
import '../tools/tools_screens.dart';
import '../tools/referral_currency_screens.dart';
import '../home/home_screen.dart';
import '../customers/customers_screen.dart';
import '../debts/debts_screen.dart';
import '../inventory/inventory_screen.dart';
import '../settings/settings_screen.dart';
import '../../app/router.dart';
import '../../core/l10n/app_strings.dart';
import '../auth/state/auth_providers.dart';

class AppShell extends ConsumerStatefulWidget { const AppShell({super.key}); @override ConsumerState<AppShell> createState()=>_AppShellState(); }
class _AppShellState extends ConsumerState<AppShell> { int index=0; @override Widget build(BuildContext context){final s=context.s; return Scaffold(body:IndexedStack(index:index,children:const[HomeScreen(),CustomersScreen(),DebtsScreen(),InventoryScreen(),SettingsScreen()]),floatingActionButton:const CalculatorFab(),bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:[NavigationDestination(icon:const Icon(Icons.home),label:s.navHome),NavigationDestination(icon:const Icon(Icons.people),label:s.navCustomers),NavigationDestination(icon:const Icon(Icons.wallet),label:s.navDebts),NavigationDestination(icon:const Icon(Icons.inventory_2),label:s.navInventory),NavigationDestination(icon:const Icon(Icons.settings),label:s.navSettings)]));} }
