/**
 * Parses a boolean query parameter from its raw value.
 *
 * Use as `@Transform(({ obj, key }) => parseBool(obj[key], fallback))`:
 * the global ValidationPipe enables implicit conversion, which turns the
 * string "false" into `true` before `value` reaches the transform, so the
 * raw value must be read from `obj`.
 */
export function parseBool(raw: unknown, fallback: boolean): boolean {
  if (raw === undefined || raw === null || raw === '') return fallback;
  if (raw === true || raw === 'true' || raw === '1') return true;
  if (raw === false || raw === 'false' || raw === '0') return false;
  return fallback;
}
