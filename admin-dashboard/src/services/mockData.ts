import { DashboardStats, Order, Product, Category, User, Promotion, Store } from '../types';

const isTestMode = () => localStorage.getItem('admin_token') === 'admin-test-token';

export const getMockDashboardStats = (): DashboardStats => ({
  todaySales: 45800,
  totalOrders: 23,
  activeCustomers: 156,
  averageOrderValue: 1990,
  salesChart: Array.from({ length: 30 }, (_, i) => ({
    date: new Date(Date.now() - (29 - i) * 86400000).toISOString().split('T')[0],
    amount: Math.floor(Math.random() * 30000) + 20000,
  })),
  recentOrders: getMockOrders().slice(0, 5),
});

export const getMockCategories = (): Category[] => [
  { id: 'cat-1', name: 'Торты', nameRu: 'Торты', imageUrl: '' },
  { id: 'cat-2', name: 'Пирожные', nameRu: 'Пирожные', imageUrl: '' },
  { id: 'cat-3', name: 'Выпечка', nameRu: 'Выпечка', imageUrl: '' },
  { id: 'cat-4', name: 'Напитки', nameRu: 'Напитки', imageUrl: '' },
];

export const getMockProducts = (): Product[] => [
  { id: 'p-1', name: 'Наполеон', nameRu: 'Торт Наполеон', descriptionRu: 'Классический торт с кремом', price: 850, categoryId: 'cat-1', category: getMockCategories()[0], isAvailable: true, createdAt: '2024-01-15T10:00:00Z' },
  { id: 'p-2', name: 'Чизкейк', nameRu: 'Чизкейк Нью-Йорк', descriptionRu: 'Нежный сливочный чизкейк', price: 750, categoryId: 'cat-1', category: getMockCategories()[0], isAvailable: true, createdAt: '2024-01-16T10:00:00Z' },
  { id: 'p-3', name: 'Эклеры', nameRu: 'Эклеры (3 шт)', descriptionRu: 'Набор из 3 эклеров', price: 350, categoryId: 'cat-2', category: getMockCategories()[1], isAvailable: true, createdAt: '2024-01-17T10:00:00Z' },
  { id: 'p-4', name: 'Макаруны', nameRu: 'Макаруны (6 шт)', descriptionRu: 'Ассорти макарунов', price: 420, categoryId: 'cat-2', category: getMockCategories()[1], isAvailable: true, createdAt: '2024-01-18T10:00:00Z' },
  { id: 'p-5', name: 'Круассан', nameRu: 'Круассан с шоколадом', descriptionRu: 'Свежий круассан', price: 180, categoryId: 'cat-3', category: getMockCategories()[2], isAvailable: false, createdAt: '2024-01-19T10:00:00Z' },
  { id: 'p-6', name: 'Латте', nameRu: 'Латте', descriptionRu: 'Кофе латте', price: 200, categoryId: 'cat-4', category: getMockCategories()[3], isAvailable: true, createdAt: '2024-01-20T10:00:00Z' },
];

export const getMockOrders = (): Order[] => [
  { id: 'ord-1', userId: 'u-1', status: 'delivered', items: [{ id: 'oi-1', productId: 'p-1', name: 'Торт Наполеон', price: 850, quantity: 1 }], totalSum: 850, address: 'ул. Киевская, 120', createdAt: new Date(Date.now() - 86400000 * 3).toISOString(), updatedAt: new Date(Date.now() - 86400000 * 2).toISOString() },
  { id: 'ord-2', userId: 'u-2', status: 'preparing', items: [{ id: 'oi-2', productId: 'p-2', name: 'Чизкейк Нью-Йорк', price: 750, quantity: 1 }, { id: 'oi-3', productId: 'p-3', name: 'Эклеры', price: 350, quantity: 2 }], totalSum: 1450, address: 'ул. Московская, 55', createdAt: new Date(Date.now() - 7200000).toISOString(), updatedAt: new Date(Date.now() - 3600000).toISOString() },
  { id: 'ord-3', userId: 'u-3', status: 'pending', items: [{ id: 'oi-4', productId: 'p-4', name: 'Макаруны', price: 420, quantity: 1 }], totalSum: 420, createdAt: new Date(Date.now() - 1800000).toISOString(), updatedAt: new Date(Date.now() - 1800000).toISOString() },
  { id: 'ord-4', userId: 'u-1', status: 'confirmed', items: [{ id: 'oi-5', productId: 'p-5', name: 'Круассан', price: 180, quantity: 3 }], totalSum: 540, address: 'ул. Ахунбаева, 85', createdAt: new Date(Date.now() - 3600000).toISOString(), updatedAt: new Date(Date.now() - 1800000).toISOString() },
  { id: 'ord-5', userId: 'u-4', status: 'ready', items: [{ id: 'oi-6', productId: 'p-1', name: 'Торт Наполеон', price: 850, quantity: 2 }], totalSum: 1700, address: 'пр. Жибек Жолу, 200', createdAt: new Date(Date.now() - 5400000).toISOString(), updatedAt: new Date(Date.now() - 900000).toISOString() },
];

export const getMockUsers = (): User[] => [
  { id: 'u-1', phone: '+996555111222', firstName: 'Алия', lastName: 'Каримова', loyaltyPoints: 320, role: 'USER', createdAt: '2024-01-10T08:00:00Z' },
  { id: 'u-2', phone: '+996555333444', firstName: 'Бакыт', lastName: 'Асанов', loyaltyPoints: 150, role: 'USER', createdAt: '2024-01-12T10:00:00Z' },
  { id: 'u-3', phone: '+996555555666', firstName: 'Гулзат', lastName: 'Токтоева', loyaltyPoints: 500, role: 'USER', createdAt: '2024-01-15T12:00:00Z' },
  { id: 'u-4', phone: '+996555777888', firstName: 'Данияр', lastName: 'Жумабеков', loyaltyPoints: 80, role: 'USER', createdAt: '2024-02-01T09:00:00Z' },
  { id: 'u-admin', phone: '+996999999999', firstName: 'Админ', lastName: 'Ширин', loyaltyPoints: 0, role: 'ADMIN', createdAt: '2024-01-01T00:00:00Z' },
];

export const getMockPromotions = (): Promotion[] => [
  { id: 'promo-1', title: 'Скидка 20%', titleRu: 'Скидка 20% на торты', description: '', descriptionRu: 'Только до конца месяца! Скидка 20% на все торты при заказе от 1500 сом.', startDate: new Date(Date.now() - 86400000 * 5).toISOString(), endDate: new Date(Date.now() + 86400000 * 25).toISOString(), isActive: true, createdAt: '2024-01-20T10:00:00Z' },
  { id: 'promo-2', title: '2+1 эклеры', titleRu: '2+1 на эклеры', description: '', descriptionRu: 'Купите 2 набора эклеров и получите третий в подарок!', startDate: new Date(Date.now() - 86400000 * 2).toISOString(), endDate: new Date(Date.now() + 86400000 * 14).toISOString(), isActive: true, createdAt: '2024-01-22T10:00:00Z' },
  { id: 'promo-3', title: 'День рождения', titleRu: 'День рождения с Ширин', description: '', descriptionRu: 'Закажите торт на день рождения и получите набор макарунов в подарок.', startDate: new Date(Date.now() - 86400000 * 30).toISOString(), endDate: new Date(Date.now() + 86400000 * 60).toISOString(), isActive: true, createdAt: '2024-01-05T10:00:00Z' },
];

export const getMockStores = (): Store[] => [
  { id: 'store-1', name: 'Ширин — Центр', address: 'ул. Киевская, 120', phone: '+996 312 123 456', lat: 42.8746, lng: 74.5698, workingHours: '08:00 - 21:00' },
  { id: 'store-2', name: 'Ширин — Юг', address: 'ул. Ахунбаева, 85', phone: '+996 312 654 321', lat: 42.856, lng: 74.582, workingHours: '09:00 - 22:00' },
  { id: 'store-3', name: 'Ширин — Восток', address: 'пр. Жибек Жолу, 200', phone: '+996 312 789 012', lat: 42.878, lng: 74.61, workingHours: '08:00 - 20:00' },
];

export { isTestMode };
