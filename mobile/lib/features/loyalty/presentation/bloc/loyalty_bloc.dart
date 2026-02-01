import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/loyalty_info.dart';
import '../../domain/entities/loyalty_transaction.dart';
import '../../domain/usecases/get_loyalty_info.dart';
import '../../domain/usecases/get_loyalty_history.dart';

// Events
abstract class LoyaltyEvent extends Equatable {
  const LoyaltyEvent();
  @override
  List<Object?> get props => [];
}

class LoadLoyaltyInfo extends LoyaltyEvent {
  const LoadLoyaltyInfo();
}

class LoadLoyaltyHistory extends LoyaltyEvent {
  const LoadLoyaltyHistory();
}

// States
abstract class LoyaltyState extends Equatable {
  const LoyaltyState();
  @override
  List<Object?> get props => [];
}

class LoyaltyInitial extends LoyaltyState {
  const LoyaltyInitial();
}

class LoyaltyLoading extends LoyaltyState {
  const LoyaltyLoading();
}

class LoyaltyInfoLoaded extends LoyaltyState {
  final LoyaltyInfo info;
  const LoyaltyInfoLoaded(this.info);
  @override
  List<Object?> get props => [info];
}

class LoyaltyHistoryLoaded extends LoyaltyState {
  final List<LoyaltyTransaction> transactions;
  const LoyaltyHistoryLoaded(this.transactions);
  @override
  List<Object?> get props => [transactions];
}

class LoyaltyError extends LoyaltyState {
  final String message;
  const LoyaltyError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final GetLoyaltyInfo getLoyaltyInfo;
  final GetLoyaltyHistory getLoyaltyHistory;

  LoyaltyBloc({
    required this.getLoyaltyInfo,
    required this.getLoyaltyHistory,
  }) : super(const LoyaltyInitial()) {
    on<LoadLoyaltyInfo>(_onLoadInfo);
    on<LoadLoyaltyHistory>(_onLoadHistory);
  }

  Future<void> _onLoadInfo(
    LoadLoyaltyInfo event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(const LoyaltyLoading());
    final result = await getLoyaltyInfo();
    result.fold(
      (failure) => emit(LoyaltyError(failure.message)),
      (info) => emit(LoyaltyInfoLoaded(info)),
    );
  }

  Future<void> _onLoadHistory(
    LoadLoyaltyHistory event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(const LoyaltyLoading());
    final result = await getLoyaltyHistory();
    result.fold(
      (failure) => emit(LoyaltyError(failure.message)),
      (transactions) => emit(LoyaltyHistoryLoaded(transactions)),
    );
  }
}
