import React, { useEffect, useState } from 'react';
import Header from '../../components/layout/Header';
import { apiErrorMessage } from '../../utils/errors';
import api from '../../services/api';

interface Setting {
  key: string;
  value: string | null;
  description: string | null;
}

/** How each editable setting is shown; order defines the groups. */
const FIELDS: { key: string; label: string; hint?: string; type: 'number' | 'text' | 'url'; group: string }[] = [
  { key: 'payment_details', label: 'Реквизиты для предоплаты', hint: 'Этот текст клиент видит в заказе', type: 'text', group: 'Предоплата за торты' },
  { key: 'payment_qr_url', label: 'Ссылка на QR-код для оплаты', hint: 'Картинка QR компании (ELQR / банк)', type: 'url', group: 'Предоплата за торты' },
  { key: 'prepayment_timeout_minutes', label: 'Срок оплаты, минут', hint: 'Неоплаченный заказ отменяется автоматически', type: 'number', group: 'Предоплата за торты' },
  { key: 'loyalty_cashback_percent', label: 'Кешбэк, %', type: 'number', group: 'Баллы' },
  { key: 'loyalty_max_points_use_percent', label: 'Можно оплатить баллами, % от суммы', type: 'number', group: 'Баллы' },
  { key: 'loyalty_max_receipt_amount', label: 'Макс. сумма чека на кассе, сом', hint: 'Защита от ошибок кассира', type: 'number', group: 'Баллы' },
  { key: 'loyalty_daily_earn_limit', label: 'Макс. баллов клиенту на кассе за сутки', type: 'number', group: 'Баллы' },
  { key: 'delivery_fee', label: 'Стоимость доставки, сом', type: 'number', group: 'Доставка' },
  { key: 'free_delivery_min_amount', label: 'Бесплатная доставка от, сом', type: 'number', group: 'Доставка' },
];

const inputClass =
  'w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary';

const SettingsPage: React.FC = () => {
  const [saved, setSaved] = useState<Record<string, string>>({});
  const [draft, setDraft] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [savingKey, setSavingKey] = useState<string | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loadError, setLoadError] = useState('');

  useEffect(() => {
    api
      .get<Setting[]>('/settings/admin')
      .then((res) => {
        const values = Object.fromEntries(res.data.map((s) => [s.key, s.value ?? '']));
        setSaved(values);
        setDraft(values);
      })
      .catch((err) => setLoadError(apiErrorMessage(err, 'Не удалось загрузить настройки')))
      .finally(() => setLoading(false));
  }, []);

  const save = async (key: string) => {
    setSavingKey(key);
    setErrors((e) => ({ ...e, [key]: '' }));
    try {
      const { data } = await api.patch<{ key: string; value: string }>(`/settings/admin/${key}`, {
        value: draft[key] ?? '',
      });
      setSaved((s) => ({ ...s, [key]: data.value }));
      setDraft((d) => ({ ...d, [key]: data.value }));
    } catch (err: any) {
      setErrors((e) => ({ ...e, [key]: apiErrorMessage(err, 'Не удалось сохранить') }));
    } finally {
      setSavingKey(null);
    }
  };

  const groups = Array.from(new Set(FIELDS.map((f) => f.group)));

  return (
    <div>
      <Header title="Настройки" />
      <div className="p-4 lg:p-8 max-w-2xl space-y-6">
        {loadError && <p className="text-red-500 text-sm">{loadError}</p>}
        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : (
          groups.map((group) => (
            <div key={group} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 space-y-5">
              <h3 className="text-lg font-semibold">{group}</h3>
              {FIELDS.filter((f) => f.group === group).map((f) => {
                const dirty = (draft[f.key] ?? '') !== (saved[f.key] ?? '');
                return (
                  <div key={f.key}>
                    <label className="block text-sm font-medium text-gray-700 mb-1">{f.label}</label>
                    <div className="flex gap-2 items-start">
                      {f.type === 'text' ? (
                        <textarea
                          rows={3}
                          value={draft[f.key] ?? ''}
                          onChange={(e) => setDraft((d) => ({ ...d, [f.key]: e.target.value }))}
                          className={`${inputClass} resize-none`}
                        />
                      ) : (
                        <input
                          type={f.type === 'number' ? 'number' : 'url'}
                          inputMode={f.type === 'number' ? 'numeric' : 'url'}
                          value={draft[f.key] ?? ''}
                          onChange={(e) => setDraft((d) => ({ ...d, [f.key]: e.target.value }))}
                          className={inputClass}
                        />
                      )}
                      <button
                        onClick={() => save(f.key)}
                        disabled={!dirty || savingKey === f.key}
                        className="px-4 py-2 bg-primary text-white text-sm rounded-lg disabled:opacity-40 shrink-0"
                      >
                        Сохранить
                      </button>
                    </div>
                    {f.hint && <p className="text-xs text-gray-500 mt-1">{f.hint}</p>}
                    {errors[f.key] && <p className="text-xs text-red-600 mt-1">{errors[f.key]}</p>}
                    {f.key === 'payment_qr_url' && saved[f.key] && (
                      <img src={saved[f.key]} alt="QR для оплаты" className="mt-3 w-32 h-32 object-contain border border-gray-100 rounded-lg" />
                    )}
                  </div>
                );
              })}
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default SettingsPage;
