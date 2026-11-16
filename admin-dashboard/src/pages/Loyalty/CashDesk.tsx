import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { Coffee, Search, PlusCircle, MinusCircle, X } from 'lucide-react';
import Header from '../../components/layout/Header';
import { CoffeeSize, PunchCard, StaffCustomer, Store } from '../../types';
import { useAuthStore } from '../../store/authStore';
import { apiErrorMessage } from '../../utils/errors';
import api from '../../services/api';

type Tab = 'earn' | 'redeem' | 'coffee';

const inputClass =
  'w-full px-4 py-3 border border-gray-200 rounded-lg text-base focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary';

const toAmount = (value: string) => {
  const n = Number(value.replace(',', '.'));
  return Number.isFinite(n) && n > 0 ? Math.round(n * 100) / 100 : 0;
};

/**
 * Cash desk: find a customer by the QR from the app, credit cashback for a
 * receipt, pay part of it with points (live QR only), give out free coffee.
 */
const CashDesk: React.FC = () => {
  const role = useAuthStore((s) => s.role);
  const canHandlePoints = role === 'ADMIN' || role === 'STORE_STAFF';
  const needsStorePick = role === 'ADMIN';

  const [code, setCode] = useState('');
  const [customer, setCustomer] = useState<StaffCustomer | null>(null);
  const [tab, setTab] = useState<Tab>(canHandlePoints ? 'earn' : 'coffee');
  const [stores, setStores] = useState<Store[]>([]);
  const [storeId, setStoreId] = useState('');
  const [receiptNumber, setReceiptNumber] = useState('');
  const [receiptAmount, setReceiptAmount] = useState('');
  const [points, setPoints] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const scanRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!needsStorePick) return;
    api
      .get<Store[]>('/stores')
      .then((res) => setStores(res.data))
      .catch(() => setStores([]));
  }, [needsStorePick]);

  const resetReceipt = () => {
    setReceiptNumber('');
    setReceiptAmount('');
    setPoints('');
  };

  /** Ready for the next customer: clear everything and focus the scanner field. */
  const nextCustomer = () => {
    setCustomer(null);
    setCode('');
    resetReceipt();
    setError('');
    setTab(canHandlePoints ? 'earn' : 'coffee');
    setTimeout(() => scanRef.current?.focus(), 0);
  };

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    const scanned = code.trim();
    if (!scanned) return;
    setBusy(true);
    setError('');
    setMessage('');
    setCustomer(null);
    resetReceipt();
    try {
      const { data } = await api.get<StaffCustomer>(
        `/loyalty/staff/customer/${encodeURIComponent(scanned)}`,
      );
      setCustomer(data);
      if (canHandlePoints) setTab(data.canRedeem && data.loyaltyPoints > 0 ? 'redeem' : 'earn');
    } catch (err: any) {
      setError(apiErrorMessage(err, 'Ошибка при поиске клиента'));
    } finally {
      setBusy(false);
    }
  };

  const amount = toAmount(receiptAmount);
  const cashbackPreview = customer ? Math.floor((amount * customer.cashbackPercent) / 100) : 0;
  const maxRedeem = customer
    ? Math.min(customer.loyaltyPoints, Math.floor((amount * customer.maxPointsUsePercent) / 100))
    : 0;
  const pointsValue = Math.floor(Number(points) || 0);
  const storeMissing = needsStorePick && !storeId;

  const submitEarn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!customer) return;
    setBusy(true);
    setError('');
    setMessage('');
    try {
      const { data } = await api.post<{ points: number; balance: number }>('/loyalty/staff/earn', {
        code: customer.customerCode,
        receiptNumber: receiptNumber.trim(),
        receiptAmount: amount,
        storeId: needsStorePick ? storeId : undefined,
      });
      setCustomer({ ...customer, loyaltyPoints: data.balance });
      setMessage(`Начислено ${data.points} баллов. Баланс: ${data.balance}`);
      resetReceipt();
    } catch (err: any) {
      setError(apiErrorMessage(err, 'Не удалось начислить баллы'));
    } finally {
      setBusy(false);
    }
  };

  const submitRedeem = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!customer) return;
    if (!window.confirm(`Списать ${pointsValue} баллов? Скидка ${pointsValue} сом.`)) return;
    setBusy(true);
    setError('');
    setMessage('');
    try {
      const { data } = await api.post<{ points: number; balance: number }>('/loyalty/staff/redeem', {
        code: code.trim(),
        receiptNumber: receiptNumber.trim(),
        receiptAmount: amount,
        points: pointsValue,
        storeId: needsStorePick ? storeId : undefined,
      });
      // The live QR is used up; further operations go by the permanent code
      setCustomer({ ...customer, loyaltyPoints: data.balance, canRedeem: false });
      setMessage(
        `Списано ${data.points} баллов — скидка ${data.points} сом. Баланс: ${data.balance}. ` +
          'Кешбэк на оплаченную деньгами часть можно начислить во вкладке «Начислить».',
      );
      resetReceipt();
      setTab('earn');
    } catch (err: any) {
      setError(apiErrorMessage(err, 'Не удалось списать баллы'));
      if (err?.response?.data?.message?.startsWith?.('QR code has expired')) {
        setCustomer({ ...customer, canRedeem: false });
      }
    } finally {
      setBusy(false);
    }
  };

  const claimCoffee = async (card: PunchCard) => {
    if (!customer) return;
    if (!window.confirm(`Выдать бесплатный ${card.sizeName}?`)) return;
    setBusy(true);
    setError('');
    setMessage('');
    try {
      const { data } = await api.post<PunchCard>('/loyalty/staff/claim', {
        qrCode: customer.customerCode,
        size: card.size as CoffeeSize,
      });
      setCustomer({
        ...customer,
        punchCards: customer.punchCards.map((c) => (c.size === card.size ? data : c)),
      });
      setMessage(`${card.sizeName} выдан, карта обнулена`);
    } catch (err: any) {
      setError(apiErrorMessage(err, 'Не удалось выдать кофе'));
    } finally {
      setBusy(false);
    }
  };

  const customerName = customer && [customer.firstName, customer.lastName].filter(Boolean).join(' ');
  const tabs: { key: Tab; label: string; icon: React.ElementType }[] = [
    ...(canHandlePoints
      ? [
          { key: 'earn' as Tab, label: 'Начислить', icon: PlusCircle },
          { key: 'redeem' as Tab, label: 'Списать', icon: MinusCircle },
        ]
      : []),
    { key: 'coffee', label: 'Кофе', icon: Coffee },
  ];

  const receiptFields = (
    <>
      {needsStorePick && (
        <label className="block">
          <span className="text-sm text-gray-600">Точка</span>
          <select value={storeId} onChange={(e) => setStoreId(e.target.value)} className={inputClass}>
            <option value="">Выберите точку</option>
            {stores.map((s) => (
              <option key={s.id} value={s.id}>{s.name}</option>
            ))}
          </select>
        </label>
      )}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <label className="block">
          <span className="text-sm text-gray-600">Номер чека</span>
          <input
            value={receiptNumber}
            onChange={(e) => setReceiptNumber(e.target.value)}
            className={inputClass}
            placeholder="Например, 004512"
            required
          />
        </label>
        <label className="block">
          <span className="text-sm text-gray-600">Сумма чека, сом</span>
          <input
            value={receiptAmount}
            onChange={(e) => setReceiptAmount(e.target.value)}
            className={inputClass}
            inputMode="decimal"
            placeholder="0"
            required
          />
        </label>
      </div>
    </>
  );

  return (
    <div>
      <Header title="Касса" />
      <div className="p-4 lg:p-8 max-w-3xl">
        <form onSubmit={handleSearch} className="flex gap-3 mb-6">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input
              ref={scanRef}
              autoFocus
              value={code}
              onChange={(e) => setCode(e.target.value)}
              placeholder="Отсканируйте QR-код клиента"
              className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-lg text-base focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
            />
          </div>
          <button
            type="submit"
            disabled={busy}
            className="px-5 py-3 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-dark disabled:opacity-50"
          >
            Найти
          </button>
        </form>

        {error && <p className="px-4 py-3 mb-4 rounded-lg bg-red-50 text-red-700 text-sm">{error}</p>}
        {message && <p className="px-4 py-3 mb-4 rounded-lg bg-green-50 text-green-700 text-sm">{message}</p>}

        {customer && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100">
            <div className="p-6 flex items-start justify-between gap-4 border-b border-gray-100">
              <div>
                <p className="text-lg font-semibold">{customerName || 'Без имени'}</p>
                <p className="text-sm text-gray-500">
                  {customer.phone} · {customer.level}
                </p>
              </div>
              <div className="text-right">
                <p className="text-3xl font-bold text-primary leading-none">{customer.loyaltyPoints}</p>
                <p className="text-xs text-gray-500 mt-1">баллов</p>
              </div>
              <button
                onClick={nextCustomer}
                className="p-2 -mr-2 -mt-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg"
                aria-label="Следующий клиент"
                title="Следующий клиент"
              >
                <X size={20} />
              </button>
            </div>

            <div className="flex border-b border-gray-100">
              {tabs.map((t) => (
                <button
                  key={t.key}
                  onClick={() => {
                    setTab(t.key);
                    setError('');
                  }}
                  className={`flex-1 flex items-center justify-center gap-2 py-4 text-sm font-medium border-b-2 ${
                    tab === t.key ? 'border-primary text-primary' : 'border-transparent text-gray-500'
                  }`}
                >
                  <t.icon size={18} />
                  {t.label}
                </button>
              ))}
            </div>

            <div className="p-6">
              {tab === 'earn' && (
                <form onSubmit={submitEarn} className="space-y-4">
                  {receiptFields}
                  <p className="text-sm text-gray-600">
                    Будет начислено: <b>{cashbackPreview}</b> баллов ({customer.cashbackPercent}% от суммы)
                  </p>
                  <button
                    type="submit"
                    disabled={busy || cashbackPreview <= 0 || !receiptNumber.trim() || storeMissing}
                    className="w-full py-4 bg-primary text-white rounded-lg font-medium disabled:opacity-40"
                  >
                    Начислить {cashbackPreview > 0 ? `${cashbackPreview} баллов` : ''}
                  </button>
                </form>
              )}

              {tab === 'redeem' &&
                (customer.canRedeem ? (
                  <form onSubmit={submitRedeem} className="space-y-4">
                    {receiptFields}
                    <label className="block">
                      <span className="text-sm text-gray-600">
                        Баллов к списанию (не больше {maxRedeem})
                      </span>
                      <div className="flex gap-2">
                        <input
                          value={points}
                          onChange={(e) => setPoints(e.target.value.replace(/\D/g, ''))}
                          className={inputClass}
                          inputMode="numeric"
                          placeholder="0"
                          required
                        />
                        <button
                          type="button"
                          onClick={() => setPoints(String(maxRedeem))}
                          disabled={maxRedeem <= 0}
                          className="px-4 rounded-lg bg-gray-100 text-sm font-medium disabled:opacity-40"
                        >
                          Максимум
                        </button>
                      </div>
                    </label>
                    {amount > 0 && pointsValue > 0 && (
                      <p className="text-sm text-gray-600">
                        К оплате деньгами: <b>{Math.max(0, amount - pointsValue).toLocaleString()} сом</b>
                      </p>
                    )}
                    <button
                      type="submit"
                      disabled={
                        busy ||
                        pointsValue <= 0 ||
                        pointsValue > maxRedeem ||
                        !receiptNumber.trim() ||
                        storeMissing
                      }
                      className="w-full py-4 bg-primary text-white rounded-lg font-medium disabled:opacity-40"
                    >
                      Списать {pointsValue > 0 ? `${pointsValue} баллов` : ''}
                    </button>
                  </form>
                ) : (
                  <p className="px-4 py-3 rounded-lg bg-yellow-50 text-yellow-800 text-sm">
                    Для списания попросите клиента открыть карту в приложении и отсканируйте QR-код
                    с экрана заново. Распечатанный или сохранённый код для списания не подходит.
                  </p>
                ))}

              {tab === 'coffee' && (
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  {customer.punchCards.map((card) => (
                    <div
                      key={card.id}
                      className={`rounded-lg border p-4 ${
                        card.isComplete ? 'border-primary bg-primary/5' : 'border-gray-100'
                      }`}
                    >
                      <div className="flex items-center gap-2 mb-3">
                        <Coffee size={18} className="text-primary" />
                        <span className="font-medium">{card.sizeName}</span>
                      </div>
                      <div className="flex gap-1 mb-3">
                        {Array.from({ length: card.maxPunches }, (_, i) => (
                          <div
                            key={i}
                            className={`h-2 flex-1 rounded-full ${i < card.currentPunches ? 'bg-primary' : 'bg-gray-200'}`}
                          />
                        ))}
                      </div>
                      <p className="text-xs text-gray-500 mb-3">
                        {card.currentPunches} / {card.maxPunches}
                      </p>
                      <button
                        onClick={() => claimCoffee(card)}
                        disabled={!card.isComplete || busy}
                        className="w-full py-3 text-sm rounded-lg font-medium bg-primary text-white hover:bg-primary-dark disabled:bg-gray-100 disabled:text-gray-400"
                      >
                        Выдать
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {canHandlePoints && (
          <p className="mt-6 text-sm">
            <Link to="/loyalty/report" className="text-primary hover:underline">
              Операции за смену →
            </Link>
          </p>
        )}
      </div>
    </div>
  );
};

export default CashDesk;
