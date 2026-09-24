import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/widgets.dart';
import '../tools/tools_screens.dart';
import '../tools/referral_currency_screens.dart';
import '../billing/billing_screen.dart';
import '../auth/state/auth_providers.dart';
import '../../app/locale_provider.dart';
import '../../app/router.dart';
import '../../core/l10n/app_strings.dart';
import '../auth/data/auth_models.dart';
import '../customers/customers_screen.dart' show CustomerAvatar;
import '../expenses/expenses_screen.dart';
import '../reports/reports_screen.dart';
import 'pin_change_screen.dart';

class SettingsScreen extends ConsumerWidget { const SettingsScreen({super.key}); void push(BuildContext c,Widget w)=>Navigator.of(c).push(MaterialPageRoute<void>(builder:(_)=>w)); @override Widget build(BuildContext context,WidgetRef ref){final s=context.s; final user=ref.watch(authControllerProvider).user; final dark=ref.watch(themeModeProvider)==ThemeMode.dark; return Scaffold(appBar:AppBar(title:Text(s.navSettings)),body:ListView(padding:const EdgeInsets.all(AppSpacing.screen),children:[if(user!=null) AppCard(child:Row(children:[CustomerAvatar(name:user.name,size:52),const SizedBox(width:12),Text(user.name)])),const SizedBox(height:16),SwitchListTile(title:const Text('Dark rejim'),secondary:const Icon(Icons.dark_mode),value:dark,onChanged:(v)=>ref.read(themeModeProvider.notifier).state=v?ThemeMode.dark:ThemeMode.light),_item(context,Icons.workspace_premium,'Tariflar',()=>push(context,const BillingScreen())),_item(context,Icons.support_agent,'Qo‘llab-quvvatlash',()=>push(context,const SupportScreen())),_item(context,Icons.video_library,'Qo‘llanma videolari',()=>push(context,const GuideScreen())),_item(context,Icons.card_giftcard,'Referal link va bonuslar',()=>push(context,const ReferralScreen())),_item(context,Icons.currency_exchange,'Valyuta kurslari (CBU)',()=>push(context,const CurrencyScreen())),_item(context,Icons.bar_chart,s.navReports,()=>push(context,const ReportsScreen())),_item(context,Icons.receipt_long,s.navExpenses,()=>push(context,const ExpensesScreen())),_item(context,Icons.pin,s.changePinTitle,()=>push(context,const PinChangeScreen())),_item(context,Icons.logout,s.logout,()=>ref.read(authControllerProvider.notifier).logout())]));} Widget _item(BuildContext c,IconData i,String t,VoidCallback f)=>ListTile(leading:Icon(i,color:AppColors.primary),title:Text(t),trailing:const Icon(Icons.chevron_right),onTap:f);}
