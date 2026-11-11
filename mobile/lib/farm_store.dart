import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmStore extends ChangeNotifier {
  FarmStore._(this._preferences);

  final SharedPreferences _preferences;

  static const _flockKey = 'livestock.mobile.flocks';
  static const _logKey = 'livestock.mobile.flockLogs';
  static const _eggKey = 'livestock.mobile.eggCollections';
  static const _feedKey = 'livestock.mobile.feedRecords';
  static const _quoteKey = 'livestock.mobile.supplierQuotes';
  static const _postKey = 'livestock.mobile.marketPosts';
  static const _healthKey = 'livestock.mobile.healthReports';

  List<Map<String, dynamic>> flocks = [];
  List<Map<String, dynamic>> flockLogs = [];
  List<Map<String, dynamic>> eggCollections = [];
  List<Map<String, dynamic>> feedRecords = [];
  List<Map<String, dynamic>> supplierQuotes = [];
  List<Map<String, dynamic>> marketPosts = [];
  List<Map<String, dynamic>> healthReports = [];

  static Future<FarmStore> load() async {
    final preferences = await SharedPreferences.getInstance();
    final store = FarmStore._(preferences);
    store.flocks = store._readList(_flockKey) ?? _initialFlocks;
    store.flockLogs = store._readList(_logKey) ?? [];
    store.eggCollections = store._readList(_eggKey) ?? [];
    store.feedRecords = store._readList(_feedKey) ?? [];
    store.supplierQuotes = store._readList(_quoteKey) ?? [];
    store.marketPosts = store._readList(_postKey) ?? [];
    store.healthReports = store._readList(_healthKey) ?? [];
    return store;
  }

  static final _initialFlocks = <Map<String, dynamic>>[
    {'id': 'layers-a', 'name': 'Layers Batch A', 'birdType': 'Layer', 'birds': 640, 'ageWeeks': 24},
    {'id': 'broilers-b', 'name': 'Broilers Batch B', 'birdType': 'Broiler', 'birds': 600, 'ageWeeks': 4},
  ];

  List<Map<String, dynamic>>? _readList(String key) {
    final encoded = _preferences.getString(key);
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> value) async {
    await _preferences.setString(key, jsonEncode(value));
    notifyListeners();
  }

  Future<void> addFlock(Map<String, dynamic> flock) async {
    flocks = [flock, ...flocks];
    await _writeList(_flockKey, flocks);
  }

  Future<void> addFlockLog(Map<String, dynamic> log) async {
    flockLogs = [log, ...flockLogs];
    await _writeList(_logKey, flockLogs);
  }

  Future<void> addEggCollection(Map<String, dynamic> collection) async {
    eggCollections = [collection, ...eggCollections];
    await _writeList(_eggKey, eggCollections);
  }

  Future<void> addFeedRecord(Map<String, dynamic> record) async {
    feedRecords = [record, ...feedRecords];
    await _writeList(_feedKey, feedRecords);
  }

  Future<void> addSupplierQuote(Map<String, dynamic> quote) async {
    supplierQuotes = [quote, ...supplierQuotes];
    await _writeList(_quoteKey, supplierQuotes);
  }

  Future<void> addMarketPost(Map<String, dynamic> post) async {
    marketPosts = [post, ...marketPosts];
    await _writeList(_postKey, marketPosts);
  }

  Future<void> addHealthReport(Map<String, dynamic> report) async {
    healthReports = [report, ...healthReports];
    await _writeList(_healthKey, healthReports);
  }

  List<Map<String, String>> get recommendations {
    final result = <Map<String, String>>[];
    final sortedUsage = [...feedRecords]
      ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
    if (sortedUsage.isNotEmpty) {
      final latest = sortedUsage.first;
      final dailyKg = _number(latest['dailyFeedKg']);
      final stockKg = _number(latest['stockRemaining']);
      final birds = _number(latest['birds']);
      final requirementDays = 7;
      final requiredKg = dailyKg * requirementDays;
      if (stockKg < requiredKg) {
        result.add({
          'kind': 'attention',
          'title': 'Feed stock may run short',
          'detail': '${stockKg.toStringAsFixed(1)} kg remains; your latest use rate projects ${requiredKg.toStringAsFixed(1)} kg for seven days.',
        });
      }
      final birdType = latest['birdType']?.toString() ?? '';
      final ageWeeks = _number(latest['ageWeeks']);
      final expected = expectedDailyGrams(birdType, ageWeeks);
      final actual = birds > 0 ? dailyKg * 1000 / birds : 0;
      if (expected > 0 && ((actual - expected) / expected).abs() >= 0.25) {
        result.add({
          'kind': 'attention',
          'title': 'Feed use differs from the planning estimate',
          'detail': '${actual.toStringAsFixed(0)} g per bird daily versus the adjustable ${expected.toStringAsFixed(0)} g stage estimate. Check records and feeding conditions.',
        });
      }
    }

    final recentQuotes = supplierQuotes.where((quote) => _daysOld(quote['date']) <= 90).toList();
    final groupedQuotes = <String, List<Map<String, dynamic>>>{};
    for (final quote in recentQuotes) {
      final key = '${quote['ingredient']}|${quote['location']}|${quote['supplier']}';
      (groupedQuotes[key] ??= []).add(quote);
    }
    for (final history in groupedQuotes.values) {
      history.sort((a, b) => _dateOf(a).compareTo(_dateOf(b)));
      if (history.length < 2) continue;
      final previous = _pricePerKg(history[history.length - 2]);
      final current = _pricePerKg(history.last);
      if (previous > 0 && (current - previous) / previous >= 0.10) {
        result.add({
          'kind': 'attention',
          'title': '${history.last['ingredient']} price increased',
          'detail': '${history.last['supplier']} in ${history.last['location']} reported a rise of ${((current - previous) / previous * 100).round()}% per kg. Confirm the quote before buying.',
        });
      }
    }

    final latestBySupplier = <String, Map<String, dynamic>>{};
    for (final quote in supplierQuotes.where((item) => _daysOld(item['date']) <= 30)) {
      final key = '${quote['ingredient']}|${quote['location']}|${quote['supplier']}';
      final prior = latestBySupplier[key];
      if (prior == null || _dateOf(quote).isAfter(_dateOf(prior))) latestBySupplier[key] = quote;
    }
    final marketGroups = <String, List<Map<String, dynamic>>>{};
    for (final quote in latestBySupplier.values) {
      final key = '${quote['ingredient']}|${quote['location']}';
      (marketGroups[key] ??= []).add(quote);
    }
    for (final quotes in marketGroups.values) {
      quotes.sort((a, b) => _pricePerKg(a).compareTo(_pricePerKg(b)));
      if (quotes.length < 2) continue;
      final cheapest = _pricePerKg(quotes.first);
      final other = _pricePerKg(quotes[1]);
      if (other > 0 && (other - cheapest) / other >= 0.05) {
        result.add({
          'kind': 'opportunity',
          'title': 'Compare ${quotes.first['ingredient']} quotes',
          'detail': '${quotes.first['supplier']} reported ${_money(cheapest)}/kg in ${quotes.first['location']}, below another recent quote. Confirm quality and availability.',
        });
      }
    }
    return result.take(5).toList();
  }

  static double expectedDailyGrams(String birdType, double ageWeeks) {
    if (birdType.toLowerCase() == 'broiler') {
      if (ageWeeks < 3) return 50;
      if (ageWeeks < 6) return 100;
      return 150;
    }
    if (ageWeeks < 8) return 40;
    if (ageWeeks < 18) return 70;
    return 110;
  }

  static double _pricePerKg(Map<String, dynamic> quote) {
    final weight = _number(quote['bagKg']);
    return weight > 0 ? _number(quote['price']) / weight : 0;
  }

  static DateTime _dateOf(Map<String, dynamic> record) => DateTime.tryParse(record['date']?.toString() ?? '') ?? DateTime(1970);

  static int _daysOld(Object? value) => DateTime.now().difference(_dateOf({'date': value})).inDays;

  static double _number(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;

  static String _money(double value) => 'GH₵ ${value.toStringAsFixed(2)}';
}