import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/domain/usecases/get_addresses.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../loyalty/domain/usecases/get_loyalty_info.dart';
import '../../../orders/domain/entities/checkout_preview.dart';
import '../../../orders/domain/entities/create_order_params.dart';
import '../../../orders/domain/usecases/create_order.dart';
import '../../../orders/domain/usecases/preview_order.dart';
import '../../../stores/domain/entities/store.dart';
import '../../../stores/domain/usecases/get_stores.dart';
import 'checkout_errors.dart';

class CheckoutState extends Equatable {
  final List<CartItem> items;
  final bool loading;
  final DeliveryType deliveryType;
  final List<Store> stores;
  final Store? store;
  final List<Address> addresses;
  final Address? address;
  final DateTime? dateTime;
  final String comment;
  final bool usePoints;
  final int pointsBalance;
  final CheckoutPreview? preview;
  final String? previewError;
  final bool submitting;
  final String? submitError;

  /// Set once the order is placed; the page then opens it.
  final String? createdOrderId;

  const CheckoutState({
    required this.items,
    this.loading = true,
    this.deliveryType = DeliveryType.pickup,
    this.stores = const [],
    this.store,
    this.addresses = const [],
    this.address,
    this.dateTime,
    this.comment = '',
    this.usePoints = false,
    this.pointsBalance = 0,
    this.preview,
    this.previewError,
    this.submitting = false,
    this.submitError,
    this.createdOrderId,
  });

  bool get hasPreorder => items.any((i) => i.product.isPreorder);

  /// Earliest time made-to-order items can be ready, by the cart's lead
  /// times; the server re-checks it.
  DateTime? get localEarliestTime {
    if (!hasPreorder) return null;
    final hours = items
        .where((i) => i.product.isPreorder)
        .map((i) => i.product.leadTimeHours)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return DateTime.now().add(Duration(hours: hours));
  }

  /// What still has to be filled in before the order can be placed.
  String? get missing {
    if (deliveryType == DeliveryType.pickup && store == null) {
      return 'Выберите точку самовывоза';
    }
    if (deliveryType == DeliveryType.delivery && address == null) {
      return 'Выберите адрес доставки';
    }
    if (hasPreorder && dateTime == null) {
      return 'Выберите дату и время для торта на заказ';
    }
    return null;
  }

  CheckoutState copyWith({
    bool? loading,
    DeliveryType? deliveryType,
    List<Store>? stores,
    Store? store,
    List<Address>? addresses,
    Address? address,
    DateTime? dateTime,
    String? comment,
    bool? usePoints,
    int? pointsBalance,
    CheckoutPreview? preview,
    String? previewError,
    bool clearPreviewError = false,
    bool? submitting,
    String? submitError,
    bool clearSubmitError = false,
    String? createdOrderId,
  }) {
    return CheckoutState(
      items: items,
      loading: loading ?? this.loading,
      deliveryType: deliveryType ?? this.deliveryType,
      stores: stores ?? this.stores,
      store: store ?? this.store,
      addresses: addresses ?? this.addresses,
      address: address ?? this.address,
      dateTime: dateTime ?? this.dateTime,
      comment: comment ?? this.comment,
      usePoints: usePoints ?? this.usePoints,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      preview: preview ?? this.preview,
      previewError: clearPreviewError ? null : previewError ?? this.previewError,
      submitting: submitting ?? this.submitting,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
      createdOrderId: createdOrderId ?? this.createdOrderId,
    );
  }

  @override
  List<Object?> get props => [
        items,
        loading,
        deliveryType,
        stores,
        store,
        addresses,
        address,
        dateTime,
        comment,
        usePoints,
        pointsBalance,
        preview,
        previewError,
        submitting,
        submitError,
        createdOrderId,
      ];
}

/// Checkout: where and when, points, a server-calculated total, and placing
/// the order. Every change re-asks the server for the total, so the screen
/// always shows what will actually be charged.
class CheckoutCubit extends Cubit<CheckoutState> {
  final PreviewOrder previewOrder;
  final CreateOrder createOrder;
  final GetStores getStores;
  final GetAddresses getAddresses;
  final GetLoyaltyInfo getLoyaltyInfo;

  /// Ignores preview answers that arrive after a newer request was sent.
  int _previewSeq = 0;

  CheckoutCubit({
    required List<CartItem> items,
    required this.previewOrder,
    required this.createOrder,
    required this.getStores,
    required this.getAddresses,
    required this.getLoyaltyInfo,
  }) : super(CheckoutState(items: items));

  Future<void> init() async {
    // Started together, awaited one by one: three independent requests
    final storesFuture = getStores();
    final addressesFuture = getAddresses();
    final loyaltyFuture = getLoyaltyInfo();
    final stores = (await storesFuture).fold((_) => <Store>[], (v) => v);
    final addresses = (await addressesFuture).fold((_) => <Address>[], (v) => v);
    final balance = (await loyaltyFuture).fold((_) => 0, (v) => v.points);
    if (isClosed) return;

    Address? defaultAddress;
    for (final a in addresses) {
      if (a.isDefault) defaultAddress = a;
    }

    emit(state.copyWith(
      loading: false,
      stores: stores,
      addresses: addresses,
      address: defaultAddress ?? (addresses.isNotEmpty ? addresses.first : null),
      store: stores.length == 1 ? stores.first : null,
      pointsBalance: balance,
    ));
    await refreshPreview();
  }

  Future<void> reloadAddresses() async {
    final result = await getAddresses();
    if (isClosed) return;
    result.fold((_) {}, (addresses) {
      final keep = addresses.where((a) => a.id == state.address?.id);
      emit(state.copyWith(
        addresses: addresses,
        address: keep.isNotEmpty
            ? keep.first
            : (addresses.isNotEmpty ? addresses.last : null),
      ));
    });
    await refreshPreview();
  }

  void setDeliveryType(DeliveryType type) {
    emit(state.copyWith(deliveryType: type));
    refreshPreview();
  }

  void selectStore(Store store) {
    emit(state.copyWith(store: store));
    refreshPreview();
  }

  void selectAddress(Address address) {
    emit(state.copyWith(address: address));
    refreshPreview();
  }

  void setDateTime(DateTime value) {
    emit(state.copyWith(dateTime: value));
    refreshPreview();
  }

  void setComment(String value) => emit(state.copyWith(comment: value));

  void setUsePoints(bool value) {
    emit(state.copyWith(usePoints: value));
    refreshPreview();
  }

  CreateOrderParams _params({bool forPreview = false}) {
    var time = state.dateTime;
    // Lets the preview show totals before a date is chosen
    if (forPreview && time == null && state.hasPreorder) {
      time = state.localEarliestTime!.add(const Duration(minutes: 10));
    }
    return CreateOrderParams(
      items: state.items
          .map((i) => CreateOrderItemParams(
                productId: i.product.id,
                quantity: i.quantity,
                inscription: i.inscription,
                wishes: i.wishes,
                referencePhotoUrl: i.referencePhotoUrl,
              ))
          .toList(),
      deliveryType: state.deliveryType,
      storeId: state.deliveryType == DeliveryType.pickup ? state.store?.id : null,
      addressId:
          state.deliveryType == DeliveryType.delivery ? state.address?.id : null,
      deliveryTime: time,
      comment: state.comment,
      pointsToUse: state.usePoints && state.pointsBalance > 0
          ? state.pointsBalance
          : null,
    );
  }

  Future<void> refreshPreview() async {
    // The server needs a store or address to calculate delivery
    if ((state.deliveryType == DeliveryType.pickup && state.store == null) ||
        (state.deliveryType == DeliveryType.delivery && state.address == null)) {
      return;
    }
    final seq = ++_previewSeq;
    final result = await previewOrder(_params(forPreview: true));
    if (isClosed || seq != _previewSeq) return;
    result.fold(
      (failure) => emit(state.copyWith(
        previewError: checkoutErrorText(failure.message),
      )),
      (preview) => emit(state.copyWith(preview: preview, clearPreviewError: true)),
    );
  }

  Future<void> submit() async {
    if (state.missing != null || state.submitting) return;
    emit(state.copyWith(submitting: true, clearSubmitError: true));
    final result = await createOrder(_params());
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        submitting: false,
        submitError: checkoutErrorText(failure.message),
      )),
      (order) => emit(state.copyWith(submitting: false, createdOrderId: order.id)),
    );
  }
}
