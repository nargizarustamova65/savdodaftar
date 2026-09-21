import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/widgets.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';
import 'data/customer_models.dart';
import 'state/customers_providers.dart';

/// TZ 9-bo'lim: mijozlar ro'yxati — qidiruv, filtr, balans.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(customersControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Customer? customer}) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            CustomerFormScreen(customer: customer),
      ),
    );
    if (changed == true && mounted) {
      await ref.read(customersControllerProvider.notifier).load();
    }
  }

  Future<void> _openDetail(Customer customer) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => CustomerDetailScreen(
          customerId: customer.id,
          initial: customer,
        ),
      ),
    );
    // To'lov, tahrirlash yoki o'chirishdan keyin ro'yxat yangilanadi.
    if (mounted) {
      await ref.read(customersControllerProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final CustomersListState state = ref.watch(customersControllerProvider);
    final CustomersController notifier =
        ref.read(customersControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(s.navCustomers)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(s.customerAddTitle),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.md,
            ),
            child: SearchField(
              hint: s.searchHint,
              controller: _searchController,
              onChanged: notifier.setSearch,
            ),
          ),
          AppFilterChips(
            labels: s.customerFilters,
            selectedIndex: state.filterIndex,
            onSelected: notifier.setFilter,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _buildBody(s, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(
    AppStrings s,
    CustomersListState state,
    CustomersController notifier,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: s.errorNetwork,
        message: apiErrorText(s, state.error!),
        actionLabel: s.retry,
        onAction: notifier.load,
      );
    }

    if (state.items.isEmpty) {
      if (state.hasQuery) {
        return EmptyState(
          icon: Icons.search_off_rounded,
          title: s.searchEmptyTitle,
          message: s.searchEmptyBody,
        );
      }
      return EmptyState(
        icon: Icons.people_outline_rounded,
        title: s.customersEmptyTitle,
        message: s.customersEmptyBody,
        actionLabel: s.customerAddTitle,
        onAction: () => _openForm(),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: notifier.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          96,
        ),
        itemCount: state.items.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final Customer customer = state.items[index];
          return _CustomerTile(
            customer: customer,
            onTap: () => _openDetail(customer),
          );
        },
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasDebt = customer.balance > 0;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          CustomerAvatar(name: customer.name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                if (customer.phone != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    Phone.formatFull(customer.phone!),
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (hasDebt) ...<Widget>[
                MoneyText(
                  customer.balance,
                  size: 15,
                  color: AppColors.danger,
                ),
                const SizedBox(height: 2),
                Text(s.customerDebtLabel, style: textTheme.labelSmall),
              ] else
                Text(
                  s.noDebtLabel,
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppColors.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ism bosh harflaridan dumaloq avatar — mijozlar ro'yxati va profili uchun.
class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  String get _initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String it) => it.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.lightGreen,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.darkGreen,
              fontSize: size * 0.36,
            ),
      ),
    );
  }
}
