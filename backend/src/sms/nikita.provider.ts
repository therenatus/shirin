import { randomUUID } from 'crypto';

/**
 * SMSPRO (Nikita, smspro.nikita.kg) — SMS gateway in Kyrgyzstan.
 *
 * IMPORTANT: the request format below follows the provider's commonly used
 * XML API (POST <message> with login/pwd/id/sender/text/phones) but was NOT
 * checked against an official specification: it is not published openly and
 * is issued in the customer account. Before going live, compare `buildXml`,
 * the URL and `parseStatus` with that document and send one test SMS.
 */
export interface NikitaConfig {
  login: string;
  password: string;
  /** Sender name approved by the provider (e.g. "SHIRIN"). */
  sender: string;
  url: string;
  /** Provider test mode: accepted but not delivered (and not billed). */
  test: boolean;
}

export const NIKITA_DEFAULT_URL = 'https://smspro.nikita.kg/api/message';

const escapeXml = (s: string) =>
  s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');

/** +996 700 123 456 -> 996700123456 */
export const toProviderPhone = (phone: string) => phone.replace(/\D/g, '');

export function buildNikitaXml(
  config: NikitaConfig,
  phone: string,
  text: string,
  id: string = randomUUID().replace(/-/g, '').slice(0, 12),
): string {
  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<message>',
    `<login>${escapeXml(config.login)}</login>`,
    `<pwd>${escapeXml(config.password)}</pwd>`,
    `<id>${escapeXml(id)}</id>`,
    `<sender>${escapeXml(config.sender)}</sender>`,
    `<text>${escapeXml(text)}</text>`,
    `<phones><phone>${toProviderPhone(phone)}</phone></phones>`,
    config.test ? '<test>1</test>' : '',
    '</message>',
  ].join('');
}

/** Status code from the provider's XML response; 0 means accepted. */
export function parseNikitaStatus(xml: string): number | null {
  const match = xml.match(/<status>\s*(-?\d+)\s*<\/status>/i);
  return match ? Number(match[1]) : null;
}

export async function sendViaNikita(
  config: NikitaConfig,
  phone: string,
  text: string,
): Promise<void> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 10_000);
  try {
    const res = await fetch(config.url, {
      method: 'POST',
      headers: { 'Content-Type': 'text/xml; charset=utf-8' },
      body: buildNikitaXml(config, phone, text),
      signal: controller.signal,
    });
    const body = await res.text();
    const status = parseNikitaStatus(body);
    if (!res.ok || status !== 0) {
      // Never log the request: it contains the password
      throw new Error(
        `SMSPRO rejected the message: HTTP ${res.status}, status ${status ?? 'unknown'}`,
      );
    }
  } finally {
    clearTimeout(timer);
  }
}
