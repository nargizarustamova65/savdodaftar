import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/widgets/widgets.dart';

/// TZ 11-bo'lim: Ombor.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;

    return Scaffold(
      appBar: AppBar(title: Text(s.navInventory)),
      body: EmptyState(
        icon: Icons.inventory_2_outlined,
        title: s.comingSoonTitle,
        message: s.comingSoonBody,
      ),
    );
  }
}
