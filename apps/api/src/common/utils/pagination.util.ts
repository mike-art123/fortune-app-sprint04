/**
 * Opaque cursor helpers (doc 52 §33). Clients never see raw Prisma cursors.
 */
export function encodeCursor(value: string): string {
  return Buffer.from(value, 'utf8').toString('base64url');
}

export function decodeCursor(cursor: string | undefined): string | undefined {
  if (!cursor) return undefined;
  try {
    const decoded = Buffer.from(cursor, 'base64url').toString('utf8');
    if (decoded.length === 0 || decoded.length > 128) return undefined;
    // Node's base64url decoding is lenient (it skips invalid characters), so a
    // garbage cursor can still yield non-empty bytes. Only a value that
    // round-trips back to the exact input was genuinely produced by us.
    return encodeCursor(decoded) === cursor ? decoded : undefined;
  } catch {
    return undefined;
  }
}
