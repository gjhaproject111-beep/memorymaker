import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/passage.dart';

/// Read-only access to the bundled passage library (assets/passages.json).
/// Custom/imported passages are a deliberate V2 extension point (spec §38)
/// and are not implemented here.
class PassageRepository {
  List<Passage>? _cache;

  Future<List<Passage>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/passages/passages.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    final passages = decoded.map((e) => Passage.fromJson(e as Map<String, dynamic>)).toList();
    _cache = passages;
    return passages;
  }

  Future<Passage?> byId(String id) async {
    final all = await loadAll();
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
