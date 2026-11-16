import React, { createContext, useContext, useEffect, useState } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import Sidebar from './Sidebar';
import { useAuthStore } from '../../store/authStore';

const SidebarContext = createContext<{ open: () => void }>({ open: () => undefined });

/** Lets the page header open the sidebar on narrow screens. */
export const useSidebar = () => useContext(SidebarContext);

const Layout: React.FC = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();
  const loadProfile = useAuthStore((s) => s.loadProfile);

  useEffect(() => {
    loadProfile();
  }, [loadProfile]);

  // Close the drawer after navigating on a tablet or phone
  useEffect(() => {
    setSidebarOpen(false);
  }, [location.pathname]);

  return (
    <SidebarContext.Provider value={{ open: () => setSidebarOpen(true) }}>
      <div className="min-h-screen bg-gray-50">
        <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
        <main className="lg:ml-64">
          <Outlet />
        </main>
      </div>
    </SidebarContext.Provider>
  );
};

export default Layout;
