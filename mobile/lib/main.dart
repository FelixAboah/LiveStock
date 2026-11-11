import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'farm_screens.dart';
import 'farm_store.dart';
import 'feed_screens.dart';
import 'market_screens.dart';
import 'vet_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveStock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: LiveStockColors.forest),
        scaffoldBackgroundColor: LiveStockColors.canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: LiveStockColors.canvas,
          foregroundColor: LiveStockColors.ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDCE4DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDCE4DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: LiveStockColors.forest, width: 1.5),
          ),
        ),
      ),
      home: const AppStartupPage(),
    );
  }
}

class AppStartupPage extends StatefulWidget {
  const AppStartupPage({super.key});

  @override
  State<AppStartupPage> createState() => _AppStartupPageState();
}

class _AppStartupPageState extends State<AppStartupPage> {
  late final Future<FarmStore> _store = FarmStore.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FarmStore>(
      future: _store,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text('Could not open farm records on this device.')));
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return LiveStockShell(store: snapshot.data!);
      },
    );
  }
}

class LiveStockShell extends StatefulWidget {
  const LiveStockShell({super.key, required this.store});

  final FarmStore store;

  @override
  State<LiveStockShell> createState() => _LiveStockShellState();
}

class _LiveStockShellState extends State<LiveStockShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      OverviewScreen(store: widget.store, onOpenFeed: () => setState(() => _selectedIndex = 2)),
      FlocksScreen(store: widget.store),
      FeedHomePage(store: widget.store, calculator: const FeedCalculatorPage()),
      MarketScreen(store: widget.store),
      VetScreen(store: widget.store),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 66,
        backgroundColor: Colors.white,
        indicatorColor: LiveStockColors.lime.withValues(alpha: 0.6),
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.egg_alt_outlined), selectedIcon: Icon(Icons.egg_alt_rounded), label: 'Flocks'),
          NavigationDestination(icon: Icon(Icons.scale_outlined), selectedIcon: Icon(Icons.scale_rounded), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront_rounded), label: 'Market'),
          NavigationDestination(icon: Icon(Icons.health_and_safety_outlined), selectedIcon: Icon(Icons.health_and_safety_rounded), label: 'Vet'),
        ],
      ),
    );
  }
}

enum BirdType { broiler, layer }

class _IngredientDraft {
  _IngredientDraft(this.name);

  final String name;
  bool available = false;
  final priceController = TextEditingController();
  final inclusionController = TextEditingController();

  String get key => name.toLowerCase().replaceAll(' ', '-');

  void dispose() {
    priceController.dispose();
    inclusionController.dispose();
  }
}

class _CostLine {
  const _CostLine({
    required this.name,
    required this.percent,
    required this.amountKg,
    required this.cost,
  });

  final String name;
  final double percent;
  final double amountKg;
  final double cost;
}

class _CostResult {
  const _CostResult({
    required this.batchKg,
    required this.totalCost,
    required this.costPerKg,
    required this.budget,
    required this.lines,
  });

  final double batchKg;
  final double totalCost;
  final double costPerKg;
  final double budget;
  final List<_CostLine> lines;
}

class FeedCalculatorPage extends StatefulWidget {
  const FeedCalculatorPage({super.key});

  @override
  State<FeedCalculatorPage> createState() => _FeedCalculatorPageState();
}

class _FeedCalculatorPageState extends State<FeedCalculatorPage> {
  static const _ingredientNames = [
    'Maize',
    'Soybean meal',
    'Fishmeal',
    'Wheat bran',
    'Premixes',
    'Limestone',
    'Dicalcium phosphate',
    'Vegetable oil',
    'Salt',
    'Lysine',
    'Methionine',
  ];

  final _ageController = TextEditingController(text: '4');
  final _birdsController = TextEditingController(text: '100');
  final _daysController = TextEditingController(text: '1');
  final _dailyIntakeController = TextEditingController(text: '100');
  final _budgetController = TextEditingController();
  late final List<_IngredientDraft> _ingredients;

  BirdType _birdType = BirdType.broiler;
  bool _intakeManuallyEdited = false;
  _CostResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ingredients = _ingredientNames.map(_IngredientDraft.new).toList();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _birdsController.dispose();
    _daysController.dispose();
    _dailyIntakeController.dispose();
    _budgetController.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  int get _ageWeeks => int.tryParse(_ageController.text) ?? 0;

  String get _stage {
    if (_birdType == BirdType.broiler) {
      if (_ageWeeks < 3) return 'Broiler starter';
      if (_ageWeeks < 6) return 'Broiler grower';
      return 'Broiler finisher';
    }
    if (_ageWeeks < 8) return 'Layer chick starter';
    if (_ageWeeks < 18) return 'Layer grower / developer';
    return 'Layer ration';
  }

  int get _stageIntake {
    if (_birdType == BirdType.broiler) {
      if (_ageWeeks < 3) return 50;
      if (_ageWeeks < 6) return 100;
      return 150;
    }
    if (_ageWeeks < 8) return 40;
    if (_ageWeeks < 18) return 70;
    return 110;
  }

  void _markDirty() {
    setState(() {
      _result = null;
      _error = null;
    });
  }

  String _money(double value) => 'GH₵ ${value.toStringAsFixed(2)}';

  void _calculate() {
    final birds = int.tryParse(_birdsController.text);
    final days = int.tryParse(_daysController.text);
    final dailyIntake = double.tryParse(_dailyIntakeController.text);
    final budget = double.tryParse(_budgetController.text);
    if (birds == null || birds < 1 || days == null || days < 1 || dailyIntake == null || dailyIntake <= 0 || budget == null || budget < 0) {
      setState(() => _error = 'Enter a valid flock size, feed amount, duration, and budget.');
      return;
    }

    final selected = _ingredients.where((ingredient) => ingredient.available).toList();
    if (selected.isEmpty) {
      setState(() => _error = 'Select the ingredients available for this mix.');
      return;
    }

    final mix = selected.map((ingredient) {
      return (
        ingredient: ingredient,
        price: double.tryParse(ingredient.priceController.text) ?? 0,
        percent: double.tryParse(ingredient.inclusionController.text) ?? 0,
      );
    }).toList();
    final mixTotal = mix.fold<double>(0, (total, line) => total + line.percent);
    if ((mixTotal - 100).abs() > 0.05) {
      setState(() => _error = 'Ingredient inclusion must total 100%. Current total: ${mixTotal.toStringAsFixed(1)}%.');
      return;
    }

    final usedMix = mix.where((line) => line.percent > 0).toList();
    if (usedMix.isEmpty || usedMix.any((line) => line.price <= 0)) {
      setState(() => _error = 'Enter a price per kg for every ingredient used in the mix.');
      return;
    }

    final batchKg = birds * days * dailyIntake / 1000;
    final lines = usedMix.map((line) {
      final amountKg = batchKg * line.percent / 100;
      return _CostLine(
        name: line.ingredient.name,
        percent: line.percent,
        amountKg: amountKg,
        cost: amountKg * line.price,
      );
    }).toList();
    final totalCost = lines.fold<double>(0, (total, line) => total + line.cost);

    setState(() {
      _error = null;
      _result = _CostResult(
        batchKg: batchKg,
        totalCost: totalCost,
        costPerKg: totalCost / batchKg,
        budget: budget,
        lines: lines,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 400 ? 16.0 : 24.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 28),
                  sliver: SliverList.list(
                    children: [
                      _buildBrandHeader(context),
                      const SizedBox(height: 24),
                      _buildPageHeading(context),
                      const SizedBox(height: 16),
                      _buildFlockPanel(context),
                      const SizedBox(height: 14),
                      _buildIngredientsPanel(context),
                      const SizedBox(height: 14),
                      _buildCalculateButton(context),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        _buildError(context),
                      ],
                      if (_result != null) ...[
                        const SizedBox(height: 14),
                        _buildResultPanel(context, _result!),
                      ],
                      const SizedBox(height: 14),
                      _buildNutritionNote(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
              bottomLeft: Radius.circular(4),
            ),
          ),
          alignment: Alignment.center,
          child: const Text('L', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LiveStock', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text('POULTRY FARM COMPANION', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.1, color: colors.onSurfaceVariant)),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Farm profile',
          onPressed: () {},
          icon: const Icon(Icons.person_outline_rounded),
        ),
      ],
    );
  }

  Widget _buildPageHeading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FEED PLANNING', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
        const SizedBox(height: 5),
        Text('Feed cost calculator', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text('Estimate batch size and cost using your local ingredient prices.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8E1)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: child,
    );
  }

  Widget _buildFlockPanel(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Flock and batch', 'Age-based feed quantity is an adjustable estimate.'),
          const SizedBox(height: 15),
          SegmentedButton<BirdType>(
            segments: const [
              ButtonSegment(value: BirdType.broiler, label: Text('Broiler'), icon: Icon(Icons.egg_alt_outlined)),
              ButtonSegment(value: BirdType.layer, label: Text('Layer'), icon: Icon(Icons.egg_outlined)),
            ],
            selected: {_birdType},
            onSelectionChanged: (selection) {
              setState(() {
                _birdType = selection.first;
                _intakeManuallyEdited = false;
                _dailyIntakeController.text = '$_stageIntake';
                _result = null;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 480 ? 2 : 3;
              const gap = 10.0;
              final fieldWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: 11,
                children: [
                  SizedBox(width: fieldWidth, child: _numberField(label: 'Age (weeks)', controller: _ageController, keyName: 'age-weeks', onChanged: (_) { if (!_intakeManuallyEdited) _dailyIntakeController.text = '$_stageIntake'; _markDirty(); })),
                  SizedBox(width: fieldWidth, child: _numberField(label: 'Number of birds', controller: _birdsController, keyName: 'bird-count', onChanged: (_) => _markDirty())),
                  SizedBox(width: fieldWidth, child: _numberField(label: 'Days to prepare', controller: _daysController, keyName: 'days-to-prepare', onChanged: (_) => _markDirty())),
                  SizedBox(width: fieldWidth, child: _numberField(label: 'Feed / bird / day (g)', controller: _dailyIntakeController, keyName: 'daily-intake', decimal: true, onChanged: (_) { _intakeManuallyEdited = true; _markDirty(); })),
                  SizedBox(width: fieldWidth, child: _numberField(label: 'Budget (GH₵)', controller: _budgetController, keyName: 'budget', decimal: true, onChanged: (_) => _markDirty())),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(color: colors.primaryContainer.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(8)),
            child: Text('$_stage · $_stageIntake g/bird/day starting estimate; adjust to your feeding guidance.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required String keyName,
    required ValueChanged<String> onChanged,
    bool decimal = false,
  }) {
    return TextField(
      key: ValueKey(keyName),
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildIngredientsPanel(BuildContext context) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Available ingredients', 'Enter the percentages from your approved recipe. The mix must total 100%.'),
          const SizedBox(height: 8),
          for (final ingredient in _ingredients) ...[
            Material(
              color: Colors.white,
              child: CheckboxListTile(
                key: ValueKey('available-${ingredient.key}'),
                value: ingredient.available,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(ingredient.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: ingredient.available
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(child: _ingredientField(ingredient, isPrice: true)),
                            const SizedBox(width: 9),
                            Expanded(child: _ingredientField(ingredient, isPrice: false)),
                          ],
                        ),
                      )
                    : null,
                onChanged: (value) {
                  setState(() {
                    ingredient.available = value ?? false;
                    if (!ingredient.available) {
                      ingredient.priceController.clear();
                      ingredient.inclusionController.clear();
                    }
                    _result = null;
                    _error = null;
                  });
                },
              ),
            ),
            if (ingredient != _ingredients.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _ingredientField(_IngredientDraft ingredient, {required bool isPrice}) {
    final controller = isPrice ? ingredient.priceController : ingredient.inclusionController;
    final key = '${isPrice ? 'price' : 'mix'}-${ingredient.key}';
    return TextField(
      key: ValueKey(key),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => _markDirty(),
      decoration: InputDecoration(labelText: isPrice ? 'GH₵ / kg' : 'Mix %', isDense: true),
    );
  }

  Widget _buildCalculateButton(BuildContext context) {
    return SizedBox(
      height: 49,
      child: FilledButton.icon(
        key: const ValueKey('calculate-feed-cost'),
        onPressed: _calculate,
        icon: const Icon(Icons.calculate_outlined),
        label: const Text('Calculate feed cost'),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Text(_error!, style: TextStyle(color: colors.onErrorContainer)),
    );
  }

  Widget _buildResultPanel(BuildContext context, _CostResult result) {
    final overBudget = result.totalCost > result.budget;
    final difference = (result.totalCost - result.budget).abs();
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Cost estimate', '${result.batchKg.toStringAsFixed(2)} kg for ${_birdsController.text} birds over ${_daysController.text} day(s).'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 22,
            runSpacing: 14,
            children: [
              _resultMetric(context, 'Batch cost', _money(result.totalCost)),
              _resultMetric(context, 'Cost / kg', _money(result.costPerKg)),
              _resultMetric(context, 'Budget', _money(result.budget)),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1),
          for (final line in result.lines)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(line.name),
              subtitle: Text('${line.percent.toStringAsFixed(1)}% · ${line.amountKg.toStringAsFixed(2)} kg'),
              trailing: Text(_money(line.cost), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: overBudget ? const Color(0xFFFFF3E8) : const Color(0xFFEEF6EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              overBudget ? 'Over budget by ${_money(difference)}.' : 'Within budget by ${_money(difference)}.',
              style: TextStyle(color: overBudget ? const Color(0xFF8A4F24) : const Color(0xFF356844), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultMetric(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 3),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildNutritionNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        border: Border.all(color: const Color(0xFFEDE0BE)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        'Costing is not nutrition validation. Use ingredient ratios approved by a qualified poultry nutritionist or veterinarian; this calculator does not verify nutrient balance.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF705C36), height: 1.45),
      ),
    );
  }
}