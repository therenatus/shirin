import React, { useState } from 'react';
import { Coffee, Search } from 'lucide-react';
import Header from '../../components/layout/Header';
import { CoffeeSize, PunchCard, StaffCustomer } from '../../types';
import api from '../../services/api';

const StaffClaim: React.FC = () => {
  const [qrCode, setQrCode] = useState('');
  const [customer, setCustomer] = useState<StaffCustomer | null>(null);
  const [loading, setLoading] = useState(false);
  const [claiming, setClaiming] = useState<CoffeeSize | null>(null);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    const code = qrCode.trim();
    if (!code) return;
    setLoading(true);
    setError('');
    setMessage('');
    setCustomer(null);
    try {
      const response = await api.get<StaffCustomer>(
        `/loyalty/staff/customer/${encodeURIComponent(code)}`
      );
      setCustomer(response.data);
    } catch (err: any) {
      setError(err?.response?.status === 404 ? 'Клиент не найден' : 'Ошибка при поиске клиента');
    } finally {
      setLoading(false);
    }
  };

  const handleClaim = async (card: PunchCard) => {
    if (!customer) return;
    if (!window.confirm(`Выдать бесплатный ${card.sizeName}?`)) return;
    setClaiming(card.size);
    setError('');
    setMessage('');
    try {
      const response = await api.post<PunchCard>('/loyalty/staff/claim', {
        qrCode: qrCode.trim(),
        size: card.size,
      });
      setCustomer({
        ...customer,
        punchCards: customer.punchCards.map((c) => (c.size === card.size ? response.data : c)),
      });
      setMessage(`${card.sizeName} выдан, карта обнулена`);
    } catch (err: any) {
      setError(err?.response?.data?.message || 'Не удалось выдать кофе');
    } finally {
      setClaiming(null);
    }
  };

  const customerName =
    customer && [customer.firstName, customer.lastName].filter(Boolean).join(' ');

  return (
    <div>
      <Header title="Выдача кофе" />
      <div className="p-8 max-w-3xl">
        <form onSubmit={handleSearch} className="flex gap-3 mb-6">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input
              autoFocus
              value={qrCode}
              onChange={(e) => setQrCode(e.target.value)}
              placeholder="Отсканируйте или вставьте QR-код клиента"
              className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="px-5 py-3 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-dark disabled:opacity-50"
          >
            {loading ? 'Поиск...' : 'Найти'}
          </button>
        </form>

        {error && <p className="text-red-500 text-sm mb-4">{error}</p>}
        {message && <p className="text-green-600 text-sm mb-4">{message}</p>}

        {customer && (
          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
            <div className="mb-6">
              <p className="text-lg font-semibold">{customerName || 'Без имени'}</p>
              <p className="text-sm text-gray-500">
                {customer.phone} · {customer.loyaltyPoints} баллов · {customer.level}
              </p>
            </div>

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
                        className={`h-2 flex-1 rounded-full ${
                          i < card.currentPunches ? 'bg-primary' : 'bg-gray-200'
                        }`}
                      />
                    ))}
                  </div>
                  <p className="text-xs text-gray-500 mb-3">
                    {card.currentPunches} / {card.maxPunches}
                  </p>
                  <button
                    onClick={() => handleClaim(card)}
                    disabled={!card.isComplete || claiming !== null}
                    className="w-full py-2 text-sm rounded-lg font-medium bg-primary text-white hover:bg-primary-dark disabled:bg-gray-100 disabled:text-gray-400"
                  >
                    {claiming === card.size ? 'Выдача...' : 'Выдать'}
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default StaffClaim;
