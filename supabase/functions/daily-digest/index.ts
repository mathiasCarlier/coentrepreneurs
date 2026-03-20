// Edge Function : digest quotidien de notifications non lues.
//
// Envoyée chaque jour à 18h (via cron VPS) pour chaque adhérent
// ayant des notifications non lues (rencontres, messages, nouveaux membres).
//
// Appelée via :
//   curl -X POST https://app.coentrepreneurs.fr/functions/v1/daily-digest \
//     -H "Authorization: Bearer <service_role_key>"

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import webPush from 'npm:web-push@3';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
  }

  try {
    webPush.setVapidDetails(
      Deno.env.get('VAPID_SUBJECT')!,
      Deno.env.get('VAPID_PUBLIC_KEY')!,
      Deno.env.get('VAPID_PRIVATE_KEY')!,
    );

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const today = new Date().toISOString().split('T')[0];
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    // Rencontres à venir (non terminées)
    const { data: events } = await supabase
      .from('events')
      .select('id')
      .gte('date', today)
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

    // Souscriptions push des adhérents avec leurs tableaux "lus"
    const { data: subscriptions, error } = await supabase
      .from('push_subscriptions')
      .select(
        'endpoint, p256dh, auth, user_id, users!inner(role, read_notification_event_ids, read_notification_message_ids, read_new_member_ids)',
      )
      .eq('users.role', 'adherent');

    if (error) throw error;
    if (!subscriptions || subscriptions.length === 0) {
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
      // Exclure l'utilisateur lui-même des nouveaux membres
      const unreadMembers = [...newMemberIds].filter(
        (id) => id !== sub.user_id && !readMemberIds.has(id),
      ).length;

      const total = unreadEvents + unreadMessages + unreadMembers;

      if (total === 0) {
        skipped++;
        continue;
      }

      // Construire un corps de notification lisible
      const parts: string[] = [];
      if (unreadEvents > 0)
        parts.push(`${unreadEvents} rencontre${unreadEvents > 1 ? 's' : ''}`);
      if (unreadMessages > 0)
        parts.push(`${unreadMessages} message${unreadMessages > 1 ? 's' : ''}`);
      if (unreadMembers > 0)
        parts.push(
          `${unreadMembers} nouveau${unreadMembers > 1 ? 'x' : ''} membre${unreadMembers > 1 ? 's' : ''}`,
        );

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
        await webPush.sendNotification(
          { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
          notifPayload,
        );
        sent++;
      } catch (err: unknown) {
        const pushErr = err as { statusCode?: number };
        if (pushErr.statusCode === 410) {
          // Souscription expirée → nettoyer
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
