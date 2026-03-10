-- Migration 006 : Ajout de la policy UPDATE sur push_subscriptions
-- Nécessaire pour que le upsert (?on_conflict=endpoint) fonctionne :
-- Postgres tente INSERT puis UPDATE si l'endpoint existe déjà.
-- Sans policy UPDATE, le RLS bloque la mise à jour → 403.

CREATE POLICY "push_subs_update_own" ON public.push_subscriptions
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
