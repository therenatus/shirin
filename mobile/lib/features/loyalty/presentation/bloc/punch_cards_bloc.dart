import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/punch_card.dart';
import '../../domain/usecases/get_punch_cards.dart';

// Events
abstract class PunchCardsEvent extends Equatable {
  const PunchCardsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPunchCards extends PunchCardsEvent {
  const LoadPunchCards();
}

// States
abstract class PunchCardsState extends Equatable {
  const PunchCardsState();
  @override
  List<Object?> get props => [];
}

class PunchCardsInitial extends PunchCardsState {
  const PunchCardsInitial();
}

class PunchCardsLoading extends PunchCardsState {
  const PunchCardsLoading();
}

class PunchCardsLoaded extends PunchCardsState {
  final List<PunchCard> punchCards;
  const PunchCardsLoaded(this.punchCards);
  @override
  List<Object?> get props => [punchCards];
}

class PunchCardsError extends PunchCardsState {
  final String message;
  const PunchCardsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class PunchCardsBloc extends Bloc<PunchCardsEvent, PunchCardsState> {
  final GetPunchCards getPunchCards;

  PunchCardsBloc({
    required this.getPunchCards,
  }) : super(const PunchCardsInitial()) {
    on<LoadPunchCards>(_onLoadPunchCards);
  }

  Future<void> _onLoadPunchCards(
    LoadPunchCards event,
    Emitter<PunchCardsState> emit,
  ) async {
    emit(const PunchCardsLoading());
    final result = await getPunchCards();
    result.fold(
      (failure) => emit(PunchCardsError(failure.message)),
      (cards) => emit(PunchCardsLoaded(cards)),
    );
  }
}
