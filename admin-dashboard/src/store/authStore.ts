import { create } from 'zustand';
import api, { tokenStorage } from '../services/api';
import { StaffRole } from '../types';

export type { StaffRole };
const STAFF_ROLES: string[] = ['ADMIN', 'SUPPORT', 'STORE_STAFF'];

/** Where each role lands after login and when opening a forbidden page. */
export const HOME_BY_ROLE: Record<StaffRole, string> = {
  ADMIN: '/',
  STORE_STAFF: '/orders',
  SUPPORT: '/loyalty',
};

export interface StaffProfile {
  name: string;
  store: { id: string; name: string } | null;
}

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
  profile: StaffProfile | null;
  loadProfile: () => Promise<void>;
  sendCode: (phone: string) => Promise<void>;
  login: (phone: string, code: string) => Promise<void>;
  logout: () => void;
  checkAuth: () => void;
}

const storedRole = () => localStorage.getItem('admin_role') as StaffRole | null;

export const useAuthStore = create<AuthState>((set, get) => ({
  token: tokenStorage.getAccess(),
  role: storedRole(),
  isAuthenticated: !!tokenStorage.getAccess(),
  isLoading: false,
  profile: null,

  loadProfile: async () => {
    try {
      const { data } = await api.get('/users/me');
      if (!STAFF_ROLES.includes(data.role)) {
        // Access was revoked by an admin
        get().logout();
        return;
      }
      const name = [data.firstName, data.lastName].filter(Boolean).join(' ');
      set({
        profile: { name: name || data.phone, store: data.store ?? null },
        // The role may have been changed by an admin since login
        role: data.role,
      });
      localStorage.setItem('admin_role', data.role);
    } catch {
      // Not critical: the header falls back to the role name
    }
  },

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
    set({ token: null, role: null, profile: null, isAuthenticated: false });
  },

  checkAuth: () => {
    const token = tokenStorage.getAccess();
    set({ isAuthenticated: !!token, token, role: storedRole() });
  },
}));
