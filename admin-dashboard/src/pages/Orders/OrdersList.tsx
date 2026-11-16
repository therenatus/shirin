import React, { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Search, Eye, Volume2, VolumeX, ChevronLeft, ChevronRight } from 'lucide-react';
import Header from '../../components/layout/Header';
import { Order, OrderStatus, Store } from '../../types';
import { ApiOrdersPage, mapOrder, toApiStatus } from '../../services/mappers';
import { paymentLabels, paymentStyles, statusLabels, statusStyles } from '../../constants/orders';
import { useNewOrderAlert } from '../../hooks/useNewOrderAlert';
import { useAuthStore } from '../../store/authStore';
import api from '../../services/api';

const POLL_INTERVAL_MS = 15000;
const PAGE_SIZE = 20;

/** Store filter values besides a store id. */
const ALL_STORES = 'all';
const UNASSIGNED = 'unassigned';

const formatTime = (iso: string) =>
  new Date(iso).toLocaleString('ru-RU', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });

const OrdersList: React.FC = () => {
  const isAdmin = useAuthStore((s) => s.role === 'ADMIN');
  const [orders, setOrders] = useState<Order[]>([]);
  const [filter, setFilter] = useState<string>('all');
  const [storeFilter, setStoreFilter] = useState<string>(ALL_STORES);
  const [stores, setStores] = useState<Store[]>([]);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [pendingCount, setPendingCount] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const { soundEnabled, soundBlocked, toggleSound } = useNewOrderAlert(pendingCount, storeFilter);

  useEffect(() => {
    if (!isAdmin) return;
    api
      .get<Store[]>('/stores')
      .then((res) => setStores(res.data))
      .catch(() => setStores([]));
  }, [isAdmin]);

  const fetchOrders = useCallback(
    async (silent: boolean) => {
      if (!silent) setLoading(true);
      try {
        const response = await api.get<ApiOrdersPage>('/orders/admin/all', {
          params: {
            page,
            limit: PAGE_SIZE,
            status: filter === 'all' ? undefined : toApiStatus(filter as OrderStatus),
            storeId:
              isAdmin && storeFilter !== ALL_STORES && storeFilter !== UNASSIGNED
                ? storeFilter
                : undefined,
            unassigned: isAdmin && storeFilter === UNASSIGNED ? true : undefined,
          },
        });
        setOrders(response.data.data.map(mapOrder));
        setTotalPages(Math.max(1, response.data.meta.totalPages));
        setPendingCount(response.data.meta.pendingCount);
        setError('');
      } catch (err: any) {
        setError(
          err?.response?.status === 403
            ? 'Вы не привязаны к точке. Обратитесь к администратору.'
            : 'Не удалось загрузить заказы',
        );
      } finally {
        if (!silent) setLoading(false);
      }
    },
    [page, filter, storeFilter, isAdmin],
  );

  useEffect(() => {
    fetchOrders(false);
    const timer = window.setInterval(() => {
      // Skip polling in background tabs; refresh as soon as the tab is visible
      if (!document.hidden) fetchOrders(true);
    }, POLL_INTERVAL_MS);
    const onVisible = () => {
      if (!document.hidden) fetchOrders(true);
    };
    document.addEventListener('visibilitychange', onVisible);
    return () => {
      window.clearInterval(timer);
      document.removeEventListener('visibilitychange', onVisible);
    };
  }, [fetchOrders]);

  const resetPage = <T,>(setter: (v: T) => void) => (value: T) => {
    setter(value);
    setPage(1);
  };

  const filteredOrders = orders.filter((o) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      o.id.includes(q) ||
      (o.orderNumber ?? '').toLowerCase().includes(q) ||
      (o.userPhone ?? '').includes(search)
    );
  });

  const soundButton = (
    <button
      onClick={toggleSound}
      className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
        soundEnabled && !soundBlocked
          ? 'bg-primary/10 text-primary'
          : soundEnabled
            ? 'bg-yellow-100 text-yellow-800'
            : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
      }`}
      title={
        soundBlocked
          ? 'Нажмите, чтобы браузер разрешил звук'
          : 'Звук при новом заказе'
      }
    >
      {soundEnabled ? <Volume2 size={18} /> : <VolumeX size={18} />}
      <span className="hidden md:inline">
        {soundBlocked ? 'Включить звук' : soundEnabled ? 'Звук включён' : 'Звук'}
      </span>
    </button>
  );

  return (
    <div>
      <Header title="Заказы" actions={soundButton} />
      <div className="p-4 lg:p-8">
        {pendingCount !== null && pendingCount > 0 && (
          <button
            onClick={() => resetPage(setFilter)('pending')}
            className="w-full mb-4 px-4 py-3 rounded-lg bg-yellow-50 border border-yellow-200 text-yellow-800 text-sm font-medium text-left"
          >
            Ожидают подтверждения: {pendingCount}
          </button>
        )}

        <div className="flex flex-wrap items-center gap-3 mb-6">
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
            onChange={(e) => resetPage(setFilter)(e.target.value)}
            className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
          >
            <option value="all">Все статусы</option>
            {Object.entries(statusLabels).map(([key, label]) => (
              <option key={key} value={key}>{label}</option>
            ))}
          </select>
          {isAdmin && (
            <select
              value={storeFilter}
              onChange={(e) => resetPage(setStoreFilter)(e.target.value)}
              className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
            >
              <option value={ALL_STORES}>Все точки</option>
              <option value={UNASSIGNED}>Без точки (назначить)</option>
              {stores.map((s) => (
                <option key={s.id} value={s.id}>{s.name}</option>
              ))}
            </select>
          )}
        </div>

        {error && <p className="text-red-500 text-sm mb-4">{error}</p>}

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-x-auto">
            <table className="w-full text-sm min-w-[720px]">
              <thead>
                <tr className="bg-gray-50 text-left text-gray-500">
                  <th className="px-4 py-3 font-medium">Заказ</th>
                  <th className="px-4 py-3 font-medium">Товары</th>
                  <th className="px-4 py-3 font-medium">Сумма</th>
                  <th className="px-4 py-3 font-medium">Статус</th>
                  <th className="px-4 py-3 font-medium">Точка / адрес</th>
                  <th className="px-4 py-3 font-medium">Создан</th>
                  <th className="px-4 py-3 font-medium" aria-label="Действия" />
                </tr>
              </thead>
              <tbody>
                {filteredOrders.map((order) => (
                  <tr
                    key={order.id}
                    className={`border-t border-gray-50 hover:bg-gray-50/50 ${
                      order.status === 'pending' ? 'bg-yellow-50/40' : ''
                    }`}
                  >
                    <td className="px-4 py-4 font-medium">
                      {order.orderNumber ?? `#${order.id.slice(-4)}`}
                      <p className="text-xs font-normal text-gray-500">
                        {order.deliveryType === 'delivery' ? 'Доставка' : 'Самовывоз'}
                      </p>
                    </td>
                    <td className="px-4 py-4 text-gray-600 max-w-xs truncate">
                      {order.items.map((i) => `${i.name} × ${i.quantity}`).join(', ')}
                    </td>
                    <td className="px-4 py-4 font-medium whitespace-nowrap">
                      {order.totalSum.toLocaleString()} сом
                    </td>
                    <td className="px-4 py-4">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium whitespace-nowrap ${statusStyles[order.status]}`}>
                        {statusLabels[order.status]}
                      </span>
                      {(order.paymentStatus === 'PENDING' || order.paymentStatus === 'REFUND_PENDING') && (
                        <span className={`mt-1 block w-fit px-2 py-0.5 rounded-full text-xs whitespace-nowrap ${paymentStyles[order.paymentStatus]}`}>
                          {paymentLabels[order.paymentStatus]}
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-4 text-xs">
                      {order.store ? (
                        <span className="text-gray-700">{order.store.name}</span>
                      ) : (
                        <span className="text-orange-600 font-medium">Точка не назначена</span>
                      )}
                      {order.address && <p className="text-gray-500">{order.address}</p>}
                    </td>
                    <td className="px-4 py-4 text-gray-500 whitespace-nowrap">
                      {formatTime(order.createdAt)}
                    </td>
                    <td className="px-4 py-4">
                      <Link
                        to={`/orders/${order.id}`}
                        className="p-3 text-gray-500 hover:text-primary hover:bg-primary/5 rounded-lg inline-flex"
                        aria-label="Открыть заказ"
                      >
                        <Eye size={18} />
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

        {totalPages > 1 && (
          <div className="flex items-center justify-center gap-3 mt-6 text-sm">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="p-2 rounded-lg border border-gray-200 disabled:opacity-40"
              aria-label="Предыдущая страница"
            >
              <ChevronLeft size={18} />
            </button>
            <span className="text-gray-600">
              {page} из {totalPages}
            </span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="p-2 rounded-lg border border-gray-200 disabled:opacity-40"
              aria-label="Следующая страница"
            >
              <ChevronRight size={18} />
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default OrdersList;
