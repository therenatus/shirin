import React, { useCallback, useEffect, useState } from 'react';
import { ChevronLeft, ChevronRight, Undo2 } from 'lucide-react';
import Header from '../../components/layout/Header';
import { LoyaltyReport as Report, LoyaltyTransaction, LoyaltyTxType, Store } from '../../types';
import { useAuthStore } from '../../store/authStore';
import { apiErrorMessage } from '../../utils/errors';
import api from '../../services/api';

const typeLabels: Record<LoyaltyTxType, string> = {
  EARN: 'Начисление',
  REDEEM: 'Списание',
  REFUND: 'Возврат',
  ADJUST: 'Корректировка',
  REVERSAL: 'Отмена',
  FREE_COFFEE: 'Бесплатный кофе',
};

const sourceLabels: Record<string, string> = {
  APP_ORDER: 'Приложение',
  IN_STORE: 'Касса',
  ONE_C: '1С',
  MANUAL: 'Вручную',
};

/** yyyy-mm-dd in local time for <input type="date">. */
const localDate = (d: Date) => {
  const shifted = new Date(d.getTime() - d.getTimezoneOffset() * 60000);
  return shifted.toISOString().slice(0, 10);
};

const person = (p: { phone: string; firstName?: string | null; lastName?: string | null } | null) =>
  p ? [p.firstName, p.lastName].filter(Boolean).join(' ') || p.phone : '—';

const LoyaltyReport: React.FC = () => {
  const isAdmin = useAuthStore((s) => s.role === 'ADMIN');
  const today = localDate(new Date());
  const [from, setFrom] = useState(today);
  const [to, setTo] = useState(today);
  const [storeId, setStoreId] = useState('');
  const [type, setType] = useState('');
  const [onlyCashDesk, setOnlyCashDesk] = useState(true);
  const [stores, setStores] = useState<Store[]>([]);
  const [page, setPage] = useState(1);
  const [report, setReport] = useState<Report | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!isAdmin) return;
    api
      .get<Store[]>('/stores')
      .then((res) => setStores(res.data))
      .catch(() => setStores([]));
  }, [isAdmin]);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      // Whole local days: from 00:00 of `from` to 00:00 after `to`
      const start = new Date(`${from}T00:00:00`);
      const end = new Date(`${to}T00:00:00`);
      end.setDate(end.getDate() + 1);
      const { data } = await api.get<Report>('/loyalty/staff/transactions', {
        params: {
          page,
          limit: 50,
          from: start.toISOString(),
          to: end.toISOString(),
          storeId: isAdmin && storeId ? storeId : undefined,
          type: type || undefined,
          source: onlyCashDesk ? 'IN_STORE' : undefined,
        },
      });
      setReport(data);
    } catch (err: any) {
      setError(apiErrorMessage(err, 'Не удалось загрузить операции'));
    } finally {
      setLoading(false);
    }
  }, [from, to, storeId, type, onlyCashDesk, page, isAdmin]);

  useEffect(() => {
    load();
  }, [load]);

  const reverse = async (tx: LoyaltyTransaction) => {
    const reason = window.prompt(
      `Отменить «${typeLabels[tx.type]}» на ${tx.points} баллов (${person(tx.user)})? Укажите причину:`,
    );
    if (reason === null) return;
    try {
      await api.post(`/loyalty/staff/transactions/${tx.id}/reverse`, { reason: reason || undefined });
      load();
    } catch (err: any) {
      alert(apiErrorMessage(err, 'Не удалось отменить операцию'));
    }
  };

  const total = (t: LoyaltyTxType) => report?.totals.find((x) => x.type === t);
  const earned = total('EARN');
  const redeemed = total('REDEEM');
  const reversed = total('REVERSAL');

  const filterClass =
    'px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary';

  return (
    <div>
      <Header title="Операции с баллами" />
      <div className="p-4 lg:p-8">
        <div className="flex flex-wrap items-end gap-3 mb-6">
          <label className="text-sm">
            <span className="block text-gray-500 mb-1">С</span>
            <input type="date" value={from} max={to} onChange={(e) => { setFrom(e.target.value); setPage(1); }} className={filterClass} />
          </label>
          <label className="text-sm">
            <span className="block text-gray-500 mb-1">По</span>
            <input type="date" value={to} min={from} onChange={(e) => { setTo(e.target.value); setPage(1); }} className={filterClass} />
          </label>
          {isAdmin && (
            <select value={storeId} onChange={(e) => { setStoreId(e.target.value); setPage(1); }} className={filterClass}>
              <option value="">Все точки</option>
              {stores.map((s) => (
                <option key={s.id} value={s.id}>{s.name}</option>
              ))}
            </select>
          )}
          <select value={type} onChange={(e) => { setType(e.target.value); setPage(1); }} className={filterClass}>
            <option value="">Все операции</option>
            {Object.entries(typeLabels).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
          <label className="flex items-center gap-2 text-sm text-gray-600 py-2">
            <input type="checkbox" checked={onlyCashDesk} onChange={(e) => { setOnlyCashDesk(e.target.checked); setPage(1); }} />
            Только касса
          </label>
        </div>

        {report && (
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
            <div className="bg-white rounded-xl p-4 border border-gray-100">
              <p className="text-sm text-gray-500">Начислено</p>
              <p className="text-2xl font-bold">{earned?.points ?? 0}</p>
              <p className="text-xs text-gray-500">
                {earned?.count ?? 0} чеков на {(earned?.receiptAmount ?? 0).toLocaleString()} сом
              </p>
            </div>
            <div className="bg-white rounded-xl p-4 border border-gray-100">
              <p className="text-sm text-gray-500">Списано (скидка, сом)</p>
              <p className="text-2xl font-bold">{Math.abs(redeemed?.points ?? 0)}</p>
              <p className="text-xs text-gray-500">{redeemed?.count ?? 0} операций</p>
            </div>
            <div className="bg-white rounded-xl p-4 border border-gray-100">
              <p className="text-sm text-gray-500">Отменено</p>
              <p className="text-2xl font-bold">{reversed?.count ?? 0}</p>
              <p className="text-xs text-gray-500">операций</p>
            </div>
          </div>
        )}

        {error && <p className="text-red-500 text-sm mb-4">{error}</p>}

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-x-auto">
            <table className="w-full text-sm min-w-[860px]">
              <thead>
                <tr className="bg-gray-50 text-left text-gray-500">
                  <th className="px-4 py-3 font-medium">Время</th>
                  <th className="px-4 py-3 font-medium">Операция</th>
                  <th className="px-4 py-3 font-medium text-right">Баллы</th>
                  <th className="px-4 py-3 font-medium">Чек</th>
                  <th className="px-4 py-3 font-medium">Клиент</th>
                  <th className="px-4 py-3 font-medium">Сотрудник / точка</th>
                  {isAdmin && <th className="px-4 py-3" aria-label="Действия" />}
                </tr>
              </thead>
              <tbody>
                {report?.data.map((tx) => (
                  <tr key={tx.id} className={`border-t border-gray-50 ${tx.isReversed ? 'text-gray-400 line-through' : ''}`}>
                    <td className="px-4 py-3 whitespace-nowrap">
                      {new Date(tx.createdAt).toLocaleString('ru-RU', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}
                    </td>
                    <td className="px-4 py-3">
                      {typeLabels[tx.type]}
                      <p className="text-xs text-gray-500 no-underline">
                        {sourceLabels[tx.source]}
                        {tx.order && ` · ${tx.order.orderNumber}`}
                      </p>
                    </td>
                    <td className={`px-4 py-3 text-right font-medium ${tx.points > 0 ? 'text-green-700' : tx.points < 0 ? 'text-red-600' : ''}`}>
                      {tx.points > 0 ? `+${tx.points}` : tx.points}
                    </td>
                    <td className="px-4 py-3">
                      {tx.receiptNumber ?? '—'}
                      {tx.receiptAmount !== null && (
                        <p className="text-xs text-gray-500">{tx.receiptAmount.toLocaleString()} сом</p>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {person(tx.user)}
                      <p className="text-xs text-gray-500">{tx.user.phone}</p>
                    </td>
                    <td className="px-4 py-3">
                      {person(tx.staff)}
                      <p className="text-xs text-gray-500">{tx.store?.name ?? ''}</p>
                    </td>
                    {isAdmin && (
                      <td className="px-4 py-3">
                        {!tx.isReversed && tx.type !== 'REVERSAL' && tx.type !== 'FREE_COFFEE' && tx.points !== 0 && (
                          <button
                            onClick={() => reverse(tx)}
                            className="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded-lg"
                            title="Отменить операцию"
                            aria-label="Отменить операцию"
                          >
                            <Undo2 size={16} />
                          </button>
                        )}
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
            {report?.data.length === 0 && (
              <div className="text-center py-12 text-gray-500">Операций за период нет</div>
            )}
          </div>
        )}

        {report && report.meta.totalPages > 1 && (
          <div className="flex items-center justify-center gap-3 mt-6 text-sm">
            <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1} className="p-2 rounded-lg border border-gray-200 disabled:opacity-40" aria-label="Предыдущая страница">
              <ChevronLeft size={18} />
            </button>
            <span className="text-gray-600">{page} из {report.meta.totalPages}</span>
            <button onClick={() => setPage((p) => Math.min(report.meta.totalPages, p + 1))} disabled={page === report.meta.totalPages} className="p-2 rounded-lg border border-gray-200 disabled:opacity-40" aria-label="Следующая страница">
              <ChevronRight size={18} />
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default LoyaltyReport;
