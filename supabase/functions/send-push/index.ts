// Edge Function principale : envoie des notifications push VAPID
// via la librairie npm:web-push (Deno).
//
// Corps attendu :
//   { user_ids?: string[], role?: string, title: string, body: string, url?: string }
//
// Variables d'environnement nécessaires (supabase secrets set ...) :
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import webPush from 'npm:web-push@3';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    webPush.setVapidDetails(
      Deno.env.get('VAPID_SUBJECT')!,
      Deno.env.get('VAPID_PUBLIC_KEY')!,
      Deno.env.get('VAPID_PRIVATE_KEY')!,
    );

    const payload = (await req.json()) as {
      user_ids?: string[];
      role?: string;
      title: string;
      body: string;
      url?: string;
    };

    // Utiliser la clé service_role pour contourner le RLS
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Construire la requête selon le ciblage (user_ids ou role)
    let query = supabase
      .from('push_subscriptions')
      .select('endpoint, p256dh, auth, users!inner(role)');

    if (payload.user_ids && payload.user_ids.length > 0) {
      query = query.in('user_id', payload.user_ids);
    } else if (payload.role) {
      query = query.eq('users.role', payload.role);
    } else {
      // Aucun ciblage : ne rien envoyer
      return new Response(
        JSON.stringify({ sent: 0, message: 'Aucun ciblage spécifié' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const { data: subscriptions, error } = await query;
    if (error) throw error;

    if (!subscriptions || subscriptions.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, message: 'Aucun abonné trouvé' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
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
        webPush
          .sendNotification(
            { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
            notifPayload,
          )
          .catch(async (err: { statusCode?: number }) => {
            // HTTP 410 = souscription expirée/révoquée → nettoyer la DB
            if (err.statusCode === 410) {
              await supabase
                .from('push_subscriptions')
                .delete()
                .eq('endpoint', sub.endpoint);
            }
            throw err;
          })
      ),
    );

    const sent = results.filter((r) => r.status === 'fulfilled').length;
    const failed = results.filter((r) => r.status === 'rejected').length;

    return new Response(
      JSON.stringify({ sent, failed }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
