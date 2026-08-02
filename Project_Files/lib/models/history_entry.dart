/// Bir ürünün nihai akıbeti.
enum ProductOutcome { rescued, wasted }

class HistoryEntry {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final DateTime expiryDate;
  final ProductOutcome outcome;
  final DateTime decidedAt;

  HistoryEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.outcome,
    required this.decidedAt,
  });

  bool get wasRescued => outcome == ProductOutcome.rescued;

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'expiryDate': expiryDate.toIso8601String(),
        'outcome': outcome.name,
        'decidedAt': decidedAt.toIso8601String(),
      };

  factory HistoryEntry.fromMap(String id, Map<String, dynamic> map) =>
      HistoryEntry(
        id: id,
        name: map['name'] as String,
        category: map['category'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String,
        expiryDate: DateTime.parse(map['expiryDate'] as String),
        outcome: ProductOutcome.values.byName(map['outcome'] as String),
        decidedAt: DateTime.parse(map['decidedAt'] as String),
      );
}
