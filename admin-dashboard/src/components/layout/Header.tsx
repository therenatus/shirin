import React from 'react';
import { Menu } from 'lucide-react';
import { useAuthStore } from '../../store/authStore';
import { roleLabels } from '../../constants/orders';
import { useSidebar } from './Layout';

interface HeaderProps {
  title: string;
  /** Optional controls shown before the user badge (e.g. sound toggle). */
  actions?: React.ReactNode;
}

const Header: React.FC<HeaderProps> = ({ title, actions }) => {
  const { open } = useSidebar();
  const role = useAuthStore((s) => s.role);
  const profile = useAuthStore((s) => s.profile);

  const name = profile?.name || (role ? roleLabels[role] : '');
  const subtitle = profile?.store?.name ?? (role ? roleLabels[role] : '');

  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between gap-3 px-4 lg:px-8">
      <div className="flex items-center gap-2 min-w-0">
        <button
          onClick={open}
          className="lg:hidden p-2 -ml-2 text-gray-600 hover:bg-gray-100 rounded-lg"
          aria-label="Открыть меню"
        >
          <Menu size={22} />
        </button>
        <h2 className="text-lg lg:text-xl font-semibold text-gray-900 truncate">{title}</h2>
      </div>
      <div className="flex items-center gap-3 shrink-0">
        {actions}
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center">
            <span className="text-sm font-medium text-primary">{name.charAt(0) || '·'}</span>
          </div>
          <div className="hidden sm:block leading-tight">
            <p className="text-sm font-medium text-gray-700">{name}</p>
            {subtitle && subtitle !== name && (
              <p className="text-xs text-gray-500">{subtitle}</p>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
