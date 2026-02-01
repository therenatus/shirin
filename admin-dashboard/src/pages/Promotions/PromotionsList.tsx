import React, { useEffect, useState } from 'react';
import { Plus, Edit, Trash2, Calendar } from 'lucide-react';
import Header from '../../components/layout/Header';
import { Promotion } from '../../types';
import { getMockPromotions, isTestMode } from '../../services/mockData';
import api from '../../services/api';

const PromotionsList: React.FC = () => {
  const [promotions, setPromotions] = useState<Promotion[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingPromo, setEditingPromo] = useState<Promotion | null>(null);

  useEffect(() => {
    const fetchPromotions = async () => {
      try {
        if (isTestMode()) {
          setPromotions(getMockPromotions());
        } else {
          const response = await api.get('/promotions');
          setPromotions(response.data);
        }
      } catch {
        setPromotions(getMockPromotions());
      } finally {
        setLoading(false);
      }
    };
    fetchPromotions();
  }, []);

  const handleDelete = async (id: string) => {
    if (!window.confirm('Удалить акцию?')) return;
    try {
      if (!isTestMode()) {
        await api.delete(`/promotions/${id}`);
      }
      setPromotions((prev) => prev.filter((p) => p.id !== id));
    } catch {
      alert('Ошибка при удалении');
    }
  };

  const handleSave = async (data: { titleRu: string; descriptionRu: string; endDate: string }) => {
    try {
      if (editingPromo) {
        if (!isTestMode()) {
          await api.put(`/promotions/${editingPromo.id}`, data);
        }
        setPromotions((prev) =>
          prev.map((p) =>
            p.id === editingPromo.id ? { ...p, titleRu: data.titleRu, descriptionRu: data.descriptionRu, endDate: data.endDate } : p
          )
        );
      } else {
        const newPromo: Promotion = {
          id: `promo-${Date.now()}`,
          title: data.titleRu,
          titleRu: data.titleRu,
          description: data.descriptionRu,
          descriptionRu: data.descriptionRu,
          startDate: new Date().toISOString(),
          endDate: data.endDate,
          isActive: true,
          createdAt: new Date().toISOString(),
        };
        if (!isTestMode()) {
          const response = await api.post('/promotions', data);
          newPromo.id = response.data.id;
        }
        setPromotions((prev) => [newPromo, ...prev]);
      }
      setShowForm(false);
      setEditingPromo(null);
    } catch {
      alert('Ошибка при сохранении');
    }
  };

  return (
    <div>
      <Header title="Акции" />
      <div className="p-8">
        <div className="flex items-center justify-between mb-6">
          <p className="text-sm text-gray-500">{promotions.length} акций</p>
          <button
            onClick={() => { setEditingPromo(null); setShowForm(true); }}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-dark transition-colors"
          >
            <Plus size={18} />
            Новая акция
          </button>
        </div>

        {showForm && (
          <PromotionForm
            promotion={editingPromo}
            onSave={handleSave}
            onCancel={() => { setShowForm(false); setEditingPromo(null); }}
          />
        )}

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {promotions.map((promo) => (
              <div key={promo.id} className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="h-32 bg-gradient-to-br from-primary/80 to-primary-light/60 flex items-center justify-center">
                  <Calendar size={32} className="text-white/80" />
                </div>
                <div className="p-4">
                  <h3 className="font-semibold text-gray-900">{promo.titleRu}</h3>
                  <p className="text-sm text-gray-500 mt-1 line-clamp-2">{promo.descriptionRu}</p>
                  <div className="mt-3 flex items-center justify-between">
                    <span className="text-xs text-gray-400">
                      до {new Date(promo.endDate).toLocaleDateString('ru-RU')}
                    </span>
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => { setEditingPromo(promo); setShowForm(true); }}
                        className="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded"
                      >
                        <Edit size={14} />
                      </button>
                      <button
                        onClick={() => handleDelete(promo.id)}
                        className="p-1.5 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

interface PromotionFormProps {
  promotion: Promotion | null;
  onSave: (data: { titleRu: string; descriptionRu: string; endDate: string }) => void;
  onCancel: () => void;
}

const PromotionForm: React.FC<PromotionFormProps> = ({ promotion, onSave, onCancel }) => {
  const [titleRu, setTitleRu] = useState(promotion?.titleRu || '');
  const [descriptionRu, setDescriptionRu] = useState(promotion?.descriptionRu || '');
  const [endDate, setEndDate] = useState(promotion?.endDate?.split('T')[0] || '');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!titleRu || !endDate) return;
    onSave({ titleRu, descriptionRu, endDate: new Date(endDate).toISOString() });
  };

  return (
    <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 mb-6">
      <h3 className="font-semibold mb-4">{promotion ? 'Редактировать акцию' : 'Новая акция'}</h3>
      <form onSubmit={handleSubmit} className="space-y-3">
        <input
          value={titleRu}
          onChange={(e) => setTitleRu(e.target.value)}
          placeholder="Название акции"
          className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
          required
        />
        <textarea
          value={descriptionRu}
          onChange={(e) => setDescriptionRu(e.target.value)}
          placeholder="Описание"
          rows={3}
          className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 resize-none"
        />
        <input
          type="date"
          value={endDate}
          onChange={(e) => setEndDate(e.target.value)}
          className="px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
          required
        />
        <div className="flex gap-2">
          <button type="submit" className="px-4 py-2 bg-primary text-white text-sm rounded-lg hover:bg-primary-dark">
            Сохранить
          </button>
          <button type="button" onClick={onCancel} className="px-4 py-2 bg-gray-100 text-gray-700 text-sm rounded-lg hover:bg-gray-200">
            Отмена
          </button>
        </div>
      </form>
    </div>
  );
};

export default PromotionsList;
