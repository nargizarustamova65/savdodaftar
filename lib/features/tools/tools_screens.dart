import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class CalculatorFab extends StatelessWidget {
  const CalculatorFab({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
        heroTag: 'global-calculator',
        tooltip: 'Kalkulyator',
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const CalculatorDialog(),
        ),
        child: const Icon(Icons.calculate_rounded),
      );
}

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});
  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String display = '0';
  double? first;
  String? operation;
  bool reset = false;

  void press(String value) {
    setState(() {
      if (value == 'C') { display = '0'; first = null; operation = null; reset = false; return; }
      if ('0123456789.'.contains(value)) {
        if (reset || display == '0') display = value == '.' ? '0.' : value;
        else if (!(value == '.' && display.contains('.'))) display += value;
        reset = false;
        return;
      }
      if (value == '=') {
        if (first != null && operation != null) {
          final second = double.tryParse(display) ?? 0;
          final result = switch (operation) { '+' => first! + second, '-' => first! - second, '×' => first! * second, '÷' => second == 0 ? 0 : first! / second, _ => second };
          display = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(2);
          first = null; operation = null; reset = true;
        }
        return;
      }
      first = double.tryParse(display) ?? 0; operation = value; reset = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const keys = <String>['C','÷','×','-','7','8','9','+','4','5','6','=','1','2','3','0','.'];
    return AlertDialog(
      title: const Text('Kalkulyator'),
      content: SizedBox(width: 280, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(alignment: Alignment.centerRight, padding: const EdgeInsets.all(12), child: Text(display, style: Theme.of(context).textTheme.headlineSmall)),
        Wrap(spacing: 6, runSpacing: 6, children: keys.map((key) => SizedBox(width: key == '0' ? 126 : 60, height: 48, child: ElevatedButton(onPressed: () => press(key), child: Text(key, style: const TextStyle(fontSize: 18))))).toList()),
      ])),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Qo‘llab-quvvatlash')), body: ListView(padding: const EdgeInsets.all(16), children: [
    const ListTile(leading: Icon(Icons.phone), title: Text('Telefon'), subtitle: Text('+998 90 000 00 00')),
    const ListTile(leading: Icon(Icons.telegram), title: Text('Telegram'), subtitle: Text('@savdodaftar_support')),
    const ListTile(leading: Icon(Icons.email), title: Text('Email'), subtitle: Text('support@savdodaftar.uz')),
    const SizedBox(height: 12), const Text('Savollaringiz bo‘lsa, biz bilan bog‘laning.'),
  ]));
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Qo‘llanma videolari')), body: ListView(padding: const EdgeInsets.all(16), children: [
    _video(context, 'Ilovani boshlash', 'https://www.youtube.com/@savdodaftar'),
    _video(context, 'Savdo va ombor bilan ishlash', 'https://www.youtube.com/@savdodaftar'),
    _video(context, 'Qarz daftari', 'https://www.youtube.com/@savdodaftar'),
  ]);
  Widget _video(BuildContext context, String title, String url) => Card(child: ListTile(leading: const Icon(Icons.play_circle_fill, size: 36), title: Text(title), trailing: const Icon(Icons.open_in_new), onTap: () => launchExternal(context, url)));
}

Future<void> launchExternal(BuildContext context, String url) async {
  // Kept in one place so all external links can later use a verified deep-link policy.
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(content: Text('Brauzerda ochish: $url')));
}
