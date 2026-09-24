import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../../core/widgets/widgets.dart';
import '../auth/state/auth_providers.dart';

class ReferralScreen extends ConsumerStatefulWidget { const ReferralScreen({super.key}); @override ConsumerState<ReferralScreen> createState() => _ReferralState(); }
class _ReferralState extends ConsumerState<ReferralScreen> {
  String? link; num bonus = 0; bool loading = true; String? error;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final r = await ref.read(apiClientProvider).get('/referral'); final d = r.dataMap; if (mounted) setState(() { link=d['link']?.toString(); bonus=(d['bonus_balance'] as num?) ?? 0; loading=false; }); } on ApiException catch(e) { if(mounted) setState(() {error=e.message; loading=false;}); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Referal va bonuslar')), body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
    AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Sizning referal linkingiz'), const SizedBox(height: 8), SelectableText(link ?? 'Hozircha link mavjud emas'), const SizedBox(height: 12), AppButton(label: 'Linkni ulashish', icon: Icons.share, onPressed: link == null ? null : () => launchExternal(context, link!))])),
    const SizedBox(height: 16), AppCard(child: ListTile(leading: const Icon(Icons.account_balance_wallet), title: const Text('Bonuslar balansi'), subtitle: Text('${bonus.toStringAsFixed(0)} so‘m'))),
    if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
  ]);
}

class CurrencyScreen extends ConsumerStatefulWidget { const CurrencyScreen({super.key}); @override ConsumerState<CurrencyScreen> createState() => _CurrencyState(); }
class _CurrencyState extends ConsumerState<CurrencyScreen> {
  List<Map<String,dynamic>> rates=[]; bool loading=true; String? updated;
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { try { final r=await Dio().get('https://cbu.uz/uz/arkhiv-kursov-valyut/json/'); final raw=r.data is String? jsonDecode(r.data as String):r.data; if(mounted)setState((){rates=(raw as List).cast<Map<String,dynamic>>(); loading=false; updated=DateTime.now().toString();}); } catch(_){if(mounted)setState(()=>loading=false);} }
  @override Widget build(BuildContext context)=>Scaffold(appBar: AppBar(title: const Text('Valyuta kurslari'), actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]), body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView.builder(itemCount:rates.length,itemBuilder:(_,i){final r=rates[i];return ListTile(title:Text('${r['CcyNm_UZ']} (${r['Ccy']})'),trailing:Text('${r['Rate']} so‘m'),subtitle:Text('1 ${r['Ccy']}'))}));
}
