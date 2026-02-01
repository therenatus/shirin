import 'package:equatable/equatable.dart';

enum CoffeeSize { S, M, L }

class PunchCard extends Equatable {
  final String id;
  final CoffeeSize size;
  final String sizeName;
  final int currentPunches;
  final int maxPunches;
  final bool isComplete;
  final bool freeItemClaimed;
  final DateTime createdAt;
  final DateTime? completedAt;

  const PunchCard({
    required this.id,
    required this.size,
    required this.sizeName,
    required this.currentPunches,
    required this.maxPunches,
    required this.isComplete,
    required this.freeItemClaimed,
    required this.createdAt,
    this.completedAt,
  });

  int get remainingPunches => maxPunches - currentPunches;

  String get progressText => '$currentPunches из $maxPunches';

  @override
  List<Object?> get props => [
        id,
        size,
        sizeName,
        currentPunches,
        maxPunches,
        isComplete,
        freeItemClaimed,
        createdAt,
        completedAt,
      ];
}
