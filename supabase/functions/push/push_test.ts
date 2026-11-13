import { assert, assertEquals, assertMatch } from 'jsr:@std/assert@1';
import { FcmClient, parseServiceAccount, signAssertion, type ServiceAccount } from './fcm.ts';
import { buildPushText, languageOf, type NotificationDetails } from './message.ts';

const base: NotificationDetails = {
  id: 'n1',
  type: 'plan_proposed',
  response: null,
  circleId: 'c1',
  circleName: 'Tırmanış',
  circleEmoji: '🧗',
  actorName: 'Bob',
  planTitle: 'Bouldering',
  planStartsAt: '2026-11-17T17:00:00Z',
};

Deno.test('languageOf falls back to English', () => {
  assertEquals(languageOf('tr'), 'tr');
  assertEquals(languageOf('tr-TR'), 'tr');
  assertEquals(languageOf('de'), 'en');
  assertEquals(languageOf(null), 'en');
});

Deno.test('plan proposed: Turkish, in the recipient time zone', () => {
  const text = buildPushText(base, 'tr', 'Europe/Istanbul');
  assertEquals(text.title, '🧗 Tırmanış');
  assertMatch(text.body, /^Bob yeni bir plan önerdi: Bouldering · /);
  assertMatch(text.body, /20:00/); // 17:00 UTC = 20:00 in Istanbul
  assertMatch(text.body, /Kas/);
  assertEquals(text.route, '/circles/c1?tab=plans');
});

Deno.test('plan proposed: English and unknown time zone falls back to UTC', () => {
  const text = buildPushText(base, 'en', 'Not/AZone');
  assertMatch(text.body, /^Bob proposed a plan: Bouldering · /);
  assertMatch(text.body, /5:00\sPM/);
});

Deno.test('plan responses in both languages', () => {
  const r = (response: 'going' | 'maybe' | 'no', lang: string) =>
    buildPushText({ ...base, type: 'plan_response', response, actorName: 'Cem' }, lang, 'UTC').body;
  assertEquals(r('going', 'tr'), 'Cem “Bouldering” planına geliyor');
  assertEquals(r('maybe', 'tr'), 'Cem “Bouldering” planı için “belki” dedi');
  assertEquals(r('no', 'tr'), 'Cem “Bouldering” planına gelemiyor');
  assertEquals(r('going', 'en'), 'Cem is going to “Bouldering”');
  assertEquals(r('no', 'en'), "Cem can't make it to “Bouldering”");
});

async function testServiceAccount(): Promise<{ sa: ServiceAccount; publicKey: CryptoKey }> {
  const pair = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true,
    ['sign', 'verify'],
  );
  const der = new Uint8Array(await crypto.subtle.exportKey('pkcs8', pair.privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${btoa(String.fromCharCode(...der))}\n-----END PRIVATE KEY-----\n`;
  return {
    sa: { project_id: 'demo', client_email: 'push@demo.iam', private_key: pem, token_uri: 'https://oauth.test/token' },
    publicKey: pair.publicKey,
  };
}

Deno.test('assertion is a valid RS256 JWT', async () => {
  const { sa, publicKey } = await testServiceAccount();
  const jwt = await signAssertion(sa, 1000);
  const [h, c, s] = jwt.split('.');
  const decode = (x: string): Uint8Array<ArrayBuffer> => Uint8Array.from(atob(x.replace(/-/g, '+').replace(/_/g, '/')), (ch) => ch.charCodeAt(0));
  const claims = JSON.parse(new TextDecoder().decode(decode(c)));
  assertEquals(claims, {
    iss: 'push@demo.iam',
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth.test/token',
    iat: 1000,
    exp: 4600,
  });
  assert(await crypto.subtle.verify('RSASSA-PKCS1-v1_5', publicKey, decode(s), new TextEncoder().encode(`${h}.${c}`)));
});

Deno.test('FcmClient caches the access token and reports unregistered tokens', async () => {
  const { sa } = await testServiceAccount();
  const calls: { url: string; body: string }[] = [];
  const fakeFetch = (async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = String(input);
    calls.push({ url, body: String(init?.body ?? '') });
    if (url === 'https://oauth.test/token') return Response.json({ access_token: 'tok', expires_in: 3600 });
    const { message } = JSON.parse(String(init?.body));
    if (message.token === 'dead') {
      return Response.json({ error: { status: 'NOT_FOUND', details: [{ errorCode: 'UNREGISTERED' }] } }, { status: 404 });
    }
    assertEquals((init?.headers as Record<string, string>).Authorization, 'Bearer tok');
    return Response.json({ name: 'projects/demo/messages/1' });
  }) as typeof fetch;

  const client = new FcmClient(sa, fakeFetch, 'https://fcm.test');
  const msg = { title: 't', body: 'b', data: { route: '/x' } };
  // Concurrent sends share one token request.
  assertEquals(await Promise.all([client.send('alive', msg), client.send('dead', msg)]), ['sent', 'unregistered']);
  assertEquals(await client.send('alive', msg), 'sent');

  assertEquals(calls.filter((c) => c.url === 'https://oauth.test/token').length, 1, 'token is cached');
  const sent = JSON.parse(calls[1].body).message;
  assertEquals(calls[1].url, 'https://fcm.test/v1/projects/demo/messages:send');
  assertEquals(sent.token, 'alive');
  assertEquals(sent.notification, { title: 't', body: 'b' });
  assertEquals(sent.data, { route: '/x' });
});

Deno.test('parseServiceAccount tolerates unescaped key newlines and rejects junk', () => {
  const sa = { project_id: 'p', client_email: 'e', private_key: '-----BEGIN PRIVATE KEY-----\nAAA\n-----END PRIVATE KEY-----\n' };
  assertEquals(parseServiceAccount(JSON.stringify(sa)), sa);
  // A dotenv loader turned the escaped \n inside the key into real newlines.
  assertEquals(parseServiceAccount(JSON.stringify(sa).replaceAll('\\n', '\n')), sa);
  assertEquals(parseServiceAccount(undefined), null);
  assertEquals(parseServiceAccount('{"project_id": "p"}'), null);
  assertEquals(parseServiceAccount('not json'), null);
});
