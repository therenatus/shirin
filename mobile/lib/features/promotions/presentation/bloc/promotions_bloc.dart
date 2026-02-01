import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/usecases/get_promotions.dart';

// Events
abstract class PromotionsEvent extends Equatable {
  const PromotionsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPromotions extends PromotionsEvent {
  const LoadPromotions();
}

// States
abstract class PromotionsState extends Equatable {
  const PromotionsState();
  @override
  List<Object?> get props => [];
}

class PromotionsInitial extends PromotionsState {
  const PromotionsInitial();
}

class PromotionsLoading extends PromotionsState {
  const PromotionsLoading();
}

class PromotionsLoaded extends PromotionsState {
  final List<Promotion> promotions;
  const PromotionsLoaded(this.promotions);
  @override
  List<Object?> get props => [promotions];
}

class PromotionsError extends PromotionsState {
  final String message;
  const PromotionsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class PromotionsBloc extends Bloc<PromotionsEvent, PromotionsState> {
  final GetPromotions getPromotions;

  PromotionsBloc({required this.getPromotions})
      : super(const PromotionsInitial()) {
    on<LoadPromotions>(_onLoadPromotions);
  }

  Future<void> _onLoadPromotions(
    LoadPromotions event,
    Emitter<PromotionsState> emit,
  ) async {
    emit(const PromotionsLoading());
    final result = await getPromotions();
    result.fold(
      (failure) => emit(PromotionsError(failure.message)),
      (promotions) => emit(PromotionsLoaded(promotions)),
    );
  }
}
