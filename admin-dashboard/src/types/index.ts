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
  isPreorder?: boolean;
  createdAt: string;
}

export interface OrderItem {
  id: string;
  productId: string;
  name: string;
  price: number;
  quantity: number;
  imageUrl?: string;
  inscription?: string | null;
  wishes?: string | null;
  referencePhotoUrl?: string | null;
}

export type PaymentStatus = 'NOT_REQUIRED' | 'PENDING' | 'PAID' | 'REFUND_PENDING' | 'REFUNDED';

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
  paymentStatus: PaymentStatus;
  prepaymentAmount: number;
  paymentDueAt?: string | null;
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
  cashbackPercent: number;
  maxPointsUsePercent: number;
  /** True when found by the live QR from the app (required to spend points). */
  canRedeem: boolean;
  /** Permanent customer code, used for crediting and coffee after a debit. */
  customerCode: string;
}

export type LoyaltyTxType = 'EARN' | 'REDEEM' | 'REFUND' | 'ADJUST' | 'REVERSAL' | 'FREE_COFFEE';
export type LoyaltyTxSource = 'APP_ORDER' | 'IN_STORE' | 'ONE_C' | 'MANUAL';

interface PersonRef {
  id: string;
  phone: string;
  firstName?: string | null;
  lastName?: string | null;
}

/** Row of `GET /loyalty/staff/transactions`. */
export interface LoyaltyTransaction {
  id: string;
  type: LoyaltyTxType;
  source: LoyaltyTxSource;
  points: number;
  balanceAfter: number | null;
  description: string | null;
  receiptNumber: string | null;
  receiptAmount: number | null;
  createdAt: string;
  reversalOfId: string | null;
  isReversed: boolean;
  user: PersonRef;
  staff: PersonRef | null;
  store: { id: string; name: string } | null;
  order: { id: string; orderNumber: string } | null;
}

export interface LoyaltyReport {
  data: LoyaltyTransaction[];
  totals: { type: LoyaltyTxType; count: number; points: number; receiptAmount: number }[];
  meta: { page: number; limit: number; total: number; totalPages: number };
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
