import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'farm_store.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key, required this.store});

  final FarmStore store;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: LiveStockColors.canvas,
        appBar: AppBar(
          title: const Text('Marketplace', style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: const TabBar(tabs: [Tab(text: 'Ingredient prices'), Tab(text: 'Buy & sell')]),
        ),
        body: TabBarView(children: [IngredientPricesScreen(store: store), FeedMarketPostsScreen(store: store)]),
      ),
    );
  }
}

const _ingredients = ['Maize', 'Soybean meal', 'Fishmeal', 'Wheat bran', 'Premixes'];

class IngredientPricesScreen extends StatefulWidget {
  const IngredientPricesScreen({super.key, required this.store});

  final FarmStore store;

  @override
  State<IngredientPricesScreen> createState() => _IngredientPricesScreenState();
}

class _IngredientPricesScreenState extends State<IngredientPricesScreen> {
  String _filter = 'All ingredients';
  final _locationQuery = TextEditingController();

  @override
  void dispose() {
    _locationQuery.dispose();
    super.dispose();
  }

  Future<void> _addQuote() async {
    final supplier = TextEditingController();
    final price = TextEditingController();
    final bagKg = TextEditingController(text: '50');
    final location = TextEditingController();
    var ingredient = _ingredients.first;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report a supplier price'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(initialValue: ingredient, decoration: const InputDecoration(labelText: 'Ingredient'), items: _ingredients.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setDialogState(() => ingredient = value ?? _ingredients.first)),
                  const SizedBox(height: 10),
                  TextFormField(controller: supplier, decoration: const InputDecoration(labelText: 'Supplier name'), validator: _required),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: TextFormField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bag price (GH₵)'), validator: (value) => _positive(value, allowZero: false))), const SizedBox(width: 8), Expanded(child: TextFormField(controller: bagKg, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bag kg'), validator: (value) => _positive(value, allowZero: false)))]),
                  const SizedBox(height: 10),
                  TextFormField(controller: location, decoration: const InputDecoration(labelText: 'Market / location'), validator: _required),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () { if (formKey.currentState?.validate() ?? false) Navigator.pop(dialogContext, true); }, child: const Text('Save quote')),
          ],
        ),
      ),
    );
    if (result == true) {
      await widget.store.addSupplierQuote({
        'ingredient': ingredient,
        'supplier': supplier.text.trim(),
        'price': double.parse(price.text),
        'bagKg': double.parse(bagKg.text),
        'location': location.text.trim(),
        'date': DateTime.now().toIso8601String(),
      });
    }
    supplier.dispose();
    price.dispose();
    bagKg.dispose();
    location.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final quotes = widget.store.supplierQuotes.where((quote) {
          final ingredientMatches = _filter == 'All ingredients' || quote['ingredient'] == _filter;
          final locationMatches = quote['location'].toString().toLowerCase().contains(_locationQuery.text.trim().toLowerCase());
          return ingredientMatches && locationMatches;
        }).toList()
          ..sort((a, b) => _perKg(a).compareTo(_perKg(b)));
        return ListView(
          padding: const EdgeInsets.fromLTRB(17, 15, 17, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: LiveStockColors.forest, borderRadius: BorderRadius.circular(8)),
              child: const Text('Compare farmer-reported prices by bag weight and location. Quotes are not live or independently verified.', style: TextStyle(color: Colors.white, height: 1.4)),
            ),
            const SizedBox(height: 14),
            Row(children: [Expanded(child: DropdownButtonFormField<String>(initialValue: _filter, decoration: const InputDecoration(labelText: 'Ingredient', isDense: true), items: ['All ingredients', ..._ingredients].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => _filter = value ?? 'All ingredients'))), const SizedBox(width: 8), Expanded(child: TextField(controller: _locationQuery, decoration: const InputDecoration(labelText: 'Market / town', isDense: true), onChanged: (_) => setState(() {})))]),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: FilledButton.tonalIcon(onPressed: _addQuote, icon: const Icon(Icons.add, size: 18), label: const Text('Report price'))),
            const SizedBox(height: 10),
            const LocalOnlyNote(message: 'Prices are farmer reports saved on this device. Confirm current price, bag weight, supplier, and quality directly.'),
            const SizedBox(height: 14),
            SectionHeading(title: 'Reported quotes', subtitle: '${quotes.length} quote${quotes.length == 1 ? '' : 's'} · lowest per kg first'),
            const SizedBox(height: 8),
            if (quotes.isEmpty)
              const LiveStockPanel(child: EmptyHint(icon: Icons.price_change_outlined, title: 'No reported prices', detail: 'Add a local supplier quote to begin comparing ingredient costs.'))
            else
              ...quotes.map((quote) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LiveStockPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Expanded(child: Text(quote['ingredient'].toString(), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),), Text('${formatGhs(_perKg(quote))}/kg', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: LiveStockColors.forest, fontWeight: FontWeight.w900))]),
                          const SizedBox(height: 5),
                          Text('${quote['supplier']} · ${quote['location']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LiveStockColors.muted)),
                          const SizedBox(height: 3),
                          Text('${formatGhs(_number(quote['price']))} / ${_number(quote['bagKg']).toStringAsFixed(0)} kg · ${formatFarmDate(quote['date'])}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.muted)),
                        ],
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }

  double _perKg(Map<String, dynamic> quote) => _number(quote['price']) / _number(quote['bagKg']);
  double _number(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;
}

class FeedMarketPostsScreen extends StatefulWidget {
  const FeedMarketPostsScreen({super.key, required this.store});

  final FarmStore store;

  @override
  State<FeedMarketPostsScreen> createState() => _FeedMarketPostsScreenState();
}

class _FeedMarketPostsScreenState extends State<FeedMarketPostsScreen> {
  String _filter = 'All';

  Future<void> _addPost() async {
    final title = TextEditingController();
    final quantity = TextEditingController();
    final price = TextEditingController();
    final location = TextEditingController();
    var kind = 'Feed for sale';
    var feedType = _ingredients.first;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isFeed = kind == 'Feed for sale' || kind == 'Feed wanted';
          return AlertDialog(
            title: const Text('New marketplace post'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(initialValue: kind, decoration: const InputDecoration(labelText: 'Post type'), items: const ['Feed for sale', 'Feed wanted', 'Eggs for sale', 'Birds for sale'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setDialogState(() => kind = value ?? 'Feed for sale')),
                    if (isFeed) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(initialValue: feedType, decoration: const InputDecoration(labelText: 'Ingredient / feed type'), items: _ingredients.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setDialogState(() => feedType = value ?? _ingredients.first)),
                    ],
                    const SizedBox(height: 10),
                    TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Title'), validator: _required),
                    const SizedBox(height: 10),
                    TextFormField(controller: quantity, decoration: const InputDecoration(labelText: 'Quantity'), validator: _required),
                    const SizedBox(height: 10),
                    TextFormField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: kind == 'Feed wanted' ? 'Budget (GH₵)' : 'Price (GH₵)'), validator: (value) => _positive(value, allowZero: true)),
                    const SizedBox(height: 10),
                    TextFormField(controller: location, decoration: const InputDecoration(labelText: 'Town / district'), validator: _required),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(onPressed: () { if (formKey.currentState?.validate() ?? false) Navigator.pop(dialogContext, true); }, child: const Text('Save post')),
            ],
          );
        },
      ),
    );
    if (result == true) {
      await widget.store.addMarketPost({'kind': kind, 'feedType': kind == 'Feed for sale' || kind == 'Feed wanted' ? feedType : '', 'title': title.text.trim(), 'quantity': quantity.text.trim(), 'price': double.parse(price.text), 'location': location.text.trim(), 'date': DateTime.now().toIso8601String()});
    }
    title.dispose();
    quantity.dispose();
    price.dispose();
    location.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final posts = widget.store.marketPosts.where((post) => _filter == 'All' || (_filter == 'Selling' ? post['kind'] != 'Feed wanted' : post['kind'] == 'Feed wanted')).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(17, 15, 17, 30),
          children: [
            const PageHeading(eyebrow: 'LOCAL MARKETPLACE', title: 'Buy and sell', subtitle: 'Post feed, ingredient, egg, and bird offers.'),
            const SizedBox(height: 12),
            const LocalOnlyNote(message: 'Posts are visible only on this device until a shared marketplace service is connected. Verify suppliers and product quality before buying.'),
            const SizedBox(height: 13),
            SegmentedButton<String>(segments: const [ButtonSegment(value: 'All', label: Text('All')), ButtonSegment(value: 'Selling', label: Text('Selling')), ButtonSegment(value: 'Wanted', label: Text('Buy orders'))], selected: {_filter}, onSelectionChanged: (value) => setState(() => _filter = value.first)),
            const SizedBox(height: 12),
            SectionHeading(title: 'Your posts', trailing: FilledButton.tonalIcon(onPressed: _addPost, icon: const Icon(Icons.add, size: 18), label: const Text('Create'))),
            const SizedBox(height: 8),
            if (posts.isEmpty)
              const LiveStockPanel(child: EmptyHint(icon: Icons.storefront_outlined, title: 'No posts yet', detail: 'Create a feed sale, buy order, or farm product post.'))
            else
              ...posts.map((post) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LiveStockPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Expanded(child: Text(post['kind'].toString().toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.leaf, fontWeight: FontWeight.w900, letterSpacing: 0.6)),), Text(formatGhs(_number(post['price'])), style: const TextStyle(fontWeight: FontWeight.w900))]),
                          const SizedBox(height: 5),
                          Text(post['title'].toString(), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          Text('${post['feedType'] == '' ? '' : '${post['feedType']} · '}${post['quantity']} · ${post['location']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LiveStockColors.muted)),
                          const SizedBox(height: 4),
                          Text('Saved locally · ${formatFarmDate(post['date'])}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.muted)),
                        ],
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }

  double _number(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;
}

String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;

String? _positive(String? value, {required bool allowZero}) {
  final number = double.tryParse(value ?? '');
  if (number == null || (allowZero ? number < 0 : number <= 0)) return 'Enter a valid amount';
  return null;
}