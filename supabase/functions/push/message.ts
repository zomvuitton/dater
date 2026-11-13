// Builds the push text for one recipient device, in its language and time zone.

export type NotificationType = 'plan_proposed' | 'plan_response';
export type PlanResponse = 'going' | 'maybe' | 'no';

export interface NotificationDetails {
  id: string;
  type: NotificationType;
  response: PlanResponse | null;
  circleId: string;
  circleName: string;
  circleEmoji: string;
  actorName: string;
  planTitle: string;
  planStartsAt: string; // ISO timestamp
}

export interface PushText {
  title: string;
  body: string;
  route: string;
}

const supported = ['tr', 'en'] as const;
type Lang = (typeof supported)[number];

export function languageOf(locale: string | null | undefined): Lang {
  const lang = (locale ?? '').slice(0, 2).toLowerCase();
  return (supported as readonly string[]).includes(lang) ? (lang as Lang) : 'en';
}

/** "Sal 17 Kas 21:00" / "Tue, Nov 17, 9:00 PM" in the recipient's time zone. */
export function formatWhen(iso: string, lang: Lang, timeZone: string): string {
  const options: Intl.DateTimeFormatOptions = {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    hour: 'numeric',
    minute: '2-digit',
  };
  try {
    return new Intl.DateTimeFormat(lang, { ...options, timeZone }).format(new Date(iso));
  } catch {
    // Unknown time zone name from the device: fall back to UTC.
    return new Intl.DateTimeFormat(lang, { ...options, timeZone: 'UTC' }).format(new Date(iso));
  }
}

export function buildPushText(n: NotificationDetails, locale: string, timeZone: string): PushText {
  const lang = languageOf(locale);
  const title = `${n.circleEmoji} ${n.circleName}`.trim();
  const route = `/circles/${n.circleId}?tab=plans`;
  const plan = `“${n.planTitle}”`;

  if (n.type === 'plan_proposed') {
    const when = formatWhen(n.planStartsAt, lang, timeZone);
    const body = lang === 'tr'
      ? `${n.actorName} yeni bir plan önerdi: ${n.planTitle} · ${when}`
      : `${n.actorName} proposed a plan: ${n.planTitle} · ${when}`;
    return { title, body, route };
  }

  const bodies: Record<Lang, Record<PlanResponse, string>> = {
    tr: {
      going: `${n.actorName} ${plan} planına geliyor`,
      maybe: `${n.actorName} ${plan} planı için “belki” dedi`,
      no: `${n.actorName} ${plan} planına gelemiyor`,
    },
    en: {
      going: `${n.actorName} is going to ${plan}`,
      maybe: `${n.actorName} might join ${plan}`,
      no: `${n.actorName} can't make it to ${plan}`,
    },
  };
  return { title, body: bodies[lang][n.response ?? 'going'], route };
}
