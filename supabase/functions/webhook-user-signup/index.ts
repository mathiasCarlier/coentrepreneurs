// Relay webhook : déclenché par INSERT sur public.users
// Notifie tous les admins qu'un nouvel utilisateur attend l'approbation.
//
// Configurer dans Supabase Dashboard > Database > Webhooks :
//   Table: users | Event: INSERT
//   URL: https://<ref>.supabase.co/functions/v1/webhook-user-signup
//   Headers: Authorization: Bearer <service_role_key>

Deno.serve(async (req: Request) => {
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
      },
    );

    return new Response(await res.text(), { status: res.status });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
