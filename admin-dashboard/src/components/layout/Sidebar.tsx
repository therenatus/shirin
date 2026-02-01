import React from 'react';
import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Package, ShoppingCart, Users, Tag, MapPin, LogOut } from 'lucide-react';
import { useAuthStore } from '../../store/authStore';

const navItems = [
  { path: '/', icon: LayoutDashboard, label: 'Дашборд' },
  { path: '/products', icon: Package, label: 'Товары' },
  { path: '/orders', icon: ShoppingCart, label: 'Заказы' },
  { path: '/users', icon: Users, label: 'Клиенты' },
  { path: '/promotions', icon: Tag, label: 'Акции' },
  { path: '/stores', icon: MapPin, label: 'Магазины' },
];

const Sidebar: React.FC = () => {
  const logout = useAuthStore((s) => s.logout);

  return (
    <aside className="fixed left-0 top-0 h-screen w-64 bg-white border-r border-gray-200 flex flex-col">
      <div className="p-6 border-b border-gray-100">
        <h1 className="text-2xl font-bold text-primary">Ширин</h1>
        <p className="text-xs text-gray-500 mt-1">Панель управления</p>
      </div>

      <nav className="flex-1 py-4 px-3">
        {navItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            end={item.path === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-lg mb-1 text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-primary/10 text-primary'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              }`
            }
          >
            <item.icon size={20} />
            {item.label}
          </NavLink>
        ))}
      </nav>

      <div className="p-3 border-t border-gray-100">
        <button
          onClick={logout}
          className="flex items-center gap-3 w-full px-4 py-3 rounded-lg text-sm font-medium text-gray-600 hover:bg-red-50 hover:text-red-600 transition-colors"
        >
          <LogOut size={20} />
          Выйти
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
