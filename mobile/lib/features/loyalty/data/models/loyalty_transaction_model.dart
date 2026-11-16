import '../../domain/entities/loyalty_transaction.dart';

/// Row of `GET /loyalty/history`:
/// `{id, type: earned|used|refunded, points (signed), description, createdAt}`.
class LoyaltyTransactionModel {
  final String id;

  /// Signed: positive credits, negative debits.
  final int points;
  final DateTime date;
  final String description;

  const LoyaltyTransactionModel({
    required this.id,
    required this.points,
    required this.date,
    required this.description,
  });

  factory LoyaltyTransactionModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransactionModel(
      id: json['id'] as String,
      points: (json['points'] as num).toInt(),
      date: DateTime.parse(json['createdAt'] as String).toLocal(),
      description: (json['description'] as String?) ?? '',
    );
  }

  LoyaltyTransaction toEntity() {
    return LoyaltyTransaction(
      id: id,
      amount: points.abs(),
      type: points >= 0
          ? LoyaltyTransactionType.earned
          : LoyaltyTransactionType.spent,
      date: date,
      description: description,
    );
  }
}
