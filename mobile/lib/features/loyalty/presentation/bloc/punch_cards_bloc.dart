import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/punch_card.dart';
import '../../domain/usecases/get_punch_cards.dart';
import '../../domain/usecases/claim_free_coffee.dart';

// Events
abstract class PunchCardsEvent extends Equatable {
  const PunchCardsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPunchCards extends PunchCardsEvent {
  const LoadPunchCards();
}

class ClaimFreeCoffeeEvent extends PunchCardsEvent {
  final CoffeeSize size;
  const ClaimFreeCoffeeEvent(this.size);
  @override
  List<Object?> get props => [size];
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

class FreeCoffeeClaimed extends PunchCardsState {
  final PunchCard updatedCard;
  const FreeCoffeeClaimed(this.updatedCard);
  @override
  List<Object?> get props => [updatedCard];
}

// BLoC
class PunchCardsBloc extends Bloc<PunchCardsEvent, PunchCardsState> {
  final GetPunchCards getPunchCards;
  final ClaimFreeCoffee claimFreeCoffee;

  List<PunchCard> _currentCards = [];

  PunchCardsBloc({
    required this.getPunchCards,
    required this.claimFreeCoffee,
  }) : super(const PunchCardsInitial()) {
    on<LoadPunchCards>(_onLoadPunchCards);
    on<ClaimFreeCoffeeEvent>(_onClaimFreeCoffee);
  }

  Future<void> _onLoadPunchCards(
    LoadPunchCards event,
    Emitter<PunchCardsState> emit,
  ) async {
    emit(const PunchCardsLoading());
    final result = await getPunchCards();
    result.fold(
      (failure) => emit(PunchCardsError(failure.message)),
      (cards) {
        _currentCards = cards;
        emit(PunchCardsLoaded(cards));
      },
    );
  }

  Future<void> _onClaimFreeCoffee(
    ClaimFreeCoffeeEvent event,
    Emitter<PunchCardsState> emit,
  ) async {
    final result = await claimFreeCoffee(event.size);
    result.fold(
      (failure) => emit(PunchCardsError(failure.message)),
      (updatedCard) {
        // Update the card in the list
        _currentCards = _currentCards.map((card) {
          return card.size == updatedCard.size ? updatedCard : card;
        }).toList();
        emit(FreeCoffeeClaimed(updatedCard));
        emit(PunchCardsLoaded(_currentCards));
      },
    );
  }
}
