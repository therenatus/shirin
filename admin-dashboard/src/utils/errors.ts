/** Russian text for backend messages staff can run into; `$1` is a number. */
const TRANSLATIONS: [RegExp, string][] = [
  [/^Not enough loyalty points/, 'Недостаточно баллов'],
  [/^This receipt has already been processed/, 'Этот чек уже проведён'],
  [/^Operation is already cancelled/, 'Операция уже отменена'],
  [/^This operation cannot be cancelled/, 'Эту операцию нельзя отменить'],
  [/^QR code has expired/, 'QR-код устарел — попросите клиента обновить его в приложении'],
  [/^To spend points scan the live QR/, 'Для списания отсканируйте QR-код с экрана приложения клиента'],
  [/^Customer not found/, 'Клиент не найден'],
  [/^Daily cashback limit of (\d+)/, 'Достигнут дневной лимит начисления: $1 баллов'],
  [/^At most (\d+) points/, 'По этому чеку можно списать не больше $1 баллов'],
  [/^Receipt amount exceeds the limit of (\d+)/, 'Сумма чека больше лимита $1 сом'],
  [/^Receipt amount is too small/, 'Сумма слишком мала для начисления'],
  [/^You cannot (credit|spend)/, 'Нельзя проводить операции со своей картой'],
  [/^Store is required/, 'Выберите точку'],
  [/^Employee is not assigned to a store/, 'Вы не привязаны к точке — обратитесь к администратору'],
  [/^Punch card is not complete/, 'Карта ещё не заполнена'],
  [/^Order belongs to another store/, 'Заказ относится к другой точке'],
  [/^Assign a store/, 'Сначала назначьте точку'],
  [/^Cannot change status/, 'Такой переход статуса недоступен'],
  [/^Order status was changed concurrently/, 'Статус уже изменил кто-то другой — обновите страницу'],
  [/^You cannot remove your own admin role/, 'Нельзя снять с себя роль администратора'],
  [/^Confirm the prepayment/, 'Сначала подтвердите предоплату'],
  [/^The order is not waiting for payment/, 'Заказ не ожидает оплаты — обновите страницу'],
  [/^The order has no refund pending/, 'По заказу нет возврата'],
  [/^Enter a whole number/, 'Введите целое число'],
  [/^Value must be between (\d+)/, 'Значение вне допустимого диапазона'],
  [/^Enter a link/, 'Ссылка должна начинаться с http:// или https://'],
];

const translate = (message: string) => {
  for (const [pattern, text] of TRANSLATIONS) {
    const match = message.match(pattern);
    if (match) return text.replace('$1', match[1] ?? '');
  }
  return message;
};

/** Message from a NestJS error response (in Russian when known), or the fallback. */
export const apiErrorMessage = (err: any, fallback: string): string => {
  if (!err?.response) return 'Нет связи с сервером';
  const message = err.response.data?.message;
  if (Array.isArray(message)) return message.map(translate).join(', ');
  return message ? translate(message) : fallback;
};
