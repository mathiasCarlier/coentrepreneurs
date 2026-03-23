// Edge Function : digest quotidien de notifications non lues.
// Implémentation native Deno (WebCrypto + fetch natif), sans npm:web-push.
//
// Appelée via :
//   curl -X POST https://app.coentrepreneurs.fr/supabase-api/functions/v1/daily-digest \
//     -H "Authorization: Bearer <service_role_key>"

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ── Base64url ──────────────────────────────────────────────────────────────

function b64uDecode(s: string): Uint8Array {
  s = s.replace(/-/g, '+').replace(/_/g, '/');
  while (s.length % 4) s += '=';
  const bin = atob(s);
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

function b64uEncode(data: Uint8Array | ArrayBuffer): string {
  const bytes = data instanceof Uint8Array ? data : new Uint8Array(data);
  let bin = '';
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

// ── HMAC-SHA-256 / HKDF ───────────────────────────────────────────────────

async function hmac256(key: Uint8Array, data: Uint8Array): Promise<Uint8Array> {
  const k = await crypto.subtle.importKey('raw', key, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return new Uint8Array(await crypto.subtle.sign('HMAC', k, data));
}

async function hkdfExtract(salt: Uint8Array, ikm: Uint8Array): Promise<Uint8Array> {
  return hmac256(salt, ikm);
}

async function hkdfExpand(prk: Uint8Array, info: Uint8Array, len: number): Promise<Uint8Array> {
  const out = new Uint8Array(len);
  let t = new Uint8Array(0);
  let pos = 0;
  for (let i = 1; pos < len; i++) {
    const inp = new Uint8Array(t.length + info.length + 1);
    inp.set(t);
    inp.set(info, t.length);
    inp[t.length + info.length] = i;
    t = await hmac256(prk, inp);
    const n = Math.min(len - pos, t.length);
    out.set(t.subarray(0, n), pos);
    pos += n;
  }
  return out;
}

function concat(...arrays: Uint8Array[]): Uint8Array {
  const total = arrays.reduce((s, a) => s + a.length, 0);
  const out = new Uint8Array(total);
  let offset = 0;
  for (const a of arrays) { out.set(a, offset); offset += a.length; }
  return out;
}

const enc = new TextEncoder();

// ── VAPID JWT (ES256) ──────────────────────────────────────────────────────

async function createVapidJwt(
  subject: string,
  vapidPublicKey: string,
  vapidPrivateKey: string,
  audience: string,
): Promise<string> {
  const privBytes = b64uDecode(vapidPrivateKey); // 32 bytes scalar

  // Build PKCS8 DER structure for P-256 private key (67 bytes total)
  const ecPrivKey = new Uint8Array([0x30, 0x25, 0x02, 0x01, 0x01, 0x04, 0x20, ...privBytes]);
  const octetStr = new Uint8Array([0x04, 0x27, ...ecPrivKey]);
  const algo = new Uint8Array([0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07]);
  const pkcs8 = new Uint8Array([0x30, 0x41, 0x02, 0x01, 0x00, ...algo, ...octetStr]);

  const key = await crypto.subtle.importKey(
    'pkcs8', pkcs8.buffer,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign'],
  );

  const header = b64uEncode(enc.encode(JSON.stringify({ typ: 'JWT', alg: 'ES256' })));
  const payload = b64uEncode(enc.encode(JSON.stringify({
    aud: audience,
    exp: Math.floor(Date.now() / 1000) + 43200,
    sub: subject,
  })));
  const sigInput = `${header}.${payload}`;
  const sig = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, enc.encode(sigInput));
  return `${sigInput}.${b64uEncode(sig)}`;
}

// ── Web Push Encryption – RFC 8291 (aes128gcm) ────────────────────────────

async function encryptPayload(
  payloadStr: string,
  p256dh: string,
  authStr: string,
): Promise<Uint8Array> {
  const receiverPub = b64uDecode(p256dh);
  const authSecret = b64uDecode(authStr);

  const ephemeral = await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits']);
  const senderPub = new Uint8Array(await crypto.subtle.exportKey('raw', ephemeral.publicKey));

  const receiverKey = await crypto.subtle.importKey('raw', receiverPub, { name: 'ECDH', namedCurve: 'P-256' }, false, []);
  const sharedSecret = new Uint8Array(await crypto.subtle.deriveBits({ name: 'ECDH', public: receiverKey }, ephemeral.privateKey, 256));

  const prkKey = await hkdfExtract(authSecret, sharedSecret);
  const keyInfo = concat(enc.encode('WebPush: info\x00'), receiverPub, senderPub);
  const ikm = await hkdfExpand(prkKey, keyInfo, 32);

  const salt = crypto.getRandomValues(new Uint8Array(16));
  const prk = await hkdfExtract(salt, ikm);

  const cek = await hkdfExpand(prk, enc.encode('Content-Encoding: aes128gcm\x00'), 16);
  const nonce = await hkdfExpand(prk, enc.encode('Content-Encoding: nonce\x00'), 12);

  const plaintext = concat(enc.encode(payloadStr), new Uint8Array([0x02]));

  const aesKey = await crypto.subtle.importKey('raw', cek, { name: 'AES-GCM' }, false, ['encrypt']);
  const ciphertext = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, aesKey, plaintext));

  const rs = 4096;
  const header = new Uint8Array(16 + 4 + 1 + 65);
  header.set(salt, 0);
  new DataView(header.buffer).setUint32(16, rs, false);
  header[20] = 65;
  header.set(senderPub, 21);
  return concat(header, ciphertext);
}

// ── Send one push notification ─────────────────────────────────────────────

async function sendPush(
  endpoint: string,
  p256dh: string,
  auth: string,
  payloadStr: string,
  vapidSubject: string,
  vapidPublicKey: string,
  vapidPrivateKey: string,
): Promise<void> {
  const url = new URL(endpoint);
  const audience = `${url.protocol}//${url.host}`;
  const jwt = await createVapidJwt(vapidSubject, vapidPublicKey, vapidPrivateKey, audience);
  const body = await encryptPayload(payloadStr, p256dh, auth);

  const res = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Authorization': `vapid t=${jwt},k=${vapidPublicKey}`,
      'Content-Encoding': 'aes128gcm',
      'Content-Type': 'application/octet-stream',
      'TTL': '86400',
    },
    body,
  });

  if (res.status === 410 || res.status === 404) {
    const err = new Error('Subscription expired') as Error & { statusCode: number };
    err.statusCode = 410;
    throw err;
  }
  if (!res.ok) {
    throw new Error(`Push failed: ${res.status} ${await res.text()}`);
  }
}

// ── Main handler ───────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  const expectedToken = `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''}`;
  if (!expectedToken || authHeader !== expectedToken) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    const vapidSubject = Deno.env.get('VAPID_SUBJECT')!;
    const vapidPublicKey = Deno.env.get('VAPID_PUBLIC_KEY')!;
    const vapidPrivateKey = Deno.env.get('VAPID_PRIVATE_KEY')!;

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    // Rencontres à venir (non terminées)
    const { data: events } = await supabase
      .from('events')
      .select('id')
      .gte('date', startOfToday)
      .neq('status', 'finished');
    const eventIds = new Set<string>((events ?? []).map((e: { id: string }) => e.id));

    // Messages publiés
    const { data: messages } = await supabase
      .from('messages')
      .select('id')
      .eq('published', true);
    const messageIds = new Set<string>((messages ?? []).map((m: { id: string }) => m.id));

    // Nouveaux membres approuvés dans les 7 derniers jours
    const { data: newMembers } = await supabase
      .from('users')
      .select('id')
      .eq('approval_status', 'approved')
      .gte('approved_at', sevenDaysAgo);
    const newMemberIds = new Set<string>((newMembers ?? []).map((u: { id: string }) => u.id));

    // Souscriptions push des adhérents
    const { data: subscriptions, error } = await supabase
      .from('push_subscriptions')
      .select(
        'endpoint, p256dh, auth, user_id, users!inner(role, read_notification_event_ids, read_notification_message_ids, read_new_member_ids)',
      )
      .eq('users.role', 'adherent');

    if (error) throw error;
    if (!subscriptions?.length) {
      return new Response(
        JSON.stringify({ sent: 0, skipped: 0, message: 'Aucun abonné adherent' }),
        { headers: { 'Content-Type': 'application/json' } },
      );
    }

    let sent = 0;
    let skipped = 0;
    let failed = 0;

    for (const sub of subscriptions) {
      const user = sub.users as {
        role: string;
        read_notification_event_ids: string[] | null;
        read_notification_message_ids: string[] | null;
        read_new_member_ids: string[] | null;
      };

      const readEventIds = new Set<string>(user.read_notification_event_ids ?? []);
      const readMessageIds = new Set<string>(user.read_notification_message_ids ?? []);
      const readMemberIds = new Set<string>(user.read_new_member_ids ?? []);

      const unreadEvents = [...eventIds].filter((id) => !readEventIds.has(id)).length;
      const unreadMessages = [...messageIds].filter((id) => !readMessageIds.has(id)).length;
      const unreadMembers = [...newMemberIds].filter(
        (id) => id !== sub.user_id && !readMemberIds.has(id),
      ).length;

      const total = unreadEvents + unreadMessages + unreadMembers;

      if (total === 0) {
        skipped++;
        continue;
      }

      const parts: string[] = [];
      if (unreadEvents > 0) parts.push(`${unreadEvents} rencontre${unreadEvents > 1 ? 's' : ''}`);
      if (unreadMessages > 0) parts.push(`${unreadMessages} message${unreadMessages > 1 ? 's' : ''}`);
      if (unreadMembers > 0) {
        parts.push(`${unreadMembers} nouveau${unreadMembers > 1 ? 'x' : ''} membre${unreadMembers > 1 ? 's' : ''}`);
      }

      const body =
        total === 1
          ? `Vous avez 1 nouvelle notification`
          : `Vous avez ${total} nouvelles notifications : ${parts.join(', ')}`;

      const notifPayload = JSON.stringify({
        title: 'Co-entrepreneurs',
        body,
        url: '/home',
        icon: '/icons/android_xxxhdpi_192x192.png',
        badge: '/icons/web_favicon_64x64.png',
      });

      try {
        await sendPush(sub.endpoint, sub.p256dh, sub.auth, notifPayload, vapidSubject, vapidPublicKey, vapidPrivateKey);
        sent++;
      } catch (err: unknown) {
        const pushErr = err as { statusCode?: number };
        if (pushErr.statusCode === 410) {
          await supabase.from('push_subscriptions').delete().eq('endpoint', sub.endpoint);
        }
        failed++;
      }
    }

    return new Response(
      JSON.stringify({ sent, skipped, failed }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
