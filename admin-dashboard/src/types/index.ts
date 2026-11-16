export type UserRole = 'CLIENT' | 'ADMIN' | 'SUPPORT' | 'STORE_STAFF';

/** Roles allowed into the dashboard. */
export type StaffRole = Exclude<UserRole, 'CLIENT'>;

export interface User {
  id: string;
  phone: string;
  firstName?: string;
  lastName?: string;
  loyaltyPoints: number;
  role: UserRole;
  createdAt: string;
}

/** User row on the staff page (`GET /users/admin/staff`). */
export interface StaffMember {
  id: string;
  phone: string;
  firstName?: string | null;
  lastName?: string | null;
  role: UserRole;
  isActive: boolean;
  store: { id: string; name: string } | null;
}

export interface Category {
  id: string;
  name: string;
  nameRu: string;
  nameKy?: string;
  imageUrl?: string;
}

export interface Product {
  id: string;
  name: string;
  nameRu: string;
  nameKy?: string;
  description?: string;
  descriptionRu?: string;
  descriptionKy?: string;
  price: number;
  imageUrl?: string;
  categoryId: string;
  category?: Category;
  isAvailable: boolean;
  createdAt: string;
}

export interface OrderItem {
  id: string;
  productId: string;
  name: string;
  price: number;
  quantity: number;
  imageUrl?: string;
}

export type OrderStatus =
  | 'pending'
  | 'confirmed'
  | 'preparing'
  | 'ready'
  | 'delivering'
  | 'delivered'
  | 'cancelled';

export interface Order {
  id: string;
  orderNumber?: string;
  userId: string;
  userPhone?: string;
  user?: User;
  customerName?: string;
  deliveryType?: 'delivery' | 'pickup';
  status: OrderStatus;
  /** Statuses the server allows next (cancel included). */
  nextStatuses: OrderStatus[];
  items: OrderItem[];
  totalSum: number;
  address?: string;
  /** Store that fulfils the order; null for an unassigned delivery order. */
  store: { id: string; name: string; address: string } | null;
  comment?: string | null;
  deliveryTime?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface Promotion {
  id: string;
  title: string;
  titleRu: string;
  description: string;
  descriptionRu: string;
  imageUrl?: string;
  startDate: string;
  endDate: string;
  isActive: boolean;
  createdAt: string;
}

export interface Store {
  id: string;
  name: string;
  address: string;
  phone: string;
  latitude: number;
  longitude: number;
  workHours: string;
}

export type CoffeeSize = 'S' | 'M' | 'L';

export interface PunchCard {
  id: string;
  size: CoffeeSize;
  sizeName: string;
  currentPunches: number;
  maxPunches: number;
  isComplete: boolean;
}

export interface StaffCustomer {
  id: string;
  phone: string;
  firstName?: string | null;
  lastName?: string | null;
  loyaltyPoints: number;
  level: string;
  punchCards: PunchCard[];
}

export interface DashboardStats {
  todaySales: number;
  totalOrders: number;
  activeCustomers: number;
  averageOrderValue: number;
  salesChart: { date: string; amount: number }[];
  recentOrders: Order[];
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
}
