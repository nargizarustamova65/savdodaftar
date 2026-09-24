import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/widgets.dart';
import '../auth/state/auth_providers.dart';

class ReferralScreen extends ConsumerStatefulWidget { const ReferralScreen({super.key}); @override ConsumerState<ReferralScreen> createState() => _ReferralState(); }
class _ReferralState extends ConsumerState<ReferralScreen> {
  String? link; String? code; num bonus = 0; bool loading = true; String? error;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final d = (await ref.read(apiClientProvider).get('/referral')).dataMap; if (mounted) setState(() { link=d['link']?.toString(); code=d['code']?.toString(); bonus=(d['bonus_balance'] as num?) ?? 0; loading=false; }); } on ApiException catch(e) { if(mounted) setState(() { error=e.message; loading=false; }); } }
  Future<void> _share() async { final uri = Uri.tryParse(link ?? ''); if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referal linkni ochib bo‘lmadi.'))); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Referal va bonuslar')), body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: <Widget>[AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('Sizning referal linkingiz'), const SizedBox(height: 8), SelectableText(link ?? 'Hozircha link mavjud emas'), if (code != null) Text('Kod: $code'), const SizedBox(height: 12), AppButton(label: 'Linkni ochish', icon: Icons.open_in_new, onPressed: link == null ? null : _share)])), const SizedBox(height: 16), AppCard(child: ListTile(leading: const Icon(Icons.account_balance_wallet), title: const Text('Bonuslar balansi'), subtitle: Text('${bonus.toStringAsFixed(0)} so‘m'))), if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red)))]);
}
