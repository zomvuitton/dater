// Sends push notifications for rows inserted into public.notifications.
//
// Called by the `dispatch_push` database trigger with
//   Authorization: Bearer <PUSH_WEBHOOK_SECRET>   body: {"notification_id": "..."}
// Secrets: PUSH_WEBHOOK_SECRET, FCM_SERVICE_ACCOUNT (service account JSON).
// Optional: FCM_BASE_URL (tests). SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are
// provided by the platform.

import { FcmClient, parseServiceAccount } from './fcm.ts';
import { buildPushText, type NotificationDetails } from './message.ts';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const webhookSecret = Deno.env.get('PUSH_WEBHOOK_SECRET');
const serviceAccountJson = Deno.env.get('FCM_SERVICE_ACCOUNT');

const serviceAccount = parseServiceAccount(serviceAccountJson);
const fcm = serviceAccount ? new FcmClient(serviceAccount, fetch, Deno.env.get('FCM_BASE_URL') ?? undefined) : null;

function rest(path: string, init: RequestInit = {}): Promise<Response> {
  const headers = new Headers(init.headers);
  headers.set('apikey', serviceKey);
  // Legacy service-role keys are JWTs; new sb_secret_ keys go in apikey only.
  if (serviceKey.startsWith('eyJ')) headers.set('Authorization', `Bearer ${serviceKey}`);
  return fetch(`${supabaseUrl}/rest/v1/${path}`, { ...init, headers });
}

async function loadNotification(id: string): Promise<(NotificationDetails & { userId: string }) | null> {
  const select = 'id,type,response,user_id,circle_id,' +
    'actor:profiles!notifications_actor_id_fkey(display_name,username),' +
    'circle:circles(name,emoji),plan:plans(title,starts_at)';
  const res = await rest(`notifications?id=eq.${encodeURIComponent(id)}&select=${select}`);
  if (!res.ok) throw new Error(`load notification: ${res.status} ${await res.text()}`);
  const [row] = await res.json();
  if (!row) return null;
  return {
    id: row.id,
    userId: row.user_id,
    type: row.type,
    response: row.response,
    circleId: row.circle_id,
    circleName: row.circle.name,
    circleEmoji: row.circle.emoji,
    actorName: row.actor.display_name || `@${row.actor.username}`,
    planTitle: row.plan.title,
    planStartsAt: row.plan.starts_at,
  };
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('method not allowed', { status: 405 });
  if (!webhookSecret || req.headers.get('Authorization') !== `Bearer ${webhookSecret}`) {
    return new Response('unauthorized', { status: 401 });
  }

  const { notification_id: id } = await req.json().catch(() => ({}));
  if (typeof id !== 'string') return Response.json({ error: 'notification_id required' }, { status: 400 });
  if (!fcm) return Response.json({ skipped: 'FCM_SERVICE_ACCOUNT not set or invalid' });

  const notification = await loadNotification(id);
  if (!notification) return Response.json({ skipped: 'notification not found' });

  const tokensRes = await rest(`device_tokens?user_id=eq.${notification.userId}&select=token,locale,time_zone`);
  if (!tokensRes.ok) throw new Error(`load tokens: ${tokensRes.status}`);
  const tokens = await tokensRes.json() as { token: string; locale: string; time_zone: string }[];

  const results = await Promise.all(tokens.map(async (t) => {
    const text = buildPushText(notification, t.locale, t.time_zone);
    const result = await fcm.send(t.token, {
      title: text.title,
      body: text.body,
      data: { route: text.route, notification_id: notification.id },
    });
    if (result === 'unregistered') {
      await rest(`device_tokens?token=eq.${encodeURIComponent(t.token)}`, { method: 'DELETE' });
    }
    return result;
  }));

  return Response.json({
    sent: results.filter((r) => r === 'sent').length,
    unregistered: results.filter((r) => r === 'unregistered').length,
    failed: results.filter((r) => r === 'failed').length,
  });
});
