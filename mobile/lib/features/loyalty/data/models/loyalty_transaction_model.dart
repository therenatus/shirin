import '../../domain/entities/loyalty_transaction.dart';

class LoyaltyTransactionModel {
  final String id;
  final int amount;
  final String type;
  final DateTime date;
  final String description;

  const LoyaltyTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.description,
  });

  factory LoyaltyTransactionModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
    );
  }

  LoyaltyTransaction toEntity() {
    return LoyaltyTransaction(
      id: id,
      amount: amount,
      type: type == 'earned'
          ? LoyaltyTransactionType.earned
          : LoyaltyTransactionType.spent,
      date: date,
      description: description,
    );
  }
}
