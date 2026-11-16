import { useCallback, useEffect, useRef, useState } from 'react';

const SOUND_KEY = 'orders_sound_enabled';
const BASE_TITLE = document.title;

const readSoundPref = () => {
  try {
    return localStorage.getItem(SOUND_KEY) === '1';
  } catch {
    return false;
  }
};

/**
 * Signals new orders: plays a short chime and shows the number of pending
 * orders in the browser tab title.
 *
 * Browsers only allow audio after a user gesture, so sound must be switched
 * on with a click (`toggleSound`) once per page load; the preference itself
 * is remembered.
 *
 * `scopeKey` identifies what the count covers (e.g. the store filter); when it
 * changes the count is re-baselined so switching filters does not chime.
 */
export function useNewOrderAlert(pendingCount: number | null, scopeKey: string) {
  const [soundEnabled, setSoundEnabled] = useState(readSoundPref);
  const [soundBlocked, setSoundBlocked] = useState(false);
  const audioRef = useRef<AudioContext | null>(null);
  const previous = useRef<number | null>(null);

  const chime = useCallback(() => {
    const ctx = audioRef.current;
    if (!ctx || ctx.state !== 'running') {
      setSoundBlocked(true);
      return;
    }
    // Two short rising tones
    [660, 880].forEach((freq, i) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      const start = ctx.currentTime + i * 0.18;
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.0001, start);
      gain.gain.exponentialRampToValueAtTime(0.3, start + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.16);
      osc.connect(gain).connect(ctx.destination);
      osc.start(start);
      osc.stop(start + 0.17);
    });
  }, []);

  const toggleSound = useCallback(async () => {
    // While blocked, a click unlocks audio instead of switching sound off
    const next = soundBlocked ? true : !soundEnabled;
    if (next) {
      const Ctx = window.AudioContext || (window as any).webkitAudioContext;
      audioRef.current = audioRef.current ?? new Ctx();
      await audioRef.current.resume();
      setSoundBlocked(false);
      chime();
    } else {
      setSoundBlocked(false);
    }
    setSoundEnabled(next);
    try {
      localStorage.setItem(SOUND_KEY, next ? '1' : '0');
    } catch {
      // Preference simply won't be remembered
    }
  }, [soundEnabled, soundBlocked, chime]);

  // Remembered "on" after a reload still needs one click to unlock audio
  useEffect(() => {
    if (soundEnabled && !audioRef.current) setSoundBlocked(true);
  }, [soundEnabled]);

  useEffect(() => {
    previous.current = null;
  }, [scopeKey]);

  useEffect(() => {
    if (pendingCount === null) return;
    if (
      soundEnabled &&
      previous.current !== null &&
      pendingCount > previous.current
    ) {
      chime();
    }
    previous.current = pendingCount;
    document.title = pendingCount > 0 ? `(${pendingCount}) ${BASE_TITLE}` : BASE_TITLE;
  }, [pendingCount, soundEnabled, chime]);

  useEffect(() => () => {
    document.title = BASE_TITLE;
  }, []);

  return { soundEnabled, soundBlocked, toggleSound };
}
