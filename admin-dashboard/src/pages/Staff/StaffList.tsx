import React, { useCallback, useEffect, useState } from 'react';
import { Search } from 'lucide-react';
import Header from '../../components/layout/Header';
import { StaffMember, Store, UserRole } from '../../types';
import { roleLabels } from '../../constants/orders';
import api from '../../services/api';

const ROLES: UserRole[] = ['STORE_STAFF', 'SUPPORT', 'ADMIN', 'CLIENT'];

const errorMessage = (err: any, fallback: string) => {
  const message = err?.response?.data?.message;
  return Array.isArray(message) ? message.join(', ') : message || fallback;
};

interface RowProps {
  member: StaffMember;
  stores: Store[];
  onSaved: (member: StaffMember) => void;
}

/** One user with editable role and store; saves only on explicit click. */
const StaffRow: React.FC<RowProps> = ({ member, stores, onSaved }) => {
  const [role, setRole] = useState<UserRole>(member.role);
  const [storeId, setStoreId] = useState(member.store?.id ?? '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const dirty = role !== member.role || (role === 'STORE_STAFF' && storeId !== (member.store?.id ?? ''));
  const missingStore = role === 'STORE_STAFF' && !storeId;

  const save = async () => {
    setSaving(true);
    setError('');
    try {
      const { data } = await api.patch<StaffMember>(`/users/admin/${member.id}/role`, {
        role,
        storeId: role === 'STORE_STAFF' ? storeId : undefined,
      });
      onSaved(data);
    } catch (err: any) {
      setError(errorMessage(err, 'Не удалось сохранить'));
    } finally {
      setSaving(false);
    }
  };

  const name = [member.firstName, member.lastName].filter(Boolean).join(' ');

  return (
    <tr className="border-t border-gray-50 align-top">
      <td className="px-4 py-4">
        <p className="font-medium">{name || '—'}</p>
        <p className="text-xs text-gray-500">{member.phone}</p>
        {!member.isActive && <p className="text-xs text-red-600">Заблокирован</p>}
      </td>
      <td className="px-4 py-4">
        <select
          value={role}
          onChange={(e) => setRole(e.target.value as UserRole)}
          className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm"
        >
          {ROLES.map((r) => (
            <option key={r} value={r}>{roleLabels[r]}</option>
          ))}
        </select>
      </td>
      <td className="px-4 py-4">
        {role === 'STORE_STAFF' ? (
          <select
            value={storeId}
            onChange={(e) => setStoreId(e.target.value)}
            className={`w-full px-3 py-2 border rounded-lg text-sm ${
              missingStore ? 'border-orange-300' : 'border-gray-200'
            }`}
          >
            <option value="">Выберите точку</option>
            {stores.map((s) => (
              <option key={s.id} value={s.id}>{s.name}</option>
            ))}
          </select>
        ) : (
          <span className="text-gray-400 text-sm">—</span>
        )}
      </td>
      <td className="px-4 py-4">
        <button
          onClick={save}
          disabled={!dirty || missingStore || saving}
          className="px-4 py-2 bg-primary text-white text-sm rounded-lg disabled:opacity-40"
        >
          {saving ? 'Сохранение…' : 'Сохранить'}
        </button>
        {error && <p className="mt-2 text-xs text-red-600">{error}</p>}
      </td>
    </tr>
  );
};

const StaffList: React.FC = () => {
  const [members, setMembers] = useState<StaffMember[]>([]);
  const [stores, setStores] = useState<Store[]>([]);
  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    api
      .get<Store[]>('/stores')
      .then((res) => setStores(res.data))
      .catch(() => setStores([]));
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      // Without a search show employees; with one, search every user so a
      // client can be promoted to staff by phone
      const { data } = await api.get<StaffMember[]>('/users/admin/staff', {
        params: query ? { search: query, staffOnly: false } : undefined,
      });
      setMembers(data);
    } catch (err: any) {
      setError(errorMessage(err, 'Не удалось загрузить сотрудников'));
    } finally {
      setLoading(false);
    }
  }, [query]);

  useEffect(() => {
    load();
  }, [load]);

  const onSaved = (saved: StaffMember) =>
    setMembers((list) => list.map((m) => (m.id === saved.id ? saved : m)));

  return (
    <div>
      <Header title="Сотрудники" />
      <div className="p-4 lg:p-8">
        <form
          onSubmit={(e) => {
            e.preventDefault();
            setQuery(search.trim());
          }}
          className="flex flex-wrap items-center gap-3 mb-2"
        >
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input
              type="text"
              placeholder="Телефон или имя"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-10 pr-4 py-2 border border-gray-200 rounded-lg text-sm w-64"
            />
          </div>
          <button type="submit" className="px-4 py-2 bg-primary text-white text-sm rounded-lg">
            Найти
          </button>
          {query && (
            <button
              type="button"
              onClick={() => {
                setSearch('');
                setQuery('');
              }}
              className="px-4 py-2 text-sm text-gray-600"
            >
              Показать сотрудников
            </button>
          )}
        </form>
        <p className="text-xs text-gray-500 mb-6">
          Чтобы добавить сотрудника, он должен один раз войти в приложение или панель по своему номеру.
          Затем найдите его по телефону и назначьте роль.
        </p>

        {error && <p className="text-red-500 text-sm mb-4">{error}</p>}

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin w-8 h-8 border-4 border-primary border-t-transparent rounded-full" />
          </div>
        ) : (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-x-auto">
            <table className="w-full text-sm min-w-[640px]">
              <thead>
                <tr className="bg-gray-50 text-left text-gray-500">
                  <th className="px-4 py-3 font-medium">Пользователь</th>
                  <th className="px-4 py-3 font-medium">Роль</th>
                  <th className="px-4 py-3 font-medium">Точка</th>
                  <th className="px-4 py-3 font-medium" aria-label="Действия" />
                </tr>
              </thead>
              <tbody>
                {members.map((m) => (
                  <StaffRow key={`${m.id}-${m.role}-${m.store?.id ?? ''}`} member={m} stores={stores} onSaved={onSaved} />
                ))}
              </tbody>
            </table>
            {members.length === 0 && (
              <div className="text-center py-12 text-gray-500">
                {query ? 'Никого не нашли' : 'Сотрудников пока нет'}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default StaffList;
