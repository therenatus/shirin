import { Order, OrderStatus, PaymentStatus, Store } from '../types';

/** Order shape returned by the backend (`formatOrder` in orders.service.ts). */
export interface ApiOrder {
  id: string;
  orderNumber: string;
  status: string;
  deliveryType: 'delivery' | 'pickup';
  total: number;
  comment?: string | null;
  deliveryTime?: string | null;
  nextStatuses?: string[];
  paymentStatus?: PaymentStatus;
  prepaymentAmount?: number;
  paymentDueAt?: string | null;
  createdAt: string;
  updatedAt?: string;
  completedAt?: string | null;
  items: {
    id: string;
    quantity: number;
    price: number;
    inscription?: string | null;
    wishes?: string | null;
    referencePhotoUrl?: string | null;
    product: { id: string; name: string; nameRu?: string | null; images?: string[] };
  }[];
  address: { street: string; apartment?: string | null } | null;
  store: { id: string; name: string; address: string } | null;
  user?: { id: string; phone: string; firstName?: string | null; lastName?: string | null };
}

export const mapOrder = (o: ApiOrder): Order => ({
  id: o.id,
  orderNumber: o.orderNumber,
  userId: o.user?.id ?? '',
  userPhone: o.user?.phone,
  customerName:
    [o.user?.firstName, o.user?.lastName].filter(Boolean).join(' ') || undefined,
  status: o.status.toLowerCase() as OrderStatus,
  nextStatuses: (o.nextStatuses ?? []).map((s) => s.toLowerCase() as OrderStatus),
  deliveryType: o.deliveryType,
  store: o.store,
  comment: o.comment,
  deliveryTime: o.deliveryTime,
  items: o.items.map((i) => ({
    id: i.id,
    productId: i.product.id,
    name: i.product.nameRu || i.product.name,
    price: i.price,
    quantity: i.quantity,
    imageUrl: i.product.images?.[0],
    inscription: i.inscription,
    wishes: i.wishes,
    referencePhotoUrl: i.referencePhotoUrl,
  })),
  paymentStatus: o.paymentStatus ?? 'NOT_REQUIRED',
  prepaymentAmount: o.prepaymentAmount ?? 0,
  paymentDueAt: o.paymentDueAt,
  totalSum: o.total,
  address: o.address
    ? [o.address.street, o.address.apartment && `кв. ${o.address.apartment}`]
        .filter(Boolean)
        .join(', ')
    : undefined,
  createdAt: o.createdAt,
  updatedAt: o.updatedAt ?? o.completedAt ?? o.createdAt,
});

/** Paginated list returned by `GET /orders/admin/all`. */
export interface ApiOrdersPage {
  data: ApiOrder[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    /** PENDING orders in the caller's scope, ignoring the status filter. */
    pendingCount: number;
  };
}

export const toApiStatus = (status: OrderStatus) => status.toUpperCase();

/** Store as returned by / sent to the backend stores endpoints. */
export type StoreInput = Omit<Store, 'id'>;
