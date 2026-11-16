import React, { useCallback, useEffect, useState } from 'react';
import { Search, ChevronLeft, ChevronRight } from 'lucide-react';
import Header from '../../components/layout/Header';
import { Customer } from '../../types';
import { apiErrorMessage } from '../../utils/errors';
import api from '../../services/api';

interface CustomersPage {
  data: Customer[];
  meta: { page: number; totalPages: number; total: number };
}

const date = (iso: string | null) =>
  iso ? new Date(iso).toLocaleDateString('ru-RU') : '—';

const UsersList: React.FC = () => {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState<'all' | 'active' | 'blocked'>('all');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const { data } = await api.get<CustomersPage>('/admin/customers', {
        params: {
          page,
          search: query || undefined,
          blocked: filter === 'all' ? undefined : filter === 'blocked',
        },
      });
      setCustomers(data.data);
      setTotalPages(Math.max(1, data.meta.totalPages));
      setTotal(data.meta.total);
    } catch (err: any) {
      setError(apiErrorMessage(err, 'Не удалось загрузить клиентов'));
    } finally {
      setLoading(false);
    }
  }, [page, query, filter]);

  useEffect(() => {
    load();
  }, [load]);

  const toggleBlock = async (c: Customer) => {
    const blocking = c.isActive;
    const name = [c.firstName, c.lastName].filter(Boolean).join(' ') || c.phone;
    if (
      !window.confirm(
        blocking
          ? `Заблокировать ${name}? Клиент сразу выйдет из приложения и не сможет войти.`
          : `Разблокировать ${name}?`,
      )
    ) {
      return;
    }
    setBusyId(c.id);
    try {
      await api.patch(`/admin/customers/${c.id}/block`, { blocked: blocking });
      setCustomers((list) => list.map((x) => (x.id === c.id ? { ...x, isActive: !blocking } : x)));
    } catch (err: any) {
      alert(apiErrorMessage(err, 'Не удалось изменить статус'));
    } finally {
      setBusyId(null);
    }
  };

  return (
    <div>
      <Header title="Клиенты" />
      <div className="p-4 lg:p-8">
        <form
          onSubmit={(e) => {
            e.preventDefault();
            setPage(1);
            setQuery(search.trim());
          }}
          className="flex flex-wrap items-center gap-3 mb-6"
        >
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input
              type="text"
              placeholder="Телефон или имя"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-10 pr-4 py-2 border border-gray-200 rounded-lg text-sm w-64 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
            />
          </div>
          <button type="submit" className="px-4 py-2 bg-primary text-white text-sm rounded-lg">
            Найти
          </button>
          <select
            value={filter}
            onChange={(e) => {
              setPage(1);
              setFilter(e.target.value as typeof filter);
            }}
            className="px-3 py-2 border border-gray-200 rounded-lg text-sm"
          >
            <option value="all">Все</option>
            <option value="active">Активные</option>
            <option value="blocked">Заблокированные</option>
          </select>
          <span className="text-sm text-gray-500">Найдено: {total}</span>
        </form>

        {error && <p className="text-red-500 text-sm mb-4">{error}</p>}

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-x-auto">
            <table className="w-full text-sm min-w-[820px]">
              <thead>
                <tr className="bg-gray-50 text-left text-gray-500">
                  <th className="px-4 py-3 font-medium">Клиент</th>
                  <th className="px-4 py-3 font-medium text-right">Заказов</th>
                  <th className="px-4 py-3 font-medium text-right">Сумма</th>
                  <th className="px-4 py-3 font-medium text-right">Баллы</th>
                  <th className="px-4 py-3 font-medium">Последний заказ</th>
                  <th className="px-4 py-3 font-medium">С нами с</th>
                  <th className="px-4 py-3 font-medium" aria-label="Действия" />
                </tr>
              </thead>
              <tbody>
                {customers.map((c) => (
                  <tr key={c.id} className={`border-t border-gray-50 ${c.isActive ? '' : 'bg-red-50/40'}`}>
                    <td className="px-4 py-3">
                      <p className="font-medium">
                        {[c.firstName, c.lastName].filter(Boolean).join(' ') || '—'}
                      </p>
                      <a href={`tel:${c.phone}`} className="text-xs text-gray-500 hover:text-primary">
                        {c.phone}
                      </a>
                      {!c.isActive && <p className="text-xs text-red-600">Заблокирован</p>}
                    </td>
                    <td className="px-4 py-3 text-right">{c.ordersCount}</td>
                    <td className="px-4 py-3 text-right whitespace-nowrap">
                      {c.totalSpent.toLocaleString('ru-RU')} сом
                    </td>
                    <td className="px-4 py-3 text-right">{c.loyaltyPoints.toLocaleString('ru-RU')}</td>
                    <td className="px-4 py-3 text-gray-500">{date(c.lastOrderAt)}</td>
                    <td className="px-4 py-3 text-gray-500">{date(c.createdAt)}</td>
                    <td className="px-4 py-3 text-right">
                      <button
                        onClick={() => toggleBlock(c)}
                        disabled={busyId === c.id}
                        className={`px-3 py-2 rounded-lg text-xs font-medium disabled:opacity-50 ${
                          c.isActive ? 'text-red-600 hover:bg-red-50' : 'text-green-700 hover:bg-green-50'
                        }`}
                      >
                        {c.isActive ? 'Заблокировать' : 'Разблокировать'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {customers.length === 0 && (
              <div className="text-center py-12 text-gray-500">
                {query ? 'Никого не нашли' : 'Клиентов пока нет'}
              </div>
            )}
          </div>
        )}

        {totalPages > 1 && (
          <div className="flex items-center justify-center gap-3 mt-6 text-sm">
            <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1} className="p-2 rounded-lg border border-gray-200 disabled:opacity-40" aria-label="Предыдущая страница">
              <ChevronLeft size={18} />
            </button>
            <span className="text-gray-600">{page} из {totalPages}</span>
            <button onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page === totalPages} className="p-2 rounded-lg border border-gray-200 disabled:opacity-40" aria-label="Следующая страница">
              <ChevronRight size={18} />
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default UsersList;
