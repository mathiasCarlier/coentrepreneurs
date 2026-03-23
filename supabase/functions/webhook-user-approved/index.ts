// Relay webhook : déclenché par UPDATE sur public.users
// Notifie l'utilisateur quand son approval_status change vers 'approved' ou 'rejected'.
//
// Configurer dans Supabase Dashboard > Database > Webhooks :
//   Table: users | Event: UPDATE
//   URL: https://<ref>.supabase.co/functions/v1/webhook-user-approved
//   Headers: Authorization: Bearer <service_role_key>

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get('Authorization') ?? '';
  const expectedToken = `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''}`;
  if (!expectedToken || authHeader !== expectedToken) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    const body = await req.json();
    const newRecord = body.record as Record<string, string>;
    const oldRecord = body.old_record as Record<string, string>;

    const statusChanged = oldRecord.approval_status !== newRecord.approval_status;
    const isTerminal = ['approved', 'rejected'].includes(newRecord.approval_status);

    if (!statusChanged || !isTerminal) {
      return new Response('ignored', { status: 200 });
    }

    const isApproved = newRecord.approval_status === 'approved';
    const title = isApproved ? 'Compte approuvé' : 'Demande refusée';
    const notifBody = isApproved
      ? 'Votre compte a été approuvé. Bienvenue !'
      : "Votre demande d'adhésion n'a pas été retenue.";

    const res = await fetch(
      `${Deno.env.get('SUPABASE_URL')}/functions/v1/send-push`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        },
        body: JSON.stringify({
          user_ids: [newRecord.id],
          title,
          body: notifBody,
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
