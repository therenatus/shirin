import React, { useEffect, useState } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { DollarSign, ShoppingCart, Users, TrendingUp } from 'lucide-react';
import Header from '../../components/layout/Header';
import { DashboardStats } from '../../types';
import { getMockDashboardStats, isTestMode } from '../../services/mockData';
import api from '../../services/api';

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        if (isTestMode()) {
          setStats(getMockDashboardStats());
        } else {
          const response = await api.get('/admin/dashboard');
          setStats(response.data);
        }
      } catch {
        setStats(getMockDashboardStats());
      } finally {
        setLoading(false);
      }
    };
    fetchStats();
  }, []);

  if (loading) {
    return (
      <div>
        <Header title="Дашборд" />
        <div className="p-8 flex items-center justify-center h-64">
          <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
        </div>
      </div>
    );
  }

  if (!stats) return null;

  const statCards = [
    { label: 'Продажи сегодня', value: `${stats.todaySales.toLocaleString()} сом`, icon: DollarSign, color: 'bg-green-50 text-green-600' },
    { label: 'Заказов', value: stats.totalOrders.toString(), icon: ShoppingCart, color: 'bg-blue-50 text-blue-600' },
    { label: 'Активных клиентов', value: stats.activeCustomers.toString(), icon: Users, color: 'bg-purple-50 text-purple-600' },
    { label: 'Средний чек', value: `${stats.averageOrderValue.toLocaleString()} сом`, icon: TrendingUp, color: 'bg-orange-50 text-orange-600' },
  ];

  return (
    <div>
      <Header title="Дашборд" />
      <div className="p-8">
        {/* Stats cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {statCards.map((card) => (
            <div key={card.label} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-center justify-between mb-4">
                <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${card.color}`}>
                  <card.icon size={20} />
                </div>
              </div>
              <p className="text-2xl font-bold text-gray-900">{card.value}</p>
              <p className="text-sm text-gray-500 mt-1">{card.label}</p>
            </div>
          ))}
        </div>

        {/* Sales chart */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 mb-8">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Продажи за 30 дней</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={stats.salesChart}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis
                dataKey="date"
                tickFormatter={(val) => {
                  const d = new Date(val);
                  return `${d.getDate()}.${String(d.getMonth() + 1).padStart(2, '0')}`;
                }}
                tick={{ fontSize: 12, fill: '#6b7280' }}
              />
              <YAxis
                tickFormatter={(val) => `${(val / 1000).toFixed(0)}k`}
                tick={{ fontSize: 12, fill: '#6b7280' }}
              />
              <Tooltip
                formatter={(value) => [`${Number(value).toLocaleString()} сом`, 'Продажи']}
                labelFormatter={(label) => {
                  const d = new Date(label);
                  return d.toLocaleDateString('ru-RU');
                }}
              />
              <Line type="monotone" dataKey="amount" stroke="#D81B60" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Recent orders */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Последние заказы</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500 border-b border-gray-100">
                  <th className="pb-3 font-medium">ID</th>
                  <th className="pb-3 font-medium">Сумма</th>
                  <th className="pb-3 font-medium">Статус</th>
                  <th className="pb-3 font-medium">Дата</th>
                </tr>
              </thead>
              <tbody>
                {stats.recentOrders.map((order) => (
                  <tr key={order.id} className="border-b border-gray-50">
                    <td className="py-3 font-medium">#{order.id.slice(-4)}</td>
                    <td className="py-3">{order.totalSum.toLocaleString()} сом</td>
                    <td className="py-3">
                      <StatusBadge status={order.status} />
                    </td>
                    <td className="py-3 text-gray-500">
                      {new Date(order.createdAt).toLocaleDateString('ru-RU')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

const StatusBadge: React.FC<{ status: string }> = ({ status }) => {
  const styles: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-700',
    confirmed: 'bg-blue-100 text-blue-700',
    preparing: 'bg-purple-100 text-purple-700',
    ready: 'bg-teal-100 text-teal-700',
    delivered: 'bg-green-100 text-green-700',
    cancelled: 'bg-red-100 text-red-700',
  };
  const labels: Record<string, string> = {
    pending: 'Ожидает',
    confirmed: 'Подтверждён',
    preparing: 'Готовится',
    ready: 'Готов',
    delivered: 'Доставлен',
    cancelled: 'Отменён',
  };

  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${styles[status] || 'bg-gray-100 text-gray-700'}`}>
      {labels[status] || status}
    </span>
  );
};

export default Dashboard;
