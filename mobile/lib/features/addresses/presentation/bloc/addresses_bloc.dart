import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/create_address_params.dart';
import '../../domain/usecases/get_addresses.dart';
import '../../domain/usecases/create_address.dart';
import '../../domain/usecases/update_address.dart';
import '../../domain/usecases/delete_address.dart';
import '../../domain/usecases/set_default_address.dart';

// Events
abstract class AddressesEvent extends Equatable {
  const AddressesEvent();
  @override
  List<Object?> get props => [];
}

class LoadAddresses extends AddressesEvent {
  const LoadAddresses();
}

class AddAddress extends AddressesEvent {
  final CreateAddressParams params;
  const AddAddress(this.params);
  @override
  List<Object?> get props => [params];
}

class EditAddress extends AddressesEvent {
  final String id;
  final UpdateAddressParams params;
  const EditAddress(this.id, this.params);
  @override
  List<Object?> get props => [id, params];
}

class RemoveAddress extends AddressesEvent {
  final String id;
  const RemoveAddress(this.id);
  @override
  List<Object?> get props => [id];
}

class SetDefault extends AddressesEvent {
  final String id;
  const SetDefault(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class AddressesState extends Equatable {
  const AddressesState();
  @override
  List<Object?> get props => [];
}

class AddressesInitial extends AddressesState {
  const AddressesInitial();
}

class AddressesLoading extends AddressesState {
  const AddressesLoading();
}

class AddressesLoaded extends AddressesState {
  final List<Address> addresses;
  const AddressesLoaded(this.addresses);

  Address? get defaultAddress {
    try {
      return addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  @override
  List<Object?> get props => [addresses];
}

class AddressesActionSuccess extends AddressesState {
  final List<Address> addresses;
  final String message;
  const AddressesActionSuccess(this.addresses, this.message);
  @override
  List<Object?> get props => [addresses, message];
}

class AddressesError extends AddressesState {
  final String message;
  const AddressesError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AddressesBloc extends Bloc<AddressesEvent, AddressesState> {
  final GetAddresses getAddresses;
  final CreateAddress createAddress;
  final UpdateAddress updateAddress;
  final DeleteAddress deleteAddress;
  final SetDefaultAddress setDefaultAddress;

  List<Address> _addresses = [];

  AddressesBloc({
    required this.getAddresses,
    required this.createAddress,
    required this.updateAddress,
    required this.deleteAddress,
    required this.setDefaultAddress,
  }) : super(const AddressesInitial()) {
    on<LoadAddresses>(_onLoadAddresses);
    on<AddAddress>(_onAddAddress);
    on<EditAddress>(_onEditAddress);
    on<RemoveAddress>(_onRemoveAddress);
    on<SetDefault>(_onSetDefault);
  }

  Future<void> _onLoadAddresses(
    LoadAddresses event,
    Emitter<AddressesState> emit,
  ) async {
    emit(const AddressesLoading());
    final result = await getAddresses();
    result.fold(
      (failure) => emit(AddressesError(failure.message)),
      (addresses) {
        _addresses = List<Address>.from(addresses);
        emit(AddressesLoaded(_addresses));
      },
    );
  }

  Future<void> _onAddAddress(
    AddAddress event,
    Emitter<AddressesState> emit,
  ) async {
    emit(const AddressesLoading());
    final result = await createAddress(event.params);
    result.fold(
      (failure) => emit(AddressesError(failure.message)),
      (address) {
        _addresses = [..._addresses, address];
        emit(AddressesActionSuccess(_addresses, 'Адрес добавлен'));
      },
    );
  }

  Future<void> _onEditAddress(
    EditAddress event,
    Emitter<AddressesState> emit,
  ) async {
    emit(const AddressesLoading());
    final result = await updateAddress(event.id, event.params);
    result.fold(
      (failure) => emit(AddressesError(failure.message)),
      (updatedAddress) {
        _addresses = _addresses.map((a) {
          return a.id == event.id ? updatedAddress : a;
        }).toList();
        emit(AddressesActionSuccess(_addresses, 'Адрес обновлён'));
      },
    );
  }

  Future<void> _onRemoveAddress(
    RemoveAddress event,
    Emitter<AddressesState> emit,
  ) async {
    emit(const AddressesLoading());
    final result = await deleteAddress(event.id);
    result.fold(
      (failure) => emit(AddressesError(failure.message)),
      (_) {
        _addresses = _addresses.where((a) => a.id != event.id).toList();
        emit(AddressesActionSuccess(_addresses, 'Адрес удалён'));
      },
    );
  }

  Future<void> _onSetDefault(
    SetDefault event,
    Emitter<AddressesState> emit,
  ) async {
    emit(const AddressesLoading());
    final result = await setDefaultAddress(event.id);
    result.fold(
      (failure) => emit(AddressesError(failure.message)),
      (defaultAddress) {
        _addresses = _addresses.map((a) {
          if (a.id == event.id) {
            return defaultAddress;
          }
          return Address(
            id: a.id,
            name: a.name,
            street: a.street,
            apartment: a.apartment,
            entrance: a.entrance,
            floor: a.floor,
            intercom: a.intercom,
            latitude: a.latitude,
            longitude: a.longitude,
            isDefault: false,
          );
        }).toList();
        emit(AddressesActionSuccess(_addresses, 'Адрес по умолчанию изменён'));
      },
    );
  }
}
