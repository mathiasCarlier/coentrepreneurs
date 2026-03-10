-- Migration 005 : Ajout du parrainage (pour badge Ambassadeur)

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS parrain_id uuid REFERENCES public.users(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.users.parrain_id IS 'ID du membre qui a parrainé cet adhérent';

-- Policy RLS : un adhérent peut mettre à jour son propre parrain_id
-- (déjà couvert par la policy users_update existante)
