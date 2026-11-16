import React, { useCallback, useEffect, useState } from 'react';
import { Plus, Edit, Trash2, Calendar } from 'lucide-react';
import Header from '../../components/layout/Header';
import ImageUpload from '../../components/ui/ImageUpload';
import { AdminPromotion, PromotionType } from '../../types';
import { apiErrorMessage } from '../../utils/errors';
import api from '../../services/api';

const typeLabels: Record<PromotionType, string> = {
  DISCOUNT: 'Скидка',
  CASHBACK: 'Кешбэк',
  GIFT: 'Подарок',
  COMBO: 'Комбо',
};

/** yyyy-mm-dd for <input type="date"> in local time. */
const toInput = (iso: string) => {
  const d = new Date(iso);
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
};

interface FormState {
  titleRu: string;
  titleKy: string;
  descriptionRu: string;
  descriptionKy: string;
  image: string | null;
  type: PromotionType;
  startDate: string;
  endDate: string;
  isActive: boolean;
  sortOrder: number;
}

const emptyForm = (): FormState => {
  const today = toInput(new Date().toISOString());
  const month = toInput(new Date(Date.now() + 30 * 86400000).toISOString());
  return {
    titleRu: '',
    titleKy: '',
    descriptionRu: '',
    descriptionKy: '',
    image: null,
    type: 'DISCOUNT',
    startDate: today,
    endDate: month,
    isActive: true,
    sortOrder: 0,
  };
};

const inputClass =
  'w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary';

const PromotionsList: React.FC = () => {
  const [promotions, setPromotions] = useState<AdminPromotion[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState<AdminPromotion | 'new' | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const { data } = await api.get<AdminPromotion[]>('/admin/promotions');
      setPromotions(data);
    } catch (err: any) {
      setError(apiErrorMessage(err, 'Не удалось загрузить акции'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const openNew = () => {
    setForm(emptyForm());
    setFormError('');
    setEditing('new');
  };

  const openEdit = (p: AdminPromotion) => {
    setForm({
      titleRu: p.titleRu || p.title,
      titleKy: p.titleKy ?? '',
      descriptionRu: p.descriptionRu || p.description,
      descriptionKy: p.descriptionKy ?? '',
      image: p.image || null,
      type: p.type,
      startDate: toInput(p.startDate),
      endDate: toInput(p.endDate),
      isActive: p.isActive,
      sortOrder: p.sortOrder,
    });
    setFormError('');
    setEditing(p);
  };

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.image) {
      setFormError('Загрузите картинку для баннера');
      return;
    }
    setSaving(true);
    setFormError('');
    const payload = {
      ...form,
      titleKy: form.titleKy || undefined,
      descriptionKy: form.descriptionKy || undefined,
      // Whole days: from the start of the first to the end of the last
      startDate: new Date(`${form.startDate}T00:00:00`).toISOString(),
      endDate: new Date(`${form.endDate}T23:59:59`).toISOString(),
    };
    try {
      if (editing === 'new') {
        await api.post('/admin/promotions', payload);
      } else if (editing) {
        await api.patch(`/admin/promotions/${editing.id}`, payload);
      }
      setEditing(null);
      load();
    } catch (err: any) {
      setFormError(apiErrorMessage(err, 'Не удалось сохранить акцию'));
    } finally {
      setSaving(false);
    }
  };

  const remove = async (p: AdminPromotion) => {
    if (!window.confirm(`Удалить акцию «${p.titleRu || p.title}»?`)) return;
    try {
      await api.delete(`/admin/promotions/${p.id}`);
      setPromotions((list) => list.filter((x) => x.id !== p.id));
    } catch (err: any) {
      alert(apiErrorMessage(err, 'Не удалось удалить акцию'));
    }
  };

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) =>
    setForm((f) => ({ ...f, [key]: value }));

  return (
    <div>
      <Header title="Акции" />
      <div className="p-4 lg:p-8">
        <div className="flex flex-wrap items-center justify-between gap-3 mb-6">
          <p className="text-sm text-gray-500 max-w-xl">
            Акции показываются в приложении как баннеры. Скидка по акции к заказу
            автоматически не применяется.
          </p>
          <button
            onClick={openNew}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-dark"
          >
            <Plus size={18} />
            Новая акция
          </button>
        </div>

        {error && <p className="text-red-500 text-sm mb-4">{error}</p>}

        {editing && (
          <form onSubmit={save} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 mb-6 space-y-4">
            <h3 className="text-lg font-semibold">{editing === 'new' ? 'Новая акция' : 'Редактировать акцию'}</h3>
            <div className="grid grid-cols-1 md:grid-cols-[auto,1fr] gap-6">
              <ImageUpload
                value={form.image}
                onChange={(url) => set('image', url)}
                folder="promotions"
                label="Баннер"
                aspect="aspect-[2/1]"
              />
              <div className="space-y-3">
                <label className="block">
                  <span className="text-sm text-gray-700">Заголовок (RU) *</span>
                  <input value={form.titleRu} onChange={(e) => set('titleRu', e.target.value)} className={inputClass} required maxLength={120} />
                </label>
                <label className="block">
                  <span className="text-sm text-gray-700">Заголовок (KY)</span>
                  <input value={form.titleKy} onChange={(e) => set('titleKy', e.target.value)} className={inputClass} maxLength={120} />
                </label>
              </div>
            </div>
            <label className="block">
              <span className="text-sm text-gray-700">Описание (RU) *</span>
              <textarea value={form.descriptionRu} onChange={(e) => set('descriptionRu', e.target.value)} className={`${inputClass} resize-none`} rows={3} required maxLength={2000} />
            </label>
            <label className="block">
              <span className="text-sm text-gray-700">Описание (KY)</span>
              <textarea value={form.descriptionKy} onChange={(e) => set('descriptionKy', e.target.value)} className={`${inputClass} resize-none`} rows={2} maxLength={2000} />
            </label>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              <label className="block">
                <span className="text-sm text-gray-700">Тип</span>
                <select value={form.type} onChange={(e) => set('type', e.target.value as PromotionType)} className={inputClass}>
                  {Object.entries(typeLabels).map(([k, v]) => (
                    <option key={k} value={k}>{v}</option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="text-sm text-gray-700">С</span>
                <input type="date" value={form.startDate} onChange={(e) => set('startDate', e.target.value)} className={inputClass} required />
              </label>
              <label className="block">
                <span className="text-sm text-gray-700">По</span>
                <input type="date" value={form.endDate} min={form.startDate} onChange={(e) => set('endDate', e.target.value)} className={inputClass} required />
              </label>
              <label className="block">
                <span className="text-sm text-gray-700">Порядок</span>
                <input type="number" min={0} value={form.sortOrder} onChange={(e) => set('sortOrder', Number(e.target.value) || 0)} className={inputClass} />
              </label>
            </div>
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" checked={form.isActive} onChange={(e) => set('isActive', e.target.checked)} />
              Показывать в приложении
            </label>
            {formError && <p className="text-sm text-red-600">{formError}</p>}
            <div className="flex gap-3">
              <button type="submit" disabled={saving} className="px-6 py-2 bg-primary text-white rounded-lg text-sm font-medium disabled:opacity-50">
                {saving ? 'Сохранение…' : 'Сохранить'}
              </button>
              <button type="button" onClick={() => setEditing(null)} className="px-6 py-2 bg-gray-100 text-gray-700 rounded-lg text-sm font-medium">
                Отмена
              </button>
            </div>
          </form>
        )}

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {promotions.map((p) => (
              <div key={p.id} className={`bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden ${p.isLive ? '' : 'opacity-70'}`}>
                {p.image && <img src={p.image} alt="" className="w-full aspect-[2/1] object-cover" />}
                <div className="p-4">
                  <div className="flex items-start justify-between gap-2 mb-2">
                    <h3 className="font-semibold">{p.titleRu || p.title}</h3>
                    <span className={`px-2 py-0.5 rounded-full text-xs whitespace-nowrap ${p.isLive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'}`}>
                      {p.isLive ? 'Идёт' : p.isActive ? 'Не в сроках' : 'Скрыта'}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 line-clamp-2 mb-3">{p.descriptionRu || p.description}</p>
                  <div className="flex items-center justify-between">
                    <span className="flex items-center gap-1 text-xs text-gray-500">
                      <Calendar size={14} />
                      {new Date(p.startDate).toLocaleDateString('ru-RU')} — {new Date(p.endDate).toLocaleDateString('ru-RU')}
                    </span>
                    <div className="flex gap-1">
                      <button onClick={() => openEdit(p)} className="p-2 text-gray-500 hover:text-primary hover:bg-primary/5 rounded-lg" aria-label="Редактировать">
                        <Edit size={16} />
                      </button>
                      <button onClick={() => remove(p)} className="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded-lg" aria-label="Удалить">
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
            {promotions.length === 0 && <p className="text-gray-500 col-span-full text-center py-12">Акций пока нет</p>}
          </div>
        )}
      </div>
    </div>
  );
};

export default PromotionsList;
