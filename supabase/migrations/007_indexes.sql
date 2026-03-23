-- Migration 007 : index sur les colonnes fréquemment filtrées
-- À appliquer dans Supabase Studio > SQL Editor
-- ou : psql -U postgres -d postgres -f 007_indexes.sql

-- users : filtres sur approval_status et role (notifications_page, admin, send-push)
CREATE INDEX IF NOT EXISTS idx_users_approval_status ON public.users (approval_status);
CREATE INDEX IF NOT EXISTS idx_users_role            ON public.users (role);

-- registrations : filtres user_id et event_id (event_service — très fréquent)
CREATE INDEX IF NOT EXISTS idx_registrations_user_id  ON public.registrations (user_id);
CREATE INDEX IF NOT EXISTS idx_registrations_event_id ON public.registrations (event_id);
-- index composé pour les requêtes .eq('user_id').eq('event_id')
CREATE INDEX IF NOT EXISTS idx_registrations_user_event ON public.registrations (user_id, event_id);

-- events : tri par date (getAllEvents)
CREATE INDEX IF NOT EXISTS idx_events_date ON public.events (date ASC);

-- cgu_acceptances : filtre user_id (cgu_service)
CREATE INDEX IF NOT EXISTS idx_cgu_acceptances_user_id ON public.cgu_acceptances (user_id);

-- push_subscriptions : filtre user_id
CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user_id ON public.push_subscriptions (user_id);
