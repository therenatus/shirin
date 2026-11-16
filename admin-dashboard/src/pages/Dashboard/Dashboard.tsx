import React, { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Wallet, ShoppingCart, Users, TrendingUp, Clock, CreditCard, Undo2, RefreshCw } from 'lucide-react';
import Header from '../../components/layout/Header';
import { DashboardStats, OrderStatus } from '../../types';
import { statusLabels, statusStyles } from '../../constants/orders';
import { apiErrorMessage } from '../../utils/errors';
import api from '../../services/api';

const som = (n: number) => `${Math.round(n).toLocaleString('ru-RU')} сом`;
const shortDate = (iso: string) => {
  const [, m, d] = iso.split('-');
  return `${d}.${m}`;
};

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [days, setDays] = useState(14);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const { data } = await api.get<DashboardStats>('/admin/dashboard', { params: { days } });
      setStats(data);
    } catch (err: any) {
      // No fallback to sample data: an outage must look like an outage
      setError(apiErrorMessage(err, 'Не удалось загрузить статистику'));
    } finally {
      setLoading(false);
    }
  }, [days]);

  useEffect(() => {
    load();
  }, [load]);

  const refreshButton = (
    <button
      onClick={load}
      className="p-2 text-gray-500 hover:bg-gray-100 rounded-lg"
      aria-label="Обновить"
      title="Обновить"
    >
      <RefreshCw size={18} className={loading ? 'animate-spin' : ''} />
    </button>
  );

  if (!stats) {
    return (
      <div>
        <Header title="Дашборд" actions={refreshButton} />
        <div className="p-8 flex items-center justify-center h-64">
          {error ? (
            <p className="text-red-600 text-sm">{error}</p>
          ) : (
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          )}
        </div>
      </div>
    );
  }

  const cards = [
    { label: 'Выручка сегодня', value: som(stats.today.revenue), icon: Wallet, color: 'bg-green-50 text-green-600' },
    { label: 'Заказов сегодня', value: String(stats.today.orders), icon: ShoppingCart, color: 'bg-blue-50 text-blue-600' },
    { label: 'Средний чек сегодня', value: som(stats.today.averageCheck), icon: TrendingUp, color: 'bg-orange-50 text-orange-600' },
    {
      label: 'Клиентов с заказами за 30 дней',
      value: String(stats.activeCustomers30d),
      hint: `новых сегодня: ${stats.today.newCustomers}`,
      icon: Users,
      color: 'bg-purple-50 text-purple-600',
    },
  ];

  const queue = [
    { label: 'Ждут подтверждения', value: stats.queue.pending, icon: Clock, to: '/orders', tone: 'text-yellow-700 bg-yellow-50' },
    { label: 'Ждут предоплату', value: stats.queue.awaitingPayment, icon: CreditCard, to: '/orders', tone: 'text-orange-700 bg-orange-50' },
    { label: 'Нужно вернуть предоплату', value: stats.queue.refundsPending, icon: Undo2, to: '/orders', tone: 'text-red-700 bg-red-50' },
  ];

  const periodTotal = stats.salesChart.reduce((s, d) => s + d.amount, 0);

  return (
    <div>
      <Header title="Дашборд" actions={refreshButton} />
      <div className="p-4 lg:p-8 space-y-6">
        {error && <p className="text-red-600 text-sm">{error}</p>}

        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
          {cards.map((card) => (
            <div key={card.label} className="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
              <div className={`w-10 h-10 rounded-lg flex items-center justify-center mb-3 ${card.color}`}>
                <card.icon size={20} />
              </div>
              <p className="text-2xl font-bold text-gray-900">{card.value}</p>
              <p className="text-sm text-gray-500 mt-1">{card.label}</p>
              {card.hint && <p className="text-xs text-gray-400 mt-1">{card.hint}</p>}
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {queue.map((q) => (
            <Link
              key={q.label}
              to={q.to}
              className={`rounded-xl p-4 flex items-center gap-3 border border-gray-100 ${q.value > 0 ? q.tone : 'bg-white text-gray-500'}`}
            >
              <q.icon size={20} />
              <span className="text-2xl font-bold">{q.value}</span>
              <span className="text-sm">{q.label}</span>
            </Link>
          ))}
        </div>

        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Выручка по дням</h3>
              <p className="text-sm text-gray-500">За период: {som(periodTotal)} · без отменённых заказов</p>
            </div>
            <select
              value={days}
              onChange={(e) => setDays(Number(e.target.value))}
              className="px-3 py-2 border border-gray-200 rounded-lg text-sm"
            >
              <option value={7}>7 дней</option>
              <option value={14}>14 дней</option>
              <option value={30}>30 дней</option>
            </select>
          </div>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={stats.salesChart}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" vertical={false} />
              <XAxis dataKey="date" tickFormatter={shortDate} tick={{ fontSize: 12, fill: '#6b7280' }} />
              <YAxis
                tickFormatter={(v) => (v >= 1000 ? `${Math.round(v / 1000)}k` : String(v))}
                tick={{ fontSize: 12, fill: '#6b7280' }}
                width={40}
              />
              <Tooltip
                formatter={(value, _name, item) => [
                  `${som(Number(value))} · заказов: ${(item?.payload as { orders?: number })?.orders ?? 0}`,
                  'Выручка',
                ]}
                labelFormatter={(label) => shortDate(String(label))}
              />
              <Bar dataKey="amount" fill="#D81B60" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 bg-white rounded-xl p-6 shadow-sm border border-gray-100">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Последние заказы</h3>
            <div className="overflow-x-auto">
              <table className="w-full text-sm min-w-[520px]">
                <thead>
                  <tr className="text-left text-gray-500 border-b border-gray-100">
                    <th className="pb-3 font-medium">Заказ</th>
                    <th className="pb-3 font-medium">Клиент</th>
                    <th className="pb-3 font-medium">Сумма</th>
                    <th className="pb-3 font-medium">Статус</th>
                  </tr>
                </thead>
                <tbody>
                  {stats.recentOrders.map((o) => {
                    const status = o.status.toLowerCase() as OrderStatus;
                    return (
                      <tr key={o.id} className="border-b border-gray-50">
                        <td className="py-3">
                          <Link to={`/orders/${o.id}`} className="font-medium hover:text-primary">
                            {o.orderNumber}
                          </Link>
                          <p className="text-xs text-gray-400">
                            {new Date(o.createdAt).toLocaleString('ru-RU', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}
                          </p>
                        </td>
                        <td className="py-3 text-gray-600">{o.customer}</td>
                        <td className="py-3">{som(o.total)}</td>
                        <td className="py-3">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${statusStyles[status] ?? 'bg-gray-100'}`}>
                            {statusLabels[status] ?? o.status}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
              {stats.recentOrders.length === 0 && <p className="text-center text-gray-500 py-8">Заказов пока нет</p>}
            </div>
          </div>

          <div className="space-y-6">
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">Топ товаров за 30 дней</h3>
              {stats.topProducts.length === 0 ? (
                <p className="text-sm text-gray-500">Пока нет продаж</p>
              ) : (
                <ol className="space-y-2 text-sm">
                  {stats.topProducts.map((p, i) => (
                    <li key={p.productId} className="flex justify-between gap-3">
                      <span className="truncate">
                        {i + 1}. {p.name}
                      </span>
                      <span className="text-gray-500 whitespace-nowrap">{p.quantity} шт</span>
                    </li>
                  ))}
                </ol>
              )}
            </div>
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">Баллы за 30 дней</h3>
              <p className="text-sm">
                Начислено: <b>{stats.loyalty30d.earned.toLocaleString('ru-RU')}</b>
              </p>
              <p className="text-sm">
                Списано: <b>{stats.loyalty30d.redeemed.toLocaleString('ru-RU')}</b>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
