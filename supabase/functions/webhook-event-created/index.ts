// Relay webhook : déclenché par INSERT sur public.events
// Notifie tous les adhérents qu'un nouvel événement a été créé.
//
// Configurer dans Supabase Dashboard > Database > Webhooks :
//   Table: events | Event: INSERT
//   URL: https://<ref>.supabase.co/functions/v1/webhook-event-created
//   Headers: Authorization: Bearer <service_role_key>

// Comparaison à temps constant (voir send-push/index.ts).
function safeEqual(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a);
  const eb = new TextEncoder().encode(b);
  if (ea.length !== eb.length) return false;
  let diff = 0;
  for (let i = 0; i < ea.length; i++) diff |= ea[i] ^ eb[i];
  return diff === 0;
}

// Fail-closed : clé absente ⇒ aucune requête acceptée.
function isAuthorized(req: Request): boolean {
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!key) return false;
  return safeEqual(req.headers.get('Authorization') ?? '', `Bearer ${key}`);
}

Deno.serve(async (req: Request) => {
  if (!isAuthorized(req)) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    const body = await req.json();
    const event = body.record as Record<string, string>;

    const res = await fetch(
      `${Deno.env.get('SUPABASE_URL')}/functions/v1/send-push`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        },
        body: JSON.stringify({
          role: 'adherent',
          title: 'Nouvel événement',
          body: `Un nouvel événement a été créé : ${event.theme || event.title || 'Voir les détails'}`,
          url: '/home',
        }),
        signal: AbortSignal.timeout(20_000),
      },
    );

    return new Response(await res.text(), { status: res.status });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
