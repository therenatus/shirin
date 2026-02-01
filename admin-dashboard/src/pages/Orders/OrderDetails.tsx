import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';
import Header from '../../components/layout/Header';
import { Order, OrderStatus } from '../../types';
import { getMockOrders, isTestMode } from '../../services/mockData';
import api from '../../services/api';

const statusLabels: Record<OrderStatus, string> = {
  pending: 'Ожидает',
  confirmed: 'Подтверждён',
  preparing: 'Готовится',
  ready: 'Готов',
  delivered: 'Доставлен',
  cancelled: 'Отменён',
};

const statusFlow: OrderStatus[] = ['pending', 'confirmed', 'preparing', 'ready', 'delivered'];

const OrderDetails: React.FC = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchOrder = async () => {
      try {
        if (isTestMode()) {
          const found = getMockOrders().find((o) => o.id === id);
          setOrder(found || null);
        } else {
          const response = await api.get(`/orders/${id}`);
          setOrder(response.data);
        }
      } catch {
        const found = getMockOrders().find((o) => o.id === id);
        setOrder(found || null);
      } finally {
        setLoading(false);
      }
    };
    fetchOrder();
  }, [id]);

  const handleStatusChange = async (newStatus: OrderStatus) => {
    if (!order) return;
    try {
      if (!isTestMode()) {
        await api.patch(`/orders/${id}/status`, { status: newStatus });
      }
      setOrder({ ...order, status: newStatus });
    } catch {
      alert('Ошибка при обновлении статуса');
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

  const currentIdx = statusFlow.indexOf(order.status);

  return (
    <div>
      <Header title={`Заказ #${order.id.slice(-4)}`} />
      <div className="p-8">
        <button
          onClick={() => navigate('/orders')}
          className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-6 text-sm"
        >
          <ArrowLeft size={16} />
          Назад к заказам
        </button>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Order info */}
          <div className="lg:col-span-2 space-y-6">
            {/* Status timeline */}
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <h3 className="text-lg font-semibold mb-4">Статус заказа</h3>
              {order.status === 'cancelled' ? (
                <div className="bg-red-50 text-red-700 px-4 py-3 rounded-lg text-sm font-medium">
                  Заказ отменён
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  {statusFlow.map((status, idx) => (
                    <React.Fragment key={status}>
                      <div className={`flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-medium ${
                        idx <= currentIdx
                          ? 'bg-primary/10 text-primary'
                          : 'bg-gray-100 text-gray-400'
                      }`}>
                        {statusLabels[status]}
                      </div>
                      {idx < statusFlow.length - 1 && (
                        <div className={`w-6 h-0.5 ${idx < currentIdx ? 'bg-primary' : 'bg-gray-200'}`} />
                      )}
                    </React.Fragment>
                  ))}
                </div>
              )}

              {order.status !== 'delivered' && order.status !== 'cancelled' && (
                <div className="mt-4 flex gap-2">
                  {currentIdx < statusFlow.length - 1 && (
                    <button
                      onClick={() => handleStatusChange(statusFlow[currentIdx + 1])}
                      className="px-4 py-2 bg-primary text-white text-sm rounded-lg hover:bg-primary-dark transition-colors"
                    >
                      {statusLabels[statusFlow[currentIdx + 1]]}
                    </button>
                  )}
                  <button
                    onClick={() => handleStatusChange('cancelled')}
                    className="px-4 py-2 bg-red-50 text-red-600 text-sm rounded-lg hover:bg-red-100 transition-colors"
                  >
                    Отменить
                  </button>
                </div>
              )}
            </div>

            {/* Items */}
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
          </div>

          {/* Sidebar info */}
          <div className="space-y-6">
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <h3 className="text-sm font-semibold text-gray-500 uppercase mb-3">Информация</h3>
              <div className="space-y-3 text-sm">
                <div>
                  <p className="text-gray-500">ID заказа</p>
                  <p className="font-medium">{order.id}</p>
                </div>
                <div>
                  <p className="text-gray-500">Дата создания</p>
                  <p className="font-medium">{new Date(order.createdAt).toLocaleString('ru-RU')}</p>
                </div>
                {order.address && (
                  <div>
                    <p className="text-gray-500">Адрес доставки</p>
                    <p className="font-medium">{order.address}</p>
                  </div>
                )}
                <div>
                  <p className="text-gray-500">ID клиента</p>
                  <p className="font-medium">{order.userId}</p>
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
