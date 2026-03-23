// Relay webhook : déclenché par INSERT sur public.events
// Notifie tous les adhérents qu'un nouvel événement a été créé.
//
// Configurer dans Supabase Dashboard > Database > Webhooks :
//   Table: events | Event: INSERT
//   URL: https://<ref>.supabase.co/functions/v1/webhook-event-created
//   Headers: Authorization: Bearer <service_role_key>

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get('Authorization') ?? '';
  const expectedToken = `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''}`;
  if (!expectedToken || authHeader !== expectedToken) {
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
