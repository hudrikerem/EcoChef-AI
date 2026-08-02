import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/history_entry.dart';
import '../models/achievement.dart';

class ProductStore extends ChangeNotifier {
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Product> _products = [];
  List<HistoryEntry> _history = [];
  List<DateTime> _recipeLog = [];
  Map<String, Color> _categoryColors = {};
  List<String> _categoryOrder = [];
  String? _avatarPresetId;
  String? _avatarImageBase64;
  String? _guestDisplayName;
  int? _totalTrackedCount;

  StreamSubscription? _productsSub;
  StreamSubscription? _historySub;
  StreamSubscription? _recipeLogSub;
  StreamSubscription? _categoryColorsSub;
  StreamSubscription? _categoryOrderSub;
  StreamSubscription? _profileSub;
  StreamSubscription? _statsSub;

  ProductStore({required this.uid}) {
    _listenToFirestore();
  }

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _db.collection('users').doc(uid).collection('products');

  CollectionReference<Map<String, dynamic>> get _historyRef =>
      _db.collection('users').doc(uid).collection('history');

  CollectionReference<Map<String, dynamic>> get _recipeLogRef =>
      _db.collection('users').doc(uid).collection('recipe_log');

  DocumentReference<Map<String, dynamic>> get _categoryColorsRef =>
      _db.collection('users').doc(uid).collection('meta').doc('categoryColors');

  DocumentReference<Map<String, dynamic>> get _profileRef =>
      _db.collection('users').doc(uid).collection('meta').doc('profile');

  DocumentReference<Map<String, dynamic>> get _categoryOrderRef =>
      _db.collection('users').doc(uid).collection('meta').doc('categoryOrder');

  DocumentReference<Map<String, dynamic>> get _statsRef =>
      _db.collection('users').doc(uid).collection('meta').doc('stats');

  void _listenToFirestore() {
    _productsSub = _productsRef.snapshots().listen((snapshot) {
      _products =
          snapshot.docs.map((d) => Product.fromMap(d.id, d.data())).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint('EcoChef ürün akışı hatası: $error');
    });

    _historySub =
        _historyRef.orderBy('decidedAt', descending: true).snapshots().listen(
      (snapshot) {
        _history = snapshot.docs
            .map((d) => HistoryEntry.fromMap(d.id, d.data()))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('EcoChef geçmiş akışı hatası: $error');
      },
    );

    _recipeLogSub = _recipeLogRef.snapshots().listen((snapshot) {
      _recipeLog = snapshot.docs
          .map((d) => DateTime.parse(d.data()['madeAt'] as String))
          .toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint('EcoChef tarif akışı hatası: $error');
    });

    _categoryColorsSub = _categoryColorsRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      final rawColors = data?['colors'] as Map<String, dynamic>? ?? {};
      _categoryColors = {
        for (final entry in rawColors.entries)
          entry.key: Color(entry.value as int),
      };
      notifyListeners();
    }, onError: (error) {
      debugPrint('EcoChef kategori renk akışı hatası: $error');
    });

    _profileSub = _profileRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      _avatarPresetId = data?['avatarPresetId'] as String?;
      _avatarImageBase64 = data?['avatarImageBase64'] as String?;
      _guestDisplayName = data?['guestDisplayName'] as String?;
      notifyListeners();
    }, onError: (error) {
      debugPrint('EcoChef profil akışı hatası: $error');
    });

    _categoryOrderSub = _categoryOrderRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      final rawOrder = data?['order'] as List<dynamic>? ?? [];
      _categoryOrder = rawOrder.map((e) => e.toString()).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint('EcoChef kategori sırası akışı hatası: $error');
    });

    _statsSub = _statsRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data.containsKey('totalTrackedCount')) {
        _totalTrackedCount = (data['totalTrackedCount'] as num).toInt();
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('EcoChef istatistik akışı hatası: $error');
    });
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _historySub?.cancel();
    _recipeLogSub?.cancel();
    _categoryColorsSub?.cancel();
    _profileSub?.cancel();
    _categoryOrderSub?.cancel();
    _statsSub?.cancel();
    super.dispose();
  }

  List<Product> get products => List.unmodifiable(_products);
  List<HistoryEntry> get history => List.unmodifiable(_history);

  int get rescuedCount =>
      _history.where((h) => h.outcome == ProductOutcome.rescued).length;

  int get wastedCount =>
      _history.where((h) => h.outcome == ProductOutcome.wasted).length;

  int get totalTracked =>
      _totalTrackedCount ?? (_products.length + _history.length);

  int get recipesMade => _recipeLog.length;

  List<Achievement> get unlockedAchievements => allAchievements
      .where((a) => _metricValue(a.metric) >= a.threshold)
      .toList();

  List<Achievement> get lockedAchievements => allAchievements
      .where((a) => _metricValue(a.metric) < a.threshold)
      .toList();

  int _metricValue(AchievementMetric metric) {
    switch (metric) {
      case AchievementMetric.rescued:
        return rescuedCount;
      case AchievementMetric.recipes:
        return recipesMade;
    }
  }

  List<AchievementUnlock> get achievementHistory {
    final rescuedTimestamps = _history
        .where((h) => h.outcome == ProductOutcome.rescued)
        .map((h) => h.decidedAt)
        .toList()
      ..sort();
    final recipeTimestamps = [..._recipeLog]..sort();

    final unlocks = <AchievementUnlock>[];
    for (final achievement in allAchievements) {
      final timestamps = achievement.metric == AchievementMetric.rescued
          ? rescuedTimestamps
          : recipeTimestamps;
      if (timestamps.length >= achievement.threshold) {
        unlocks.add(AchievementUnlock(
          achievement: achievement,
          achievedAt: timestamps[achievement.threshold - 1],
        ));
      }
    }
    unlocks.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    return unlocks;
  }

  Future<void> recordRecipeMade() async {
    await _recipeLogRef.add({'madeAt': DateTime.now().toIso8601String()});
  }

  bool isNameTaken(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _products.any((p) => p.name.trim().toLowerCase() == normalized);
  }

  Future<void> addProduct(Product product) async {
    await _db.runTransaction((transaction) async {
      final statsSnap = await transaction.get(_statsRef);
      final statsData = statsSnap.data();

      if (statsData != null && statsData.containsKey('totalTrackedCount')) {
        final current = (statsData['totalTrackedCount'] as num).toInt();
        transaction.set(
          _statsRef,
          {'totalTrackedCount': current + 1},
          SetOptions(merge: true),
        );
      } else {
        final baseline = _products.length + _history.length + 1;
        transaction.set(_statsRef, {'totalTrackedCount': baseline});
      }

      transaction.set(_productsRef.doc(product.id), product.toMap());
    });

    final prefs = await SharedPreferences.getInstance();
    final notifEnabled = prefs.getBool('notificationsEnabled') ?? true;
    final daysBefore = prefs.getInt('reminderDaysBefore') ?? 3;

    if (notifEnabled) {
      await NotificationService().scheduleExpiryNotification(
        productId: product.id,
        productName: product.name,
        expiryDate: product.expiryDate,
        daysBefore: daysBefore,
      );
    }
  }

  Future<void> updateProduct(
    String id, {
    double? quantity,
    DateTime? expiryDate,
  }) async {
    final updates = <String, dynamic>{};
    if (quantity != null) updates['quantity'] = quantity;
    if (expiryDate != null) {
      updates['expiryDate'] = expiryDate.toIso8601String();
    }
    if (updates.isEmpty) return;
    await _productsRef.doc(id).update(updates);
  }

  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
    await NotificationService().cancelNotification(id); // EKLENDİ
  }

  Future<void> markConsumed(String id) =>
      _moveToHistory(id, ProductOutcome.rescued);

  Future<void> markWasted(String id) =>
      _moveToHistory(id, ProductOutcome.wasted);

  Future<void> _moveToHistory(String id, ProductOutcome outcome) async {
    await NotificationService().cancelNotification(id); // EKLENDİ
    final product = _products.firstWhere((p) => p.id == id);
    final entry = HistoryEntry(
      id: product.id,
      name: product.name,
      category: product.category,
      quantity: product.quantity,
      unit: product.unit,
      expiryDate: product.expiryDate,
      outcome: outcome,
      decidedAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.delete(_productsRef.doc(id));
    batch.set(_historyRef.doc(id), entry.toMap());
    await batch.commit();
  }

  static const List<String> predefinedCategories = [
    'Süt Ürünleri',
    'Meyve & Sebze',
    'Kahvaltılık',
    'Temel Gıda',
    'Et, Tavuk & Balık',
    'Atıştırmalık',
    'Dondurulmuş Gıda',
  ];

  static const Map<String, Color> defaultCategoryColors = {
    'Süt Ürünleri': Color(0xFFE8DCC0),
    'Meyve & Sebze': Color(0xFF8BC34A),
    'Kahvaltılık': Color(0xFFFFB74D),
    'Temel Gıda': Color(0xFFA1887F),
    'Et, Tavuk & Balık': Color(0xFFE57373),
    'Atıştırmalık': Color(0xFFBA68C8),
    'Dondurulmuş Gıda': Color(0xFF4FC3F7),
  };

  static const List<Color> categoryColorPalette = [
    Color(0xFFE8DCC0),
    Color(0xFF8BC34A),
    Color(0xFFFFB74D),
    Color(0xFFA1887F),
    Color(0xFFE57373),
    Color(0xFFBA68C8),
    Color(0xFF4FC3F7),
    Color(0xFF90A4AE),
    Color(0xFF4DB6AC),
    Color(0xFFF06292),
    Color(0xFF9575CD),
    Color(0xFFAED581),
    Color(0xFFFFD54F),
    Color(0xFF7986CB),
    Color(0xFF4DD0E1),
    Color(0xFFA1C181),
  ];

  Map<String, Color> get categoryColors => Map.unmodifiable(_categoryColors);

  List<String> get knownCategories {
    final set = <String>{...predefinedCategories, ..._categoryColors.keys};
    final list = set.toList();
    list.sort((a, b) {
      final indexA = predefinedCategories.indexOf(a);
      final indexB = predefinedCategories.indexOf(b);
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      return a.compareTo(b);
    });
    return list;
  }

  Color colorForCategory(String category) {
    return _categoryColors[category] ??
        defaultCategoryColors[category] ??
        const Color(0xFF90A4AE);
  }

  String? categoryUsingColor(Color color) {
    for (final entry in _categoryColors.entries) {
      if (entry.value.toARGB32() == color.toARGB32()) return entry.key;
    }
    return null;
  }

  Future<void> ensureCategoryColor(String category) async {
    if (_categoryColors.containsKey(category)) return;

    final usedColors = _categoryColors.values.toSet();
    final defaultColor = defaultCategoryColors[category];
    final chosen = (defaultColor != null && !usedColors.contains(defaultColor))
        ? defaultColor
        : _pickUnusedColor(usedColors);

    await _saveCategoryColor(category, chosen);
  }

  Future<void> setCategoryColor(String category, Color color) =>
      _saveCategoryColor(category, color);

  Future<void> _saveCategoryColor(String category, Color color) async {
    _categoryColors = {..._categoryColors, category: color};
    notifyListeners();

    await _categoryColorsRef.set(
      {'colors': {category: color.toARGB32()}},
      SetOptions(merge: true),
    );
  }

  Color _pickUnusedColor(Set<Color> usedColors) {
    final available =
        categoryColorPalette.where((c) => !usedColors.contains(c)).toList();
    if (available.isNotEmpty) {
      available.shuffle();
      return available.first;
    }
    final random = Random();
    return Color.fromARGB(
      255,
      40 + random.nextInt(190),
      40 + random.nextInt(190),
      40 + random.nextInt(190),
    );
  }

  List<String> get categoryOrder => List.unmodifiable(_categoryOrder);

  Future<void> reorderCategories(List<String> newOrder) async {
    _categoryOrder = newOrder;
    notifyListeners();
    await _categoryOrderRef.set({'order': newOrder});
  }

  String? get avatarPresetId => _avatarPresetId;
  String? get avatarImageBase64 => _avatarImageBase64;
  String? get guestDisplayName => _guestDisplayName;

  Future<void> setGuestDisplayName(String name) async {
    _guestDisplayName = name;
    notifyListeners();
    await _profileRef.set({'guestDisplayName': name}, SetOptions(merge: true));
  }

  Future<void> setAvatarPreset(String presetId) async {
    _avatarPresetId = presetId;
    _avatarImageBase64 = null;
    notifyListeners();
    await _profileRef.set({
      'avatarPresetId': presetId,
      'avatarImageBase64': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> setAvatarImage(String base64Image) async {
    _avatarImageBase64 = base64Image;
    _avatarPresetId = null;
    notifyListeners();
    await _profileRef.set({
      'avatarImageBase64': base64Image,
      'avatarPresetId': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
  Future<void> deleteHistoryEntry(String historyId) async {
  await _historyRef.doc(historyId).delete();
}
}