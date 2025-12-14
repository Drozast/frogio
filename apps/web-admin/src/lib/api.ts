const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
const TENANT_ID = process.env.NEXT_PUBLIC_TENANT_ID || 'santa_juana';

interface FetchOptions extends Omit<RequestInit, 'headers'> {
  token?: string;
}

export async function apiRequest<T>(
  endpoint: string,
  options: FetchOptions = {}
): Promise<T> {
  const { token, ...fetchOptions } = options;

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  // Add tenant header for auth endpoints
  if (endpoint.startsWith('/auth/')) {
    headers['X-Tenant-ID'] = TENANT_ID;
  }

  const response = await fetch(`${API_URL}/api${endpoint}`, {
    ...fetchOptions,
    headers,
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Error desconocido' }));
    throw new Error(error.error || `HTTP ${response.status}`);
  }

  return response.json();
}

// Auth API
export const authApi = {
  login: (email: string, password: string) =>
    apiRequest<{
      user: any;
      accessToken: string;
      refreshToken: string;
    }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  register: (data: any) =>
    apiRequest('/auth/register', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  me: (token: string) =>
    apiRequest('/auth/me', { token }),
};

// Reports API
export const reportsApi = {
  getAll: (token: string, params?: any) => {
    const query = params ? `?${new URLSearchParams(params)}` : '';
    return apiRequest(`/reports${query}`, { token });
  },

  getById: (token: string, id: string) =>
    apiRequest(`/reports/${id}`, { token }),

  create: (token: string, data: any) =>
    apiRequest('/reports', {
      method: 'POST',
      token,
      body: JSON.stringify(data),
    }),

  update: (token: string, id: string, data: any) =>
    apiRequest(`/reports/${id}`, {
      method: 'PATCH',
      token,
      body: JSON.stringify(data),
    }),

  delete: (token: string, id: string) =>
    apiRequest(`/reports/${id}`, {
      method: 'DELETE',
      token,
    }),
};

// Infractions API
export const infractionsApi = {
  getAll: (token: string, params?: any) => {
    const query = params ? `?${new URLSearchParams(params)}` : '';
    return apiRequest(`/infractions${query}`, { token });
  },

  getStats: (token: string) =>
    apiRequest('/infractions/stats', { token }),

  getById: (token: string, id: string) =>
    apiRequest(`/infractions/${id}`, { token }),

  create: (token: string, data: any) =>
    apiRequest('/infractions', {
      method: 'POST',
      token,
      body: JSON.stringify(data),
    }),

  update: (token: string, id: string, data: any) =>
    apiRequest(`/infractions/${id}`, {
      method: 'PATCH',
      token,
      body: JSON.stringify(data),
    }),
};

// Vehicles API
export const vehiclesApi = {
  getAll: (token: string) =>
    apiRequest('/vehicles', { token }),

  search: (token: string, plate: string) =>
    apiRequest(`/vehicles/plate/${plate}`, { token }),

  create: (token: string, data: any) =>
    apiRequest('/vehicles', {
      method: 'POST',
      token,
      body: JSON.stringify(data),
    }),
};

// Notifications API
export const notificationsApi = {
  getAll: (token: string) =>
    apiRequest('/notifications', { token }),

  getUnreadCount: (token: string) =>
    apiRequest('/notifications/unread/count', { token }),

  markAsRead: (token: string, id: string) =>
    apiRequest(`/notifications/${id}/read`, {
      method: 'PATCH',
      token,
    }),
};
