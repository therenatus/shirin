import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { App, cert, initializeApp } from 'firebase-admin/app';
import { getMessaging, Messaging } from 'firebase-admin/messaging';
import { PrismaService } from '../prisma/prisma.service';

export type NotificationType = 'order_status' | 'payment' | 'loyalty' | 'promo';

export interface NotifyInput {
  title: string;
  body: string;
  type: NotificationType;
  /** Small string map delivered with the push; e.g. { orderId } for deep links. */
  data?: Record<string, string>;
}

/** FCM errors meaning the device token will never work again. */
const DEAD_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/**
 * Customer notifications: every notification is stored (the app shows the
 * list) and, when Firebase is configured, also sent as a push.
 *
 * Push is enabled by FIREBASE_SERVICE_ACCOUNT_BASE64 (the service account
 * JSON from the Firebase console, base64-encoded). Without it notifications
 * are only stored.
 *
 * Call it after the change is committed; it never throws, so a failed push
 * can't break an order.
 */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly messaging: Messaging | null;

  constructor(private prisma: PrismaService) {
    this.messaging = this.initFirebase();
  }

  private initFirebase(): Messaging | null {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
    if (!raw) {
      this.logger.warn(
        'Push disabled: FIREBASE_SERVICE_ACCOUNT_BASE64 is not set',
      );
      return null;
    }
    try {
      const account = JSON.parse(Buffer.from(raw, 'base64').toString('utf8'));
      const app: App = initializeApp(
        { credential: cert(account) },
        'shirin-push',
      );
      return getMessaging(app);
    } catch (e) {
      this.logger.error(
        `Push disabled: invalid Firebase credentials (${(e as Error).message})`,
      );
      return null;
    }
  }

  get pushEnabled() {
    return this.messaging !== null;
  }

  async notify(userId: string, input: NotifyInput): Promise<void> {
    try {
      await this.prisma.notification.create({
        data: {
          userId,
          title: input.title,
          body: input.body,
          type: input.type,
          data: input.data ? JSON.stringify(input.data) : null,
        },
      });
      await this.push(userId, input);
    } catch (e) {
      this.logger.error(
        `Notification for ${userId} failed: ${(e as Error).message}`,
      );
    }
  }

  private async push(userId: string, input: NotifyInput) {
    if (!this.messaging) return;
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true, isActive: true },
    });
    if (!user?.fcmToken || !user.isActive) return;

    try {
      await this.messaging.send({
        token: user.fcmToken,
        notification: { title: input.title, body: input.body },
        data: { type: input.type, ...(input.data ?? {}) },
        apns: { payload: { aps: { sound: 'default' } } },
        android: { priority: 'high', notification: { sound: 'default' } },
      });
    } catch (e) {
      const code = (e as { code?: string }).code ?? '';
      if (DEAD_TOKEN_CODES.has(code)) {
        // The app was uninstalled or the token rotated: stop sending to it
        await this.prisma.user.updateMany({
          where: { id: userId, fcmToken: user.fcmToken },
          data: { fcmToken: null },
        });
        return;
      }
      throw e;
    }
  }

  // ==================== CUSTOMER API ====================

  async list(userId: string, page = 1, limit = 30) {
    const [rows, total, unread] = await this.prisma.$transaction([
      this.prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.notification.count({ where: { userId } }),
      this.prisma.notification.count({ where: { userId, isRead: false } }),
    ]);
    return {
      data: rows.map((n) => ({
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        data: n.data ? (JSON.parse(n.data) as Record<string, string>) : null,
        isRead: n.isRead,
        createdAt: n.createdAt,
      })),
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        unread,
      },
    };
  }

  async unreadCount(userId: string) {
    const unread = await this.prisma.notification.count({
      where: { userId, isRead: false },
    });
    return { unread };
  }

  async markRead(userId: string, id: string) {
    const { count } = await this.prisma.notification.updateMany({
      where: { id, userId },
      data: { isRead: true },
    });
    if (count === 0) throw new NotFoundException('Notification not found');
    return { success: true };
  }

  async markAllRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
    return { success: true };
  }
}
