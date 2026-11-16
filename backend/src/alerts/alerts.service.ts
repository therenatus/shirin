import { Injectable, Logger } from '@nestjs/common';

/** Same alert at most once per this interval (per process). */
const REPEAT_AFTER_MS = 10 * 60 * 1000;

/**
 * Operational alerts to a Telegram chat (failures someone must look at).
 *
 * ALERT_TELEGRAM_BOT_TOKEN: token from @BotFather
 * ALERT_TELEGRAM_CHAT_ID: chat or group id the bot may write to
 * Without them alerts are only logged.
 *
 * `key` groups repeats: the first alert with a key is sent, the same key is
 * then muted for 10 minutes and the next message says how many were muted.
 */
@Injectable()
export class AlertsService {
  private readonly logger = new Logger(AlertsService.name);
  private readonly lastSent = new Map<string, { at: number; muted: number }>();
  private readonly token = process.env.ALERT_TELEGRAM_BOT_TOKEN;
  private readonly chatId = process.env.ALERT_TELEGRAM_CHAT_ID;
  private readonly env =
    process.env.ALERT_ENV_NAME || process.env.NODE_ENV || 'dev';

  get enabled() {
    return !!(this.token && this.chatId);
  }

  async alert(key: string, message: string): Promise<void> {
    const now = Date.now();
    const prev = this.lastSent.get(key);
    if (prev && now - prev.at < REPEAT_AFTER_MS) {
      prev.muted++;
      return;
    }
    const muted = prev?.muted ?? 0;
    this.lastSent.set(key, { at: now, muted: 0 });

    const text =
      `⚠️ Shirin [${this.env}]\n${message}` +
      (muted > 0 ? `\n(ещё ${muted} таких за последние 10 мин)` : '');
    this.logger.warn(`ALERT ${key}: ${message}`);
    if (!this.enabled) return;

    try {
      const res = await fetch(
        `https://api.telegram.org/bot${this.token}/sendMessage`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            chat_id: this.chatId,
            text: text.slice(0, 4000),
          }),
          signal: AbortSignal.timeout(5000),
        },
      );
      if (!res.ok)
        this.logger.error(`Telegram alert failed: HTTP ${res.status}`);
    } catch (e) {
      // Alerts must never break the request that triggered them
      this.logger.error(`Telegram alert failed: ${(e as Error).message}`);
    }
  }
}
