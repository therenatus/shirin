import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Search, Eye } from 'lucide-react';
import Header from '../../components/layout/Header';
import { Order, OrderStatus } from '../../types';
import { ApiOrder, mapOrder, toApiStatus } from '../../services/mappers';
import api from '../../services/api';

const statusLabels: Record<OrderStatus, string> = {
  pending: 'Ожидает',
  confirmed: 'Подтверждён',
  preparing: 'Готовится',
  ready: 'Готов',
  delivering: 'В пути',
  delivered: 'Доставлен',
  cancelled: 'Отменён',
};

const statusStyles: Record<OrderStatus, string> = {
  pending: 'bg-yellow-100 text-yellow-700',
  confirmed: 'bg-blue-100 text-blue-700',
  preparing: 'bg-purple-100 text-purple-700',
  ready: 'bg-teal-100 text-teal-700',
  delivering: 'bg-indigo-100 text-indigo-700',
  delivered: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-700',
};

const OrdersList: React.FC = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [filter, setFilter] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchOrders = async () => {
      setLoading(true);
      setError('');
      try {
        const response = await api.get<{ data: ApiOrder[] }>('/orders/admin/all', {
          params: {
            limit: 100,
            status: filter === 'all' ? undefined : toApiStatus(filter as OrderStatus),
          },
        });
        setOrders(response.data.data.map(mapOrder));
      } catch {
        setError('Не удалось загрузить заказы');
      } finally {
        setLoading(false);
      }
    };
    fetchOrders();
  }, [filter]);

  const filteredOrders = orders.filter((o) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      o.id.includes(q) ||
      (o.orderNumber ?? '').toLowerCase().includes(q) ||
      (o.userPhone ?? '').includes(search)
    );
  });

  return (
    <div>
      <Header title="Заказы" />
      <div className="p-8">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
              <input
                type="text"
                placeholder="Номер заказа или телефон"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-10 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary w-56"
              />
            </div>
            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
              className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
            >
              <option value="all">Все статусы</option>
              {Object.entries(statusLabels).map(([key, label]) => (
                <option key={key} value={key}>{label}</option>
              ))}
            </select>
          </div>
        </div>

        {error && <p className="text-red-500 text-sm mb-4">{error}</p>}

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-50 text-left text-gray-500">
                  <th className="px-6 py-3 font-medium">ID</th>
                  <th className="px-6 py-3 font-medium">Товары</th>
                  <th className="px-6 py-3 font-medium">Сумма</th>
                  <th className="px-6 py-3 font-medium">Статус</th>
                  <th className="px-6 py-3 font-medium">Адрес</th>
                  <th className="px-6 py-3 font-medium">Дата</th>
                  <th className="px-6 py-3 font-medium">Действия</th>
                </tr>
              </thead>
              <tbody>
                {filteredOrders.map((order) => (
                  <tr key={order.id} className="border-t border-gray-50 hover:bg-gray-50/50">
                    <td className="px-6 py-4 font-medium">{order.orderNumber ?? `#${order.id.slice(-4)}`}</td>
                    <td className="px-6 py-4 text-gray-600 max-w-xs truncate">
                      {order.items.map((i) => i.name).join(', ')}
                    </td>
                    <td className="px-6 py-4 font-medium">{order.totalSum.toLocaleString()} сом</td>
                    <td className="px-6 py-4">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${statusStyles[order.status]}`}>
                        {statusLabels[order.status]}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-gray-500 text-xs">{order.address || '-'}</td>
                    <td className="px-6 py-4 text-gray-500">
                      {new Date(order.createdAt).toLocaleDateString('ru-RU')}
                    </td>
                    <td className="px-6 py-4">
                      <Link
                        to={`/orders/${order.id}`}
                        className="p-2 text-gray-500 hover:text-primary hover:bg-primary/5 rounded-lg inline-flex"
                      >
                        <Eye size={16} />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filteredOrders.length === 0 && (
              <div className="text-center py-12 text-gray-500">Заказы не найдены</div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default OrdersList;
