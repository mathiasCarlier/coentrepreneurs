// Edge Function : envoie des notifications push VAPID
// Implémentation native Deno (WebCrypto + fetch natif), sans npm:web-push.
//
// Corps attendu :
//   { user_ids?: string[], role?: string, title: string, body: string, url?: string }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

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
  const receiverPub = b64uDecode(p256dh);  // 65 bytes
  const authSecret = b64uDecode(authStr);  // 16 bytes

  // Ephemeral ECDH key pair
  const ephemeral = await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits']);
  const senderPub = new Uint8Array(await crypto.subtle.exportKey('raw', ephemeral.publicKey));

  // Import receiver public key
  const receiverKey = await crypto.subtle.importKey('raw', receiverPub, { name: 'ECDH', namedCurve: 'P-256' }, false, []);

  // ECDH shared secret
  const sharedSecret = new Uint8Array(await crypto.subtle.deriveBits({ name: 'ECDH', public: receiverKey }, ephemeral.privateKey, 256));

  // PRK_key = HKDF-Extract(auth_secret, shared_secret)
  const prkKey = await hkdfExtract(authSecret, sharedSecret);

  // key_info = "WebPush: info\x00" || receiverPub || senderPub
  const keyInfo = concat(enc.encode('WebPush: info\x00'), receiverPub, senderPub);

  // IKM = HKDF-Expand(PRK_key, key_info, 32)
  const ikm = await hkdfExpand(prkKey, keyInfo, 32);

  // Random salt
  const salt = crypto.getRandomValues(new Uint8Array(16));

  // PRK = HKDF-Extract(salt, IKM)
  const prk = await hkdfExtract(salt, ikm);

  // CEK (16 bytes) and NONCE (12 bytes)
  const cek = await hkdfExpand(prk, enc.encode('Content-Encoding: aes128gcm\x00'), 16);
  const nonce = await hkdfExpand(prk, enc.encode('Content-Encoding: nonce\x00'), 12);

  // Plaintext = payload + 0x02 (last-record delimiter)
  const plaintext = concat(enc.encode(payloadStr), new Uint8Array([0x02]));

  // AES-128-GCM encryption
  const aesKey = await crypto.subtle.importKey('raw', cek, { name: 'AES-GCM' }, false, ['encrypt']);
  const ciphertext = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, aesKey, plaintext));

  // Body = salt(16) + rs(4 BE) + keyIdLen(1) + senderPub(65) + ciphertext
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
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const vapidSubject = Deno.env.get('VAPID_SUBJECT')!;
    const vapidPublicKey = Deno.env.get('VAPID_PUBLIC_KEY')!;
    const vapidPrivateKey = Deno.env.get('VAPID_PRIVATE_KEY')!;

    const payload = (await req.json()) as {
      user_ids?: string[];
      role?: string;
      title: string;
      body: string;
      url?: string;
    };

    if (!payload.title?.trim()) {
      return new Response(JSON.stringify({ error: 'Champ title manquant ou invalide' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (!payload.body?.trim()) {
      return new Response(JSON.stringify({ error: 'Champ body manquant ou invalide' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    const allowedRoles = ['admin', 'adherent', 'invite'];
    if (payload.role !== undefined && !allowedRoles.includes(payload.role)) {
      return new Response(JSON.stringify({ error: `Rôle invalide : ${payload.role}` }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    if (payload.user_ids !== undefined && (!Array.isArray(payload.user_ids) || payload.user_ids.length > 500)) {
      return new Response(JSON.stringify({ error: 'user_ids invalide ou trop grand (max 500)' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    let query = supabase.from('push_subscriptions').select('endpoint, p256dh, auth, users!inner(role)');
    if (payload.user_ids?.length) {
      query = query.in('user_id', payload.user_ids);
    } else if (payload.role) {
      query = query.eq('users.role', payload.role);
    } else {
      return new Response(JSON.stringify({ sent: 0, message: 'Aucun ciblage spécifié' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: subscriptions, error } = await query;
    if (error) throw error;
    if (!subscriptions?.length) {
      return new Response(JSON.stringify({ sent: 0, message: 'Aucun abonné trouvé' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const notifPayload = JSON.stringify({
      title: payload.title,
      body: payload.body,
      url: payload.url ?? '/',
      icon: '/icons/android_xxxhdpi_192x192.png',
      badge: '/icons/web_favicon_64x64.png',
    });

    const results = await Promise.allSettled(
      subscriptions.map((sub) =>
        sendPush(sub.endpoint, sub.p256dh, sub.auth, notifPayload, vapidSubject, vapidPublicKey, vapidPrivateKey)
          .catch(async (err: Error & { statusCode?: number }) => {
            if (err.statusCode === 410) {
              await supabase.from('push_subscriptions').delete().eq('endpoint', sub.endpoint);
            }
            throw err;
          })
      ),
    );

    const sent = results.filter((r) => r.status === 'fulfilled').length;
    const failed = results.filter((r) => r.status === 'rejected').length;

    return new Response(JSON.stringify({ sent, failed }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
