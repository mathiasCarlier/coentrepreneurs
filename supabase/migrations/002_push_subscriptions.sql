-- =============================================================
-- Migration 002 : push_subscriptions
-- Table pour stocker les abonnements push navigateur (VAPID)
-- =============================================================

CREATE TABLE public.push_subscriptions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  endpoint    TEXT NOT NULL,
  p256dh      TEXT NOT NULL,
  auth        TEXT NOT NULL,
  user_agent  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(endpoint)
);

ALTER TABLE public.push_subscriptions ENABLE ROW LEVEL SECURITY;

-- Un utilisateur gère uniquement ses propres souscriptions
CREATE POLICY "push_subs_select_own" ON public.push_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "push_subs_insert_own" ON public.push_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "push_subs_delete_own" ON public.push_subscriptions
  FOR DELETE USING (auth.uid() = user_id);

-- Le service_role (Edge Functions) peut lire toutes les souscriptions
-- (géré automatiquement par la clé service_role, pas besoin de policy explicite)
