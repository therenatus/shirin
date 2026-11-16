import { create } from 'zustand';
import api, { tokenStorage } from '../services/api';

export type StaffRole = 'ADMIN' | 'SUPPORT';
const STAFF_ROLES: string[] = ['ADMIN', 'SUPPORT'];

export class AccessDeniedError extends Error {
  constructor() {
    super('Нет доступа к панели управления');
  }
}

interface AuthState {
  token: string | null;
  role: StaffRole | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  sendCode: (phone: string) => Promise<void>;
  login: (phone: string, code: string) => Promise<void>;
  logout: () => void;
  checkAuth: () => void;
}

const storedRole = () => localStorage.getItem('admin_role') as StaffRole | null;

export const useAuthStore = create<AuthState>((set) => ({
  token: tokenStorage.getAccess(),
  role: storedRole(),
  isAuthenticated: !!tokenStorage.getAccess(),
  isLoading: false,

  sendCode: async (phone: string) => {
    set({ isLoading: true });
    try {
      await api.post('/auth/send-code', { phone });
    } finally {
      set({ isLoading: false });
    }
  },

  login: async (phone: string, code: string) => {
    set({ isLoading: true });
    try {
      const response = await api.post('/auth/verify-code', { phone, code });
      const { accessToken, refreshToken, user } = response.data;

      if (!STAFF_ROLES.includes(user?.role)) {
        // Revoke the session we just got: this user is not staff
        await api
          .post('/auth/logout', { refreshToken }, {
            headers: { Authorization: `Bearer ${accessToken}` },
          })
          .catch(() => undefined);
        throw new AccessDeniedError();
      }

      tokenStorage.set(accessToken, refreshToken);
      localStorage.setItem('admin_role', user.role);
      set({ token: accessToken, role: user.role, isAuthenticated: true });
    } finally {
      set({ isLoading: false });
    }
  },

  logout: () => {
    const refreshToken = tokenStorage.getRefresh();
    if (refreshToken) {
      api.post('/auth/logout', { refreshToken }).catch(() => undefined);
    }
    tokenStorage.clear();
    localStorage.removeItem('admin_role');
    set({ token: null, role: null, isAuthenticated: false });
  },

  checkAuth: () => {
    const token = tokenStorage.getAccess();
    set({ isAuthenticated: !!token, token, role: storedRole() });
  },
}));
