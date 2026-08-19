// Relay webhook : déclenché par INSERT sur public.users
// Notifie tous les admins qu'un nouvel utilisateur attend l'approbation.
//
// Configurer dans Supabase Dashboard > Database > Webhooks :
//   Table: users | Event: INSERT
//   URL: https://<ref>.supabase.co/functions/v1/webhook-user-signup
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
    const newUser = body.record as Record<string, string>;

    // Ignorer si ce n'est pas un utilisateur en attente
    if (newUser.approval_status !== 'pending') {
      return new Response('ignored', { status: 200 });
    }

    const prenom = newUser.prenom || '';
    const nom = newUser.nom || '';
    const displayName = `${prenom} ${nom}`.trim() || newUser.email;

    const res = await fetch(
      `${Deno.env.get('SUPABASE_URL')}/functions/v1/send-push`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        },
        body: JSON.stringify({
          role: 'admin',
          title: "Nouvelle demande d'adhésion",
          body: `${displayName} souhaite rejoindre la plateforme.`,
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
