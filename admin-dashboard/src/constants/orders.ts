import { OrderStatus, PaymentStatus, StaffRole } from '../types';

export const statusLabels: Record<OrderStatus, string> = {
  pending: 'Ожидает',
  confirmed: 'Подтверждён',
  preparing: 'Готовится',
  ready: 'Готов',
  delivering: 'В пути',
  delivered: 'Выполнен',
  cancelled: 'Отменён',
};

const statusActions: Record<OrderStatus, string> = {
  pending: 'Вернуть в ожидание',
  confirmed: 'Подтвердить',
  preparing: 'Начать готовить',
  ready: 'Готов',
  delivering: 'Передать курьеру',
  delivered: 'Выдан клиенту',
  cancelled: 'Отменить',
};

/** Button text for moving an order to the given status. */
export const statusAction = (
  status: OrderStatus,
  deliveryType?: 'delivery' | 'pickup',
) =>
  status === 'delivered' && deliveryType === 'delivery'
    ? 'Доставлен'
    : statusActions[status];

export const statusStyles: Record<OrderStatus, string> = {
  pending: 'bg-yellow-100 text-yellow-700',
  confirmed: 'bg-blue-100 text-blue-700',
  preparing: 'bg-purple-100 text-purple-700',
  ready: 'bg-teal-100 text-teal-700',
  delivering: 'bg-indigo-100 text-indigo-700',
  delivered: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-700',
};

export const statusFlow = (deliveryType?: 'delivery' | 'pickup'): OrderStatus[] =>
  deliveryType === 'delivery'
    ? ['pending', 'confirmed', 'preparing', 'ready', 'delivering', 'delivered']
    : ['pending', 'confirmed', 'preparing', 'ready', 'delivered'];

export const paymentLabels: Record<PaymentStatus, string> = {
  NOT_REQUIRED: 'Без предоплаты',
  PENDING: 'Ждёт предоплату',
  PAID: 'Предоплата получена',
  REFUND_PENDING: 'Нужно вернуть предоплату',
  REFUNDED: 'Предоплата возвращена',
};

export const paymentStyles: Record<PaymentStatus, string> = {
  NOT_REQUIRED: 'bg-gray-100 text-gray-600',
  PENDING: 'bg-orange-100 text-orange-700',
  PAID: 'bg-green-100 text-green-700',
  REFUND_PENDING: 'bg-red-100 text-red-700',
  REFUNDED: 'bg-gray-100 text-gray-600',
};

export const roleLabels: Record<StaffRole | 'CLIENT', string> = {
  ADMIN: 'Администратор',
  STORE_STAFF: 'Сотрудник точки',
  SUPPORT: 'Поддержка',
  CLIENT: 'Клиент',
};
