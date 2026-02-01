import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/store.dart';
import '../../domain/usecases/get_stores.dart';

// Events
abstract class StoresEvent extends Equatable {
  const StoresEvent();
  @override
  List<Object?> get props => [];
}

class LoadStores extends StoresEvent {
  const LoadStores();
}

// States
abstract class StoresState extends Equatable {
  const StoresState();
  @override
  List<Object?> get props => [];
}

class StoresInitial extends StoresState {
  const StoresInitial();
}

class StoresLoading extends StoresState {
  const StoresLoading();
}

class StoresLoaded extends StoresState {
  final List<Store> stores;
  const StoresLoaded(this.stores);
  @override
  List<Object?> get props => [stores];
}

class StoresError extends StoresState {
  final String message;
  const StoresError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class StoresBloc extends Bloc<StoresEvent, StoresState> {
  final GetStores getStores;

  StoresBloc({required this.getStores}) : super(const StoresInitial()) {
    on<LoadStores>(_onLoadStores);
  }

  Future<void> _onLoadStores(
    LoadStores event,
    Emitter<StoresState> emit,
  ) async {
    emit(const StoresLoading());
    final result = await getStores();
    result.fold(
      (failure) => emit(StoresError(failure.message)),
      (stores) => emit(StoresLoaded(stores)),
    );
  }
}
