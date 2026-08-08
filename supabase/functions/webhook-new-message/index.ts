// Edge Function : envoie un email via Resend quand un nouveau message est inséré.
// À configurer comme webhook sur la table public.messages (événement INSERT).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE';
  table: string;
  record: {
    id: string;
    user_name?: string;
    user_email?: string;
    category?: string;
    message?: string;
  };
  schema: string;
  old_record: null | Record<string, unknown>;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  const expectedToken = `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''}`;
  if (!expectedToken || authHeader !== expectedToken) {
    return new Response('Unauthorized', { status: 401, headers: corsHeaders });
  }

  try {
    const payload = (await req.json()) as WebhookPayload;

    if (payload.type !== 'INSERT' || payload.table !== 'messages') {
      return new Response(JSON.stringify({ skipped: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const resendApiKey = Deno.env.get('RESEND_API_KEY');

    if (!supabaseUrl || !supabaseServiceKey || !resendApiKey) {
      return new Response(
        JSON.stringify({ error: 'Missing required env vars (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, RESEND_API_KEY)' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 },
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: admins, error: adminsError } = await supabase
      .from('users')
      .select('email')
      .like('role', '%admin%');

    if (adminsError) throw adminsError;

    const adminEmails = (admins ?? [])
      .map((admin) => admin.email)
      .filter((email): email is string => typeof email === 'string' && email.trim().length > 0);

    if (adminEmails.length === 0) {
      return new Response(JSON.stringify({ skipped: true, reason: 'no admin emails' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    const record = payload.record;
    const senderName = record.user_name?.trim() || 'Utilisateur inconnu';
    const senderEmail = record.user_email?.trim() || 'N/A';
    const category = record.category?.trim() || 'N/A';
    const message = record.message?.trim() || '';

    const emailHtml = `
      <h2>Nouveau message reçu</h2>
      <p><strong>De :</strong> ${senderName} (${senderEmail})</p>
      <p><strong>Catégorie :</strong> ${category}</p>
      <p><strong>Message :</strong></p>
      <p>${message.replace(/\n/g, '<br />')}</p>
      <hr />
      <p>Connectez-vous à l'application pour répondre.</p>
    `;

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'CoEntrepreneurs <onboarding@resend.dev>',
        to: adminEmails,
        subject: `Nouveau message de ${senderName}`,
        html: emailHtml,
      }),
      signal: AbortSignal.timeout(20_000),
    });

    if (!res.ok) {
      const errText = await res.text();
      throw new Error(`Resend error: ${errText}`);
    }

    return new Response(JSON.stringify({ success: true, sentTo: adminEmails.length }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: String(err) }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
