import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'farm_store.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.store, required this.onOpenFeed});

  final FarmStore store;
  final VoidCallback onOpenFeed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final birds = store.flocks.fold<int>(0, (total, flock) => total + (flock['birds'] as num? ?? 0).toInt());
        final recentSpend = store.feedRecords
            .where((record) => _isWithinDays(record['date'], 30))
            .fold<double>(0, (total, record) => total + _number(record['amountSpent']));
        final recentEggs = store.eggCollections
            .where((record) => _isWithinDays(record['date'], 7))
            .fold<double>(0, (total, record) => total + _number(record['trays']));

        return Scaffold(
          backgroundColor: LiveStockColors.canvas,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                  sliver: SliverList.list(
                    children: [
                      _brandRow(context),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: LiveStockColors.forest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FARM OVERVIEW', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.lime, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                            const SizedBox(height: 8),
                            Text('Good morning, Kofi', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 5),
                            Text('Adom Poultry Farm · Eastern Region', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: onOpenFeed,
                              icon: const Icon(Icons.add_chart_rounded, size: 18),
                              label: const Text('Record feed use'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 9,
                        crossAxisSpacing: 9,
                        childAspectRatio: 1.45,
                        children: [
                          MetricTile(label: 'Active birds', value: birds.toString(), icon: Icons.egg_alt_outlined),
                          MetricTile(label: 'Flocks', value: store.flocks.length.toString(), icon: Icons.groups_2_outlined, tint: LiveStockColors.amber),
                          MetricTile(label: 'Feed spend · 30 days', value: formatGhs(recentSpend), icon: Icons.payments_outlined, tint: LiveStockColors.coral),
                          MetricTile(label: 'Eggs · 7 days', value: '${recentEggs.toStringAsFixed(1)} trays', icon: Icons.egg_outlined),
                        ],
                      ),
                      const SizedBox(height: 21),
                      SectionHeading(title: 'Feed recommendations', subtitle: 'Based on your records and supplier reports.'),
                      const SizedBox(height: 9),
                      if (store.recommendations.isEmpty)
                        const LiveStockPanel(child: EmptyHint(icon: Icons.insights_outlined, title: 'No alerts yet', detail: 'Record feed use and supplier quotes to surface stock, consumption, and price changes.'))
                      else
                        ...store.recommendations.take(3).map((recommendation) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _RecommendationTile(recommendation: recommendation),
                            )),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: SectionHeading(title: 'Your flocks', subtitle: 'Current bird groups')),
                          TextButton(onPressed: onOpenFeed, child: const Text('Feed records')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (store.flocks.isEmpty)
                        const LiveStockPanel(child: EmptyHint(icon: Icons.egg_alt_outlined, title: 'Add your first flock', detail: 'Create a flock to start tracking birds and care records.'))
                      else
                        ...store.flocks.take(3).map((flock) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _FlockSummary(flock: flock),
                            )),
                      const SizedBox(height: 10),
                      const LocalOnlyNote(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _brandRow(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: LiveStockColors.lime, borderRadius: BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11), bottomRight: Radius.circular(11), bottomLeft: Radius.circular(4))),
          alignment: Alignment.center,
          child: const Text('L', style: TextStyle(color: LiveStockColors.forest, fontWeight: FontWeight.w900, fontSize: 19)),
        ),
        const SizedBox(width: 9),
        Text('LiveStock', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: LiveStockColors.forest)),
        const Spacer(),
        IconButton.filledTonal(onPressed: () {}, tooltip: 'Farm profile', icon: const Icon(Icons.person_outline_rounded)),
      ],
    );
  }

  bool _isWithinDays(Object? value, int days) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return false;
    final age = DateTime.now().difference(date).inDays;
    return age >= 0 && age < days;
  }

  double _number(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.recommendation});

  final Map<String, String> recommendation;

  @override
  Widget build(BuildContext context) {
    final opportunity = recommendation['kind'] == 'opportunity';
    final tint = opportunity ? LiveStockColors.leaf : LiveStockColors.amber;
    return LiveStockPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(opportunity ? Icons.trending_down_rounded : Icons.notifications_active_outlined, color: tint, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recommendation['title'] ?? '', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(recommendation['detail'] ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LiveStockColors.muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlockSummary extends StatelessWidget {
  const _FlockSummary({required this.flock});

  final Map<String, dynamic> flock;

  @override
  Widget build(BuildContext context) {
    return LiveStockPanel(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.egg_alt_outlined, color: LiveStockColors.leaf),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(flock['name']?.toString() ?? 'Flock', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text('${flock['birdType']} · ${flock['ageWeeks']} weeks', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.muted)),
              ],
            ),
          ),
          Text('${flock['birds']}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class FlocksScreen extends StatefulWidget {
  const FlocksScreen({super.key, required this.store});

  final FarmStore store;

  @override
  State<FlocksScreen> createState() => _FlocksScreenState();
}

class _FlocksScreenState extends State<FlocksScreen> {
  Future<void> _addFlock() async {
    final name = TextEditingController();
    final birds = TextEditingController(text: '100');
    final age = TextEditingController(text: '1');
    var type = 'Broiler';
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add a flock'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Flock name'), validator: (value) => value == null || value.trim().isEmpty ? 'Enter a flock name' : null),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Bird type'), items: const [DropdownMenuItem(value: 'Broiler', child: Text('Broiler')), DropdownMenuItem(value: 'Layer', child: Text('Layer'))], onChanged: (value) => setDialogState(() => type = value ?? 'Broiler')),
                  const SizedBox(height: 10),
                  TextFormField(controller: birds, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Number of birds'), validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1 ? 'Enter at least one bird' : null),
                  const SizedBox(height: 10),
                  TextFormField(controller: age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age (weeks)'), validator: (value) => (int.tryParse(value ?? '') ?? -1) < 0 ? 'Enter a valid age' : null),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () { if (formKey.currentState?.validate() ?? false) Navigator.pop(dialogContext, true); }, child: const Text('Save flock')),
          ],
        ),
      ),
    );
    if (result == true) {
      await widget.store.addFlock({'id': DateTime.now().microsecondsSinceEpoch.toString(), 'name': name.text.trim(), 'birdType': type, 'birds': int.parse(birds.text), 'ageWeeks': int.parse(age.text)});
    }
    name.dispose();
    birds.dispose();
    age.dispose();
  }

  Future<void> _logUpdate(Map<String, dynamic> flock) async {
    final details = TextEditingController();
    const types = ['Feed', 'Water', 'Weight', 'Vaccination', 'Treatment', 'Mortality', 'General note'];
    var type = types.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Log · ${flock['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Update type'), items: types.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setDialogState(() => type = value ?? types.first)),
              const SizedBox(height: 12),
              TextField(controller: details, maxLines: 3, decoration: const InputDecoration(labelText: 'Details')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, details.text.trim().isNotEmpty), child: const Text('Save update')),
          ],
        ),
      ),
    );
    if (result == true) {
      await widget.store.addFlockLog({'flockId': flock['id'], 'flockName': flock['name'], 'type': type, 'details': details.text.trim(), 'date': DateTime.now().toIso8601String()});
    }
    details.dispose();
  }

  Future<void> _logEggCollection() async {
    final trays = TextEditingController();
    final notes = TextEditingController();
    var flockId = widget.store.flocks.firstOrNull?['id']?.toString();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Log egg collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: flockId,
                decoration: const InputDecoration(labelText: 'Flock'),
                items: widget.store.flocks.where((flock) => flock['birdType'] == 'Layer').map((flock) => DropdownMenuItem(value: flock['id'].toString(), child: Text(flock['name'].toString()))).toList(),
                onChanged: (value) => setDialogState(() => flockId = value),
              ),
              const SizedBox(height: 10),
              TextField(controller: trays, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Trays collected')),
              const SizedBox(height: 10),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, (double.tryParse(trays.text) ?? 0) > 0 && flockId != null), child: const Text('Save collection')),
          ],
        ),
      ),
    );
    if (result == true) {
      final flock = widget.store.flocks.firstWhere((item) => item['id'].toString() == flockId);
      await widget.store.addEggCollection({'flockId': flockId, 'flockName': flock['name'], 'trays': double.parse(trays.text), 'notes': notes.text.trim(), 'date': DateTime.now().toIso8601String()});
    }
    trays.dispose();
    notes.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => Scaffold(
        backgroundColor: LiveStockColors.canvas,
        floatingActionButton: FloatingActionButton.extended(onPressed: _addFlock, icon: const Icon(Icons.add), label: const Text('Add flock')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 19, 18, 90),
            children: [
              const PageHeading(eyebrow: 'FARM WORKSPACE', title: 'My flocks', subtitle: 'Manage flock sizes, ages, and care records.'),
              const SizedBox(height: 17),
              if (widget.store.flocks.isEmpty)
                const LiveStockPanel(child: EmptyHint(icon: Icons.egg_alt_outlined, title: 'No flocks yet', detail: 'Add a flock to start tracking day-to-day care.'))
              else
                ...widget.store.flocks.map((flock) {
                  final logs = widget.store.flockLogs.where((log) => log['flockId'] == flock['id']).take(3).toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LiveStockPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.egg_alt_outlined, color: LiveStockColors.leaf),
                              const SizedBox(width: 9),
                              Expanded(child: Text(flock['name'].toString(), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                              IconButton(onPressed: () => _logUpdate(flock), tooltip: 'Log flock update', icon: const Icon(Icons.note_add_outlined)),
                            ],
                          ),
                          Text('${flock['birdType']} · ${flock['birds']} birds · ${flock['ageWeeks']} weeks old', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LiveStockColors.muted)),
                          if (logs.isNotEmpty) ...[
                            const Divider(height: 20),
                            for (final log in logs)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Text('${log['type']}: ${log['details']}', style: Theme.of(context).textTheme.bodySmall),
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 9),
              SectionHeading(
                title: 'Egg collection',
                subtitle: 'Record trays from layer flocks.',
                trailing: IconButton.filledTonal(onPressed: widget.store.flocks.any((flock) => flock['birdType'] == 'Layer') ? _logEggCollection : null, tooltip: 'Log egg collection', icon: const Icon(Icons.add)),
              ),
              const SizedBox(height: 8),
              if (widget.store.eggCollections.isEmpty)
                const LiveStockPanel(child: EmptyHint(icon: Icons.egg_outlined, title: 'No egg collections logged', detail: 'Save a tray count to include it in the overview.'))
              else
                ...widget.store.eggCollections.take(4).map((collection) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: LiveStockPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                        child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(collection['flockName'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)), Text(formatFarmDate(collection['date']), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.muted))])), Text('${collection['trays']} trays', style: const TextStyle(fontWeight: FontWeight.w800))]),
                      ),
                    )),
              const SizedBox(height: 10),
              const LocalOnlyNote(),
            ],
          ),
        ),
      ),
    );
  }
}