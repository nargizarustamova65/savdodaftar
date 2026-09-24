import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../auth/state/auth_providers.dart';

/// Standard (Savdo + Ombor) va Pro tariflarini faollashtirish ekrani.
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  String _selectedPlan = 'standard';
  String _selectedProvider = 'payme';
  bool _loading = true;
  bool _paying = false;
  String? _currentPlan;
  DateTime? _expiresAt;
  Map<String, dynamic> _plans = const <String, dynamic>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final response = await ref.read(apiClientProvider).get('/billing/plan');
      final data = response.dataMap;
      if (!mounted) return;
      setState(() {
        _currentPlan = data['plan']?.toString() ?? 'free';
        _expiresAt = DateTime.tryParse(data['expires_at']?.toString() ?? '');
        _plans = data['plans'] is Map
            ? (data['plans'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.message; });
    }
  }

  num _price(String plan) {
    final value = _plans[plan];
    return value is Map ? (value['price'] as num? ?? 0) : 0;
  }

  int _days(String plan) {
    final value = _plans[plan];
    return value is Map ? (value['days'] as num? ?? 30).toInt() : 30;
  }

  Future<void> _checkout() async {
    setState(() { _paying = true; _error = null; });
    try {
      final response = await ref.read(apiClientProvider).post(
        '/billing/checkout',
        body: <String, dynamic>{'plan': _selectedPlan, 'provider': _selectedProvider},
      );
      final data = response.dataMap;
      final url = data['checkout_url']?.toString();
      final orderId = (data['payment'] is Map)
          ? (data['payment'] as Map)['order_id']?.toString()
          : null;
      if (url == null || url.isEmpty) {
        throw const ApiException(message: 'To‘lov provayderi sozlanmagan.', code: 'checkout_unavailable');
      }
      final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched) throw const ApiException(message: 'Checkout sahifasi ochilmadi.');
      if (orderId != null && mounted) await _pollPayment(orderId);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _pollPayment(String orderId) async {
    for (int i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      final response = await ref.read(apiClientProvider).get('/billing/payments/$orderId');
      final data = response.dataMap;
      final payment = data['payment'] is Map ? (data['payment'] as Map) : const <String, dynamic>{};
      final status = payment['status']?.toString();
      if (status == 'paid') {
        await _loadPlan();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tarif faollashtirildi.')));
        return;
      }
      if (status == 'failed' || status == 'canceled') {
        if (mounted) setState(() => _error = 'To‘lov amalga oshmadi.');
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final active = _currentPlan == 'standard' || _currentPlan == 'pro';
    return Scaffold(
      appBar: AppBar(title: const Text('Tariflar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: <Widget>[
          if (active) AppCard(
            color: AppColors.lightGreen,
            child: Row(children: <Widget>[
              const Icon(Icons.verified_rounded, color: AppColors.darkGreen),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text('Joriy tarif: ${_currentPlan == 'pro' ? 'Pro' : 'Standart'}')),
              if (_expiresAt != null) Text('${_expiresAt!.day}.${_expiresAt!.month}.${_expiresAt!.year}'),
            ]),
          ),
          if (active) const SizedBox(height: AppSpacing.lg),
          _PlanCard(
            title: 'Standart',
            subtitle: 'Savdo va Ombor bo‘limlari',
            price: _price('standard'),
            days: _days('standard'),
            selected: _selectedPlan == 'standard',
            onTap: () => setState(() => _selectedPlan = 'standard'),
            icon: Icons.storefront_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _PlanCard(
            title: 'Pro',
            subtitle: 'AI, ovozli boshqaruv, OCR va kengaytirilgan hisobotlar',
            price: _price('pro'),
            days: _days('pro'),
            selected: _selectedPlan == 'pro',
            onTap: () => setState(() => _selectedPlan = 'pro'),
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('To‘lov usuli', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'payme', label: Text('Payme')),
              ButtonSegment<String>(value: 'click', label: Text('Click')),
            ],
            selected: <String>{_selectedProvider},
            onSelectionChanged: (value) => setState(() => _selectedProvider = value.first),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'To‘lovga o‘tish — ${Money.format(_price(_selectedPlan))}',
            icon: Icons.open_in_new_rounded,
            isLoading: _paying,
            onPressed: _paying ? null : _checkout,
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.title, required this.subtitle, required this.price, required this.days, required this.selected, required this.onTap, required this.icon});
  final String title;
  final String subtitle;
  final num price;
  final int days;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    borderColor: selected ? AppColors.primary : null,
    color: selected ? AppColors.lightGreen : AppColors.card,
    child: Row(children: <Widget>[
      Icon(icon, color: selected ? AppColors.darkGreen : AppColors.textSecondary, size: 30),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle),
        const SizedBox(height: AppSpacing.sm),
        Text('${Money.format(price)} / $days kun', style: const TextStyle(fontWeight: FontWeight.w700)),
      ])),
      Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.primary : AppColors.textSecondary),
    ]),
  );
}
