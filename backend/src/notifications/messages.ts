import { OrderStatus } from '@prisma/client';
import type { NotifyInput } from './notifications.service';

/** All customer-facing notification texts in one place. */

interface OrderLike {
  id: string;
  orderNumber: string;
  deliveryType: string;
  pointsEarned: number;
  store?: { name: string } | null;
}

const withOrder = (o: OrderLike, title: string, body: string): NotifyInput => ({
  title,
  body,
  type: 'order_status',
  data: { orderId: o.id, orderNumber: o.orderNumber },
});

/** Text for a status change, or null when the customer needn't be told. */
export function orderStatusMessage(
  o: OrderLike,
  status: OrderStatus,
): NotifyInput | null {
  const n = o.orderNumber;
  const pickup = o.deliveryType !== 'delivery';
  switch (status) {
    case OrderStatus.CONFIRMED:
      return withOrder(
        o,
        `Заказ ${n} принят`,
        'Мы начали работу над вашим заказом.',
      );
    case OrderStatus.READY:
      // Delivery orders get a message when the courier leaves instead
      return pickup
        ? withOrder(
            o,
            `Заказ ${n} готов`,
            o.store ? `Ждём вас в «${o.store.name}».` : 'Можно забирать.',
          )
        : null;
    case OrderStatus.DELIVERING:
      return withOrder(o, `Заказ ${n} в пути`, 'Курьер уже везёт ваш заказ.');
    case OrderStatus.DELIVERED:
      return withOrder(
        o,
        'Спасибо за заказ!',
        o.pointsEarned > 0
          ? `Начислили ${o.pointsEarned} баллов кешбэком.`
          : 'Будем рады видеть вас снова.',
      );
    case OrderStatus.CANCELLED:
      return withOrder(
        o,
        `Заказ ${n} отменён`,
        'Если были списаны баллы, они вернулись на ваш счёт.',
      );
    default:
      return null;
  }
}

export const paymentConfirmedMessage = (o: OrderLike) => ({
  ...withOrder(
    o,
    'Предоплата получена',
    `Начинаем готовить заказ ${o.orderNumber}.`,
  ),
  type: 'payment' as const,
});

export const paymentExpiredMessage = (o: OrderLike) => ({
  ...withOrder(
    o,
    `Заказ ${o.orderNumber} отменён`,
    'Предоплата не поступила вовремя. Вы можете оформить заказ заново.',
  ),
  type: 'payment' as const,
});

export const paymentRefundedMessage = (o: OrderLike) => ({
  ...withOrder(
    o,
    'Предоплата возвращена',
    `Деньги за заказ ${o.orderNumber} вернули.`,
  ),
  type: 'payment' as const,
});

export const pointsEarnedMessage = (
  points: number,
  balance: number,
): NotifyInput => ({
  title: `+${points} баллов`,
  body: `Кешбэк за покупку. Теперь на счёте ${balance}.`,
  type: 'loyalty',
});

export const pointsSpentMessage = (
  points: number,
  balance: number,
): NotifyInput => ({
  title: `Списано ${points} баллов`,
  body: `Оплата покупки баллами. Осталось ${balance}.`,
  type: 'loyalty',
});

export const pointsReversedMessage = (
  points: number,
  balance: number,
): NotifyInput => ({
  title: 'Операция с баллами отменена',
  body: `${points > 0 ? 'Начислено' : 'Списано'} ${Math.abs(points)}. Теперь на счёте ${balance}.`,
  type: 'loyalty',
});
