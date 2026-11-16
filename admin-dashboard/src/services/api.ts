import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000/api/v1';

export const tokenStorage = {
  getAccess: () => localStorage.getItem('admin_token'),
  getRefresh: () => localStorage.getItem('admin_refresh_token'),
  set: (access: string, refresh: string) => {
    localStorage.setItem('admin_token', access);
    localStorage.setItem('admin_refresh_token', refresh);
  },
  clear: () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_refresh_token');
  },
};

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  const token = tokenStorage.getAccess();
  if (token && !config.headers.Authorization) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Single in-flight refresh shared by concurrent 401 responses
let refreshPromise: Promise<string> | null = null;

const refreshAccessToken = async (): Promise<string> => {
  const refreshToken = tokenStorage.getRefresh();
  if (!refreshToken) throw new Error('No refresh token');
  const { data } = await axios.post(`${API_URL}/auth/refresh`, { refreshToken });
  tokenStorage.set(data.accessToken, data.refreshToken);
  return data.accessToken;
};

const AUTH_PATHS = ['/auth/verify-code', '/auth/send-code', '/auth/refresh'];

api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const original = error.config as (InternalAxiosRequestConfig & { _retry?: boolean }) | undefined;
    const isAuthCall = AUTH_PATHS.some((p) => original?.url?.includes(p));

    if (error.response?.status === 401 && original && !original._retry && !isAuthCall) {
      original._retry = true;
      try {
        refreshPromise ??= refreshAccessToken().finally(() => {
          refreshPromise = null;
        });
        const newToken = await refreshPromise;
        original.headers.Authorization = `Bearer ${newToken}`;
        return api(original);
      } catch {
        tokenStorage.clear();
        localStorage.removeItem('admin_role');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export default api;
