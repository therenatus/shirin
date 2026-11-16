/// Russian text for server messages a customer can run into at checkout.
String checkoutErrorText(String message) {
  const known = <String, String>{
    'Choose the date and time': 'Выберите дату и время для торта на заказ',
    'Earliest available time': 'Так быстро не успеем: выберите время позже',
    'Time is in the past': 'Выбранное время уже прошло',
    'Orders are accepted up to': 'Заказы принимаются не больше чем на 60 дней вперёд',
    'Store is required': 'Выберите точку самовывоза',
    'Address is required': 'Выберите адрес доставки',
    'Address not found': 'Адрес не найден, выберите другой',
    'Store not found': 'Точка сейчас не работает, выберите другую',
    'Some products are not available':
        'Некоторых товаров уже нет в наличии — уберите их из корзины',
    'Not enough loyalty points': 'Недостаточно баллов',
    'Reference photo not found': 'Фото-образец не найдено, приложите его заново',
    'An inscription is not available': 'Для одного из товаров надпись недоступна',
    'A reference photo is not available':
        'Для одного из товаров фото-образец недоступен',
  };
  for (final entry in known.entries) {
    if (message.contains(entry.key)) return entry.value;
  }
  return message;
}
