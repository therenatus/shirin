import { create } from 'zustand';
import api from '../services/api';

interface AuthState {
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (phone: string, code: string) => Promise<void>;
  logout: () => void;
  checkAuth: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: localStorage.getItem('admin_token'),
  isAuthenticated: !!localStorage.getItem('admin_token'),
  isLoading: false,

  login: async (phone: string, code: string) => {
    set({ isLoading: true });
    try {
      // For test mode: phone 999999999, code 9999
      if (phone === '+996999999999' && code === '9999') {
        const testToken = 'admin-test-token';
        localStorage.setItem('admin_token', testToken);
        set({ token: testToken, isAuthenticated: true, isLoading: false });
        return;
      }
      const response = await api.post('/auth/verify-code', { phone, code });
      const { accessToken } = response.data;
      localStorage.setItem('admin_token', accessToken);
      set({ token: accessToken, isAuthenticated: true, isLoading: false });
    } catch (error) {
      set({ isLoading: false });
      throw error;
    }
  },

  logout: () => {
    localStorage.removeItem('admin_token');
    set({ token: null, isAuthenticated: false });
  },

  checkAuth: () => {
    const token = localStorage.getItem('admin_token');
    set({ isAuthenticated: !!token, token });
  },
}));
