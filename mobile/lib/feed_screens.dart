import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'farm_store.dart';

class FeedHomePage extends StatelessWidget {
  const FeedHomePage({super.key, required this.store, required this.calculator});

  final FarmStore store;
  final Widget calculator;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: LiveStockColors.canvas,
        appBar: AppBar(
          title: const Text('Feed', style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [Tab(text: 'Calculator'), Tab(text: 'Use & stock'), Tab(text: 'Cycle impact')],
          ),
        ),
        body: TabBarView(children: [calculator, FeedUsageScreen(store: store), FeedCycleImpactScreen(store: store)]),
      ),
    );
  }
}

class FeedUsageScreen extends StatefulWidget {
  const FeedUsageScreen({super.key, required this.store});

  final FarmStore store;

  @override
  State<FeedUsageScreen> createState() => _FeedUsageScreenState();
}

class _FeedUsageScreenState extends State<FeedUsageScreen> {
  final _birds = TextEditingController(text: '100');
  final _dailyKg = TextEditingController();
  final _spend = TextEditingController(text: '0');
  final _stock = TextEditingController();
  final _planningDays = TextEditingController(text: '7');
  String _birdType = 'Broiler';
  final _ageWeeks = TextEditingController(text: '4');

  @override
  void dispose() {
    _birds.dispose();
    _dailyKg.dispose();
    _spend.dispose();
    _stock.dispose();
    _planningDays.dispose();
    _ageWeeks.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    final birds = int.tryParse(_birds.text) ?? 0;
    final dailyKg = double.tryParse(_dailyKg.text) ?? 0;
    final spend = double.tryParse(_spend.text) ?? -1;
    final stock = double.tryParse(_stock.text) ?? -1;
    final ageWeeks = int.tryParse(_ageWeeks.text) ?? -1;
    if (birds < 1 || dailyKg <= 0 || spend < 0 || stock < 0 || ageWeeks < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid bird, feed, spend, and stock values.')));
      return;
    }
    await widget.store.addFeedRecord({
      'birds': birds,
      'birdType': _birdType,
      'ageWeeks': ageWeeks,
      'dailyFeedKg': dailyKg,
      'amountSpent': spend,
      'stockRemaining': stock,
      'date': DateTime.now().toIso8601String(),
      'recordedAt': DateTime.now().millisecondsSinceEpoch,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feed record saved on this device.')));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final records = [...widget.store.feedRecords]..sort((a, b) => _date(b).compareTo(_date(a)));
        final latest = records.isEmpty ? null : records.first;
        final dailyKg = _number(latest?['dailyFeedKg']);
        final stockKg = _number(latest?['stockRemaining']);
        final birds = _number(latest?['birds']);
        final requiredDays = int.tryParse(_planningDays.text) ?? 7;
        final requiredKg = dailyKg * requiredDays;
        final weeklySpend = _spendInDays(records, 7);
        final monthlySpend = _spendInDays(records, 30);

        return ListView(
          padding: const EdgeInsets.fromLTRB(17, 16, 17, 30),
          children: [
            const PageHeading(eyebrow: 'FLOCK OPERATIONS', title: 'Feed use & stock', subtitle: 'Record actual use and spend to improve your estimates.'),
            const SizedBox(height: 15),
            LiveStockPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(title: 'Daily feed record', subtitle: 'Saved locally and available offline.'),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _birdType,
                    decoration: const InputDecoration(labelText: 'Bird type'),
                    items: const [DropdownMenuItem(value: 'Broiler', child: Text('Broiler')), DropdownMenuItem(value: 'Layer', child: Text('Layer'))],
                    onChanged: (value) => setState(() => _birdType = value ?? 'Broiler'),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: _numberField(context, _ageWeeks, 'Age (weeks)')), const SizedBox(width: 9), Expanded(child: _numberField(context, _birds, 'Birds'))]),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: _numberField(context, _dailyKg, 'Feed used daily (kg)', decimal: true)), const SizedBox(width: 9), Expanded(child: _numberField(context, _spend, 'Spend today (GH₵)', decimal: true))]),
                  const SizedBox(height: 10),
                  _numberField(context, _stock, 'Feed remaining (kg)', decimal: true),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _saveRecord, icon: const Icon(Icons.save_outlined), label: const Text('Save daily record'))),
                ],
              ),
            ),
            const SizedBox(height: 15),
            SectionHeading(
              title: 'Usage summary',
              subtitle: 'Based on the latest feed record.',
              trailing: SizedBox(width: 74, child: TextField(controller: _planningDays, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Days', isDense: true), onChanged: (_) => setState(() {}))),
            ),
            const SizedBox(height: 9),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.65,
              children: [
                MetricTile(label: 'Feed / day', value: latest == null ? '—' : '${dailyKg.toStringAsFixed(1)} kg', icon: Icons.scale_outlined),
                MetricTile(label: 'Per bird / day', value: latest == null || birds == 0 ? '—' : '${(dailyKg * 1000 / birds).toStringAsFixed(0)} g', icon: Icons.egg_alt_outlined, tint: LiveStockColors.amber),
                MetricTile(label: 'Spend · 7 days', value: formatGhs(weeklySpend), icon: Icons.payments_outlined, tint: LiveStockColors.coral),
                MetricTile(label: 'Spend · 30 days', value: formatGhs(monthlySpend), icon: Icons.account_balance_wallet_outlined),
                MetricTile(label: 'Remaining', value: latest == null ? '—' : '${stockKg.toStringAsFixed(1)} kg', icon: Icons.inventory_2_outlined, tint: LiveStockColors.amber),
                MetricTile(label: 'Required · $requiredDays days', value: latest == null ? '—' : '${requiredKg.toStringAsFixed(1)} kg', icon: Icons.event_repeat_outlined),
              ],
            ),
            if (latest != null) ...[
              const SizedBox(height: 9),
              LiveStockPanel(
                child: Text(
                  stockKg < requiredKg
                      ? 'Stock is short by ${(requiredKg - stockKg).toStringAsFixed(1)} kg for this plan; current supply covers about ${dailyKg > 0 ? (stockKg / dailyKg).toStringAsFixed(1) : '0'} days.'
                      : 'Current stock covers the $requiredDays-day plan.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: stockKg < requiredKg ? LiveStockColors.coral : LiveStockColors.forest, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const SectionHeading(title: 'Recent records'),
            const SizedBox(height: 8),
            if (records.isEmpty)
              const LiveStockPanel(child: EmptyHint(icon: Icons.receipt_long_outlined, title: 'No feed use logged', detail: 'Your daily entries will appear here.'))
            else
              ...records.take(10).map((record) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: LiveStockPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                      child: Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(formatFarmDate(record['date']), style: const TextStyle(fontWeight: FontWeight.w700)), Text('${record['birds']} birds · ${_number(record['dailyFeedKg']).toStringAsFixed(1)} kg/day', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.muted))])),
                          Text(formatGhs(_number(record['amountSpent'])), style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  )),
            const SizedBox(height: 8),
            const LocalOnlyNote(),
          ],
        );
      },
    );
  }

  Widget _numberField(BuildContext context, TextEditingController controller, String label, {bool decimal = false}) {
    return TextField(controller: controller, keyboardType: TextInputType.numberWithOptions(decimal: decimal), decoration: InputDecoration(labelText: label));
  }

  double _spendInDays(List<Map<String, dynamic>> records, int days) => records
      .where((record) => DateTime.now().difference(_date(record)).inDays < days && !DateTime.now().isBefore(_date(record)))
      .fold<double>(0, (total, record) => total + _number(record['amountSpent']));

  DateTime _date(Map<String, dynamic>? record) => DateTime.tryParse(record?['date']?.toString() ?? '') ?? DateTime(1970);
  double _number(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;
}

class FeedCycleImpactScreen extends StatefulWidget {
  const FeedCycleImpactScreen({super.key, required this.store});

  final FarmStore store;

  @override
  State<FeedCycleImpactScreen> createState() => _FeedCycleImpactScreenState();
}

class _FeedCycleImpactScreenState extends State<FeedCycleImpactScreen> {
  final _birds = TextEditingController(text: '500');
  final _spend = TextEditingController();
  final _savingPercent = TextEditingController(text: '0');
  DateTime _start = DateTime.now().subtract(const Duration(days: 30));
  DateTime _end = DateTime.now();
  bool _calculated = false;
  String? _sourceMessage;

  @override
  void dispose() {
    _birds.dispose();
    _spend.dispose();
    _savingPercent.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(context: context, initialDate: start ? _start : _end, firstDate: DateTime(2018), lastDate: DateTime.now());
    if (selected == null) return;
    setState(() {
      if (start) {
        _start = selected;
      } else {
        _end = selected;
      }
      _calculated = false;
    });
  }

  void _useLoggedSpend() {
    final start = DateTime(_start.year, _start.month, _start.day);
    final end = DateTime(_end.year, _end.month, _end.day, 23, 59, 59);
    final spend = widget.store.feedRecords.where((record) {
      final date = DateTime.tryParse(record['date']?.toString() ?? '');
      return date != null && !date.isBefore(start) && !date.isAfter(end);
    }).fold<double>(0, (total, record) => total + (double.tryParse(record['amountSpent']?.toString() ?? '') ?? 0));
    setState(() {
      _spend.text = spend.toStringAsFixed(2);
      _sourceMessage = spend > 0 ? 'Loaded feed spend from saved records.' : 'No feed expenses found in that date range.';
      _calculated = false;
    });
  }

  void _calculate() {
    final birds = int.tryParse(_birds.text) ?? 0;
    final spend = double.tryParse(_spend.text) ?? -1;
    final percent = double.tryParse(_savingPercent.text) ?? -1;
    if (birds < 1 || spend < 0 || percent < 0 || percent > 100 || _end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check birds, cycle dates, feed spend, and savings percent.')));
      return;
    }
    setState(() => _calculated = true);
  }

  @override
  Widget build(BuildContext context) {
    final spend = double.tryParse(_spend.text) ?? 0;
    final birds = int.tryParse(_birds.text) ?? 0;
    final percent = double.tryParse(_savingPercent.text) ?? 0;
    final savings = spend * percent / 100;
    return ListView(
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 30),
      children: [
        const PageHeading(eyebrow: 'CYCLE PLANNING', title: 'Cost & savings impact', subtitle: 'Model the feed cost per bird and possible cycle savings.'),
        const SizedBox(height: 15),
        LiveStockPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(title: 'Production cycle', subtitle: 'Compare only against a supplier quote you have checked.'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dateButton('Start', _start, () => _pickDate(start: true))),
                  const SizedBox(width: 8),
                  Expanded(child: _dateButton('End', _end, () => _pickDate(start: false))),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(child: TextField(controller: _birds, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Birds in cycle'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _spend, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Feed spend (GH₵)'))),
                ],
              ),
              const SizedBox(height: 11),
              TextField(controller: _savingPercent, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Potential savings (%)')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(onPressed: _useLoggedSpend, icon: const Icon(Icons.download_outlined, size: 18), label: const Text('Use logged spend')),
                  if (_sourceMessage != null)
                    Text(_sourceMessage!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.muted)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _calculate, child: const Text('Estimate cycle impact'))),
            ],
          ),
        ),
        if (_calculated) ...[
          const SizedBox(height: 12),
          LiveStockPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(title: 'Potential impact', subtitle: 'Savings may improve profit if feed quality and performance remain equivalent.'),
                const SizedBox(height: 13),
                _impactRow(context, 'Current feed cost / bird', birds > 0 ? formatGhs(spend / birds) : formatGhs(0)),
                _impactRow(context, 'Potential cycle savings', formatGhs(savings), strong: true),
                _impactRow(context, 'Adjusted feed spend', formatGhs(spend - savings)),
                _impactRow(context, 'Potential profit uplift', formatGhs(savings), strong: true),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        const LocalOnlyNote(message: 'Scenario estimate only. LiveStock does not verify suppliers or nutritional equivalence. Saved records remain on this device.'),
      ],
    );
  }

  Widget _dateButton(String label, DateTime date, VoidCallback onPressed) {
    return OutlinedButton.icon(onPressed: onPressed, icon: const Icon(Icons.calendar_today_outlined, size: 16), label: Text('$label · ${formatFarmDate(date.toIso8601String())}', overflow: TextOverflow.ellipsis));
  }

  Widget _impactRow(BuildContext context, String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LiveStockColors.muted),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                  color: strong ? LiveStockColors.forest : LiveStockColors.ink,
                ),
          ),
        ],
      ),
    );
  }
}