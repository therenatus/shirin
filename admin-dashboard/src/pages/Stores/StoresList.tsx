import React, { useEffect, useState } from 'react';
import { Plus, Edit, Trash2, MapPin, Phone, Clock } from 'lucide-react';
import Header from '../../components/layout/Header';
import { Store } from '../../types';
import { StoreInput } from '../../services/mappers';
import api from '../../services/api';

const StoresList: React.FC = () => {
  const [stores, setStores] = useState<Store[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editingStore, setEditingStore] = useState<Store | null>(null);

  useEffect(() => {
    const fetchStores = async () => {
      try {
        const response = await api.get<Store[]>('/stores');
        setStores(response.data);
      } catch {
        setError('Не удалось загрузить магазины');
      } finally {
        setLoading(false);
      }
    };
    fetchStores();
  }, []);

  const handleDelete = async (id: string) => {
    if (!window.confirm('Удалить магазин?')) return;
    try {
      await api.delete(`/stores/${id}`);
      setStores((prev) => prev.filter((s) => s.id !== id));
    } catch {
      alert('Ошибка при удалении');
    }
  };

  const handleSave = async (data: StoreInput) => {
    try {
      if (editingStore) {
        const response = await api.patch<Store>(`/stores/${editingStore.id}`, data);
        setStores((prev) =>
          prev.map((s) => (s.id === editingStore.id ? response.data : s))
        );
      } else {
        const response = await api.post<Store>('/stores', data);
        setStores((prev) => [...prev, response.data]);
      }
      setShowForm(false);
      setEditingStore(null);
    } catch {
      alert('Ошибка при сохранении');
    }
  };

  return (
    <div>
      <Header title="Магазины" />
      <div className="p-8">
        <div className="flex items-center justify-between mb-6">
          <p className="text-sm text-gray-500">{stores.length} магазинов</p>
          <button
            onClick={() => { setEditingStore(null); setShowForm(true); }}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-dark transition-colors"
          >
            <Plus size={18} />
            Добавить магазин
          </button>
        </div>

        {showForm && (
          <StoreForm
            store={editingStore}
            onSave={handleSave}
            onCancel={() => { setShowForm(false); setEditingStore(null); }}
          />
        )}

        {error && <p className="text-red-500 text-sm mb-4">{error}</p>}

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {stores.map((store) => (
              <div key={store.id} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
                <div className="flex items-start justify-between mb-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-lg flex items-center justify-center">
                    <MapPin size={20} className="text-primary" />
                  </div>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => { setEditingStore(store); setShowForm(true); }}
                      className="p-1.5 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded"
                    >
                      <Edit size={14} />
                    </button>
                    <button
                      onClick={() => handleDelete(store.id)}
                      className="p-1.5 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </div>
                <h3 className="font-semibold text-gray-900">{store.name}</h3>
                <div className="mt-3 space-y-2 text-sm text-gray-500">
                  <div className="flex items-center gap-2">
                    <MapPin size={14} />
                    <span>{store.address}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Phone size={14} />
                    <span>{store.phone}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Clock size={14} />
                    <span>{store.workHours}</span>
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

interface StoreFormProps {
  store: Store | null;
  onSave: (data: StoreInput) => void;
  onCancel: () => void;
}

const inputClass =
  'px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary/20';

const StoreForm: React.FC<StoreFormProps> = ({ store, onSave, onCancel }) => {
  const [name, setName] = useState(store?.name || '');
  const [address, setAddress] = useState(store?.address || '');
  const [phone, setPhone] = useState(store?.phone || '');
  const [workHours, setWorkHours] = useState(store?.workHours || '');
  const [latitude, setLatitude] = useState(store?.latitude?.toString() || '');
  const [longitude, setLongitude] = useState(store?.longitude?.toString() || '');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave({
      name,
      address,
      phone,
      workHours,
      latitude: Number(latitude),
      longitude: Number(longitude),
    });
  };

  return (
    <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 mb-6">
      <h3 className="font-semibold mb-4">{store ? 'Редактировать магазин' : 'Новый магазин'}</h3>
      <form onSubmit={handleSubmit} className="space-y-3">
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Название"
          className={`w-full ${inputClass}`}
          required
        />
        <input
          value={address}
          onChange={(e) => setAddress(e.target.value)}
          placeholder="Адрес"
          className={`w-full ${inputClass}`}
          required
        />
        <div className="grid grid-cols-2 gap-3">
          <input
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="Телефон"
            className={inputClass}
            required
          />
          <input
            value={workHours}
            onChange={(e) => setWorkHours(e.target.value)}
            placeholder="Режим работы (08:00 - 21:00)"
            className={inputClass}
            required
          />
          <input
            type="number"
            step="any"
            min={-90}
            max={90}
            value={latitude}
            onChange={(e) => setLatitude(e.target.value)}
            placeholder="Широта (42.8746)"
            className={inputClass}
            required
          />
          <input
            type="number"
            step="any"
            min={-180}
            max={180}
            value={longitude}
            onChange={(e) => setLongitude(e.target.value)}
            placeholder="Долгота (74.5698)"
            className={inputClass}
            required
          />
        </div>
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

export default StoresList;
