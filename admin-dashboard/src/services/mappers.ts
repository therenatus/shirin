import { Order, OrderStatus, Store } from '../types';

/** Order shape returned by the backend (`formatOrder` in orders.service.ts). */
export interface ApiOrder {
  id: string;
  orderNumber: string;
  status: string;
  deliveryType: 'delivery' | 'pickup';
  total: number;
  createdAt: string;
  completedAt?: string | null;
  items: {
    id: string;
    quantity: number;
    price: number;
    product: { id: string; name: string; nameRu?: string | null; images?: string[] };
  }[];
  address: { street: string; apartment?: string | null } | null;
  store: { name: string; address: string } | null;
  user?: { id: string; phone: string; firstName?: string | null; lastName?: string | null };
}

export const mapOrder = (o: ApiOrder): Order => ({
  id: o.id,
  orderNumber: o.orderNumber,
  userId: o.user?.id ?? '',
  userPhone: o.user?.phone,
  status: o.status.toLowerCase() as OrderStatus,
  deliveryType: o.deliveryType,
  items: o.items.map((i) => ({
    id: i.id,
    productId: i.product.id,
    name: i.product.nameRu || i.product.name,
    price: i.price,
    quantity: i.quantity,
    imageUrl: i.product.images?.[0],
  })),
  totalSum: o.total,
  address: o.address
    ? [o.address.street, o.address.apartment && `кв. ${o.address.apartment}`]
        .filter(Boolean)
        .join(', ')
    : o.store
      ? `Самовывоз: ${o.store.name}`
      : undefined,
  createdAt: o.createdAt,
  updatedAt: o.completedAt ?? o.createdAt,
});

export const toApiStatus = (status: OrderStatus) => status.toUpperCase();

/** Store as returned by / sent to the backend stores endpoints. */
export type StoreInput = Omit<Store, 'id'>;
