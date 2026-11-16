import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';
import Header from '../../components/layout/Header';
import { Order, OrderStatus, Store } from '../../types';
import { ApiOrder, mapOrder, toApiStatus } from '../../services/mappers';
import { statusAction, statusFlow, statusLabels } from '../../constants/orders';
import { useAuthStore } from '../../store/authStore';
import api from '../../services/api';

const errorMessage = (err: any, fallback: string) => {
  const message = err?.response?.data?.message;
  return Array.isArray(message) ? message.join(', ') : message || fallback;
};

const OrderDetails: React.FC = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const isAdmin = useAuthStore((s) => s.role === 'ADMIN');
  const [order, setOrder] = useState<Order | null>(null);
  const [stores, setStores] = useState<Store[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [actionError, setActionError] = useState('');

  useEffect(() => {
    const fetchOrder = async () => {
      try {
        const response = await api.get<ApiOrder>(`/orders/${id}`);
        setOrder(mapOrder(response.data));
      } catch {
        setOrder(null);
      } finally {
        setLoading(false);
      }
    };
    fetchOrder();
  }, [id]);

  useEffect(() => {
    if (!isAdmin) return;
    api
      .get<Store[]>('/stores')
      .then((res) => setStores(res.data))
      .catch(() => setStores([]));
  }, [isAdmin]);

  const applyUpdate = (data: ApiOrder) => {
    // Status endpoints don't return the customer; keep what we already have
    setOrder((prev) => {
      const next = mapOrder(data);
      return prev
        ? {
            ...next,
            userId: prev.userId,
            userPhone: next.userPhone ?? prev.userPhone,
            customerName: next.customerName ?? prev.customerName,
          }
        : next;
    });
  };

  const handleStatusChange = async (newStatus: OrderStatus) => {
    if (!order) return;
    if (
      newStatus === 'cancelled' &&
      !window.confirm(`Отменить заказ ${order.orderNumber ?? ''}? Баллы вернутся клиенту.`)
    ) {
      return;
    }
    setSaving(true);
    setActionError('');
    try {
      const response = await api.patch<ApiOrder>(`/orders/${id}/status`, {
        status: toApiStatus(newStatus),
      });
      applyUpdate(response.data);
    } catch (err: any) {
      setActionError(errorMessage(err, 'Не удалось изменить статус'));
    } finally {
      setSaving(false);
    }
  };

  const handleAssignStore = async (storeId: string) => {
    if (!storeId) return;
    setSaving(true);
    setActionError('');
    try {
      const response = await api.patch<ApiOrder>(`/orders/${id}/store`, { storeId });
      applyUpdate(response.data);
    } catch (err: any) {
      setActionError(errorMessage(err, 'Не удалось назначить точку'));
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div>
        <Header title="Заказ" />
        <div className="p-8 flex justify-center">
          <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
        </div>
      </div>
    );
  }

  if (!order) {
    return (
      <div>
        <Header title="Заказ" />
        <div className="p-8 text-center text-gray-500">Заказ не найден</div>
      </div>
    );
  }

  const flow = statusFlow(order.deliveryType);
  const currentIdx = flow.indexOf(order.status);
  const forward = order.nextStatuses.filter((s) => s !== 'cancelled');
  const canCancel = order.nextStatuses.includes('cancelled');
  const isFinal = order.status === 'delivered' || order.status === 'cancelled';
  const needsStore = !order.store && !isFinal;

  return (
    <div>
      <Header title={`Заказ ${order.orderNumber ?? `#${order.id.slice(-4)}`}`} />
      <div className="p-4 lg:p-8">
        <button
          onClick={() => navigate('/orders')}
          className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-6 text-sm"
        >
          <ArrowLeft size={16} />
          Назад к заказам
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <h3 className="text-lg font-semibold mb-4">Статус заказа</h3>
              {order.status === 'cancelled' ? (
                <div className="bg-red-50 text-red-700 px-4 py-3 rounded-lg text-sm font-medium">
                  Заказ отменён
                </div>
              ) : (
                <div className="flex flex-wrap items-center gap-2">
                  {flow.map((status, idx) => (
                    <React.Fragment key={status}>
                      <div
                        className={`px-3 py-2 rounded-lg text-xs font-medium ${
                          idx <= currentIdx ? 'bg-primary/10 text-primary' : 'bg-gray-100 text-gray-400'
                        }`}
                      >
                        {statusLabels[status]}
                      </div>
                      {idx < flow.length - 1 && (
                        <div className={`w-4 h-0.5 ${idx < currentIdx ? 'bg-primary' : 'bg-gray-200'}`} />
                      )}
                    </React.Fragment>
                  ))}
                </div>
              )}

              {needsStore && (
                <p className="mt-4 px-4 py-3 rounded-lg bg-orange-50 text-orange-700 text-sm">
                  Чтобы взять заказ в работу, назначьте точку{isAdmin ? ' справа' : ' (это делает администратор)'}.
                </p>
              )}

              {actionError && <p className="mt-4 text-sm text-red-600">{actionError}</p>}

              {(forward.length > 0 || canCancel) && (
                <div className="mt-4 flex flex-wrap gap-2">
                  {forward.map((status) => (
                    <button
                      key={status}
                      onClick={() => handleStatusChange(status)}
                      disabled={saving || needsStore}
                      className="px-5 py-3 bg-primary text-white text-sm font-medium rounded-lg hover:bg-primary-dark transition-colors disabled:opacity-50"
                    >
                      {statusAction(status, order.deliveryType)}
                    </button>
                  ))}
                  {canCancel && (
                    <button
                      onClick={() => handleStatusChange('cancelled')}
                      disabled={saving}
                      className="px-5 py-3 bg-red-50 text-red-600 text-sm font-medium rounded-lg hover:bg-red-100 transition-colors disabled:opacity-50"
                    >
                      Отменить
                    </button>
                  )}
                </div>
              )}
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <h3 className="text-lg font-semibold mb-4">Товары</h3>
              <div className="space-y-3">
                {order.items.map((item) => (
                  <div key={item.id} className="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                    <div>
                      <p className="text-sm font-medium">{item.name}</p>
                      <p className="text-xs text-gray-500">{item.price} сом × {item.quantity}</p>
                    </div>
                    <p className="text-sm font-semibold">{(item.price * item.quantity).toLocaleString()} сом</p>
                  </div>
                ))}
              </div>
              <div className="mt-4 pt-4 border-t border-gray-100 flex justify-between">
                <span className="font-semibold">Итого</span>
                <span className="font-bold text-primary">{order.totalSum.toLocaleString()} сом</span>
              </div>
            </div>

            {order.comment && (
              <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
                <h3 className="text-lg font-semibold mb-2">Комментарий клиента</h3>
                <p className="text-sm text-gray-700 whitespace-pre-wrap">{order.comment}</p>
              </div>
            )}
          </div>

          <div className="space-y-6">
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <h3 className="text-sm font-semibold text-gray-500 uppercase mb-3">Информация</h3>
              <div className="space-y-3 text-sm">
                <div>
                  <p className="text-gray-500">Клиент</p>
                  <p className="font-medium">{order.customerName ?? '—'}</p>
                  {order.userPhone && (
                    <a href={`tel:${order.userPhone}`} className="text-primary">
                      {order.userPhone}
                    </a>
                  )}
                </div>
                <div>
                  <p className="text-gray-500">Способ получения</p>
                  <p className="font-medium">
                    {order.deliveryType === 'delivery' ? 'Доставка' : 'Самовывоз'}
                  </p>
                </div>
                {order.deliveryTime && (
                  <div>
                    <p className="text-gray-500">Желаемое время</p>
                    <p className="font-medium">{new Date(order.deliveryTime).toLocaleString('ru-RU')}</p>
                  </div>
                )}
                {order.address && (
                  <div>
                    <p className="text-gray-500">Адрес доставки</p>
                    <p className="font-medium">{order.address}</p>
                  </div>
                )}
                <div>
                  <p className="text-gray-500">Точка</p>
                  {isAdmin && !isFinal ? (
                    <select
                      value={order.store?.id ?? ''}
                      onChange={(e) => handleAssignStore(e.target.value)}
                      disabled={saving}
                      className="mt-1 w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
                    >
                      <option value="" disabled>Выберите точку</option>
                      {stores.map((s) => (
                        <option key={s.id} value={s.id}>{s.name}</option>
                      ))}
                    </select>
                  ) : (
                    <p className="font-medium">{order.store?.name ?? 'Не назначена'}</p>
                  )}
                </div>
                <div>
                  <p className="text-gray-500">Создан</p>
                  <p className="font-medium">{new Date(order.createdAt).toLocaleString('ru-RU')}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default OrderDetails;
