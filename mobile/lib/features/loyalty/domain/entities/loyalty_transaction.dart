import 'package:equatable/equatable.dart';

enum LoyaltyTransactionType { earned, spent }

class LoyaltyTransaction extends Equatable {
  final String id;
  final int amount;
  final LoyaltyTransactionType type;
  final DateTime date;
  final String description;

  const LoyaltyTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.description,
  });

  @override
  List<Object?> get props => [id, amount, type, date, description];
}
