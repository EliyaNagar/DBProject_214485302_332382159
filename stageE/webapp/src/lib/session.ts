export const SESSION_COOKIE = "hms_session";

// Uses the Web Crypto API (globalThis.crypto.subtle) so the same code works in
// both the Node.js runtime (API routes) and the Edge runtime (middleware).
// Node's built-in `crypto` module is NOT available in the Edge runtime.

function utf8(s: string): Uint8Array {
  return new TextEncoder().encode(s);
}

function bytesToB64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function b64urlToBytes(b64url: string): Uint8Array {
  const b64 = b64url.replace(/-/g, "+").replace(/_/g, "/");
  const pad = b64.length % 4 ? "=".repeat(4 - (b64.length % 4)) : "";
  const bin = atob(b64 + pad);
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

async function hmac(payload: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    utf8(secret) as BufferSource,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, utf8(payload) as BufferSource);
  return bytesToB64url(new Uint8Array(sig));
}

/** Constant-time comparison of two equal-purpose strings. */
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return mismatch === 0;
}

/** Returns "<base64url(username)>.<hmac>". */
export async function signSession(username: string, secret: string): Promise<string> {
  const payload = bytesToB64url(utf8(username));
  const sig = await hmac(payload, secret);
  return `${payload}.${sig}`;
}

/** Returns the username if the token is valid, else null. */
export async function verifySession(token: string, secret: string): Promise<string | null> {
  const parts = token.split(".");
  if (parts.length !== 2) return null;
  const [payload, sig] = parts;
  const expected = await hmac(payload, secret);
  if (!timingSafeEqual(sig, expected)) return null;
  try {
    return new TextDecoder().decode(b64urlToBytes(payload));
  } catch {
    return null;
  }
}
