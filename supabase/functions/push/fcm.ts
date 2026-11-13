// Firebase Cloud Messaging HTTP v1 client using a service account key.

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

/** Parses the service account secret; null (push disabled) if it is missing or malformed. */
export function parseServiceAccount(raw: string | undefined): ServiceAccount | null {
  if (!raw) return null;
  // Some env loaders turn the key's escaped "\n" into real newlines, which JSON rejects.
  for (const candidate of [raw, raw.replace(/\r?\n/g, '\\n')]) {
    try {
      const sa = JSON.parse(candidate) as ServiceAccount;
      if (sa.project_id && sa.client_email && sa.private_key) return sa;
    } catch {
      // try the next form
    }
  }
  console.error('FCM_SERVICE_ACCOUNT is not a valid service account JSON; push is disabled');
  return null;
}

export type Fetch = typeof fetch;

export type SendResult = 'sent' | 'unregistered' | 'failed';

const scope = 'https://www.googleapis.com/auth/firebase.messaging';

function base64url(data: Uint8Array | string): string {
  const bytes = typeof data === 'string' ? new TextEncoder().encode(data) : data;
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToDer(pem: string): Uint8Array<ArrayBuffer> {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

/** Signed JWT assertion for Google's OAuth token endpoint. */
export async function signAssertion(sa: ServiceAccount, nowSeconds = Math.floor(Date.now() / 1000)): Promise<string> {
  const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    scope,
    aud: sa.token_uri ?? 'https://oauth2.googleapis.com/token',
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  }));
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claims}`));
  return `${header}.${claims}.${base64url(new Uint8Array(signature))}`;
}

export class FcmClient {
  #token: { value: Promise<string>; expiresAt: number } | null = null;

  constructor(
    private readonly sa: ServiceAccount,
    private readonly fetchImpl: Fetch = fetch,
    private readonly baseUrl = 'https://fcm.googleapis.com',
  ) {}

  /** OAuth access token, shared by concurrent sends and reused until shortly before it expires. */
  accessToken(): Promise<string> {
    const now = Date.now();
    if (this.#token && this.#token.expiresAt - 60_000 > now) return this.#token.value;
    const value = this.#fetchToken();
    this.#token = { value, expiresAt: now + 3_600_000 };
    value.catch(() => (this.#token = null));
    return value;
  }

  async #fetchToken(): Promise<string> {
    const res = await this.fetchImpl(this.sa.token_uri ?? 'https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: await signAssertion(this.sa),
      }),
    });
    if (!res.ok) throw new Error(`OAuth token request failed: ${res.status} ${await res.text()}`);
    const json = await res.json() as { access_token: string; expires_in?: number };
    if (this.#token) this.#token.expiresAt = Date.now() + (json.expires_in ?? 3600) * 1000;
    return json.access_token;
  }

  async send(
    deviceToken: string,
    message: { title: string; body: string; data: Record<string, string> },
  ): Promise<SendResult> {
    const res = await this.fetchImpl(`${this.baseUrl}/v1/projects/${this.sa.project_id}/messages:send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${await this.accessToken()}`,
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: { title: message.title, body: message.body },
          data: message.data,
          android: { priority: 'high' },
          apns: { payload: { aps: { sound: 'default' } } },
        },
      }),
    });
    if (res.ok) return 'sent';
    const text = await res.text();
    if (res.status === 404 || text.includes('UNREGISTERED')) return 'unregistered';
    console.error(`FCM send failed: ${res.status} ${text}`);
    return 'failed';
  }
}
