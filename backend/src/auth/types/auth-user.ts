import { UserRole } from '@prisma/client';

/** The authenticated user attached to the request by JwtStrategy. */
export interface AuthUser {
  id: string;
  phone: string;
  role: UserRole;
  /** Store the employee works in; set only for STORE_STAFF. */
  storeId: string | null;
}
