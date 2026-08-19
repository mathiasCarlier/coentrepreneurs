-- Migration 004 : Ajout des colonnes member_since et passions dans la table users

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS member_since date,
  ADD COLUMN IF NOT EXISTS passions text;

COMMENT ON COLUMN public.users.member_since IS 'Date de première adhésion à l''association (saisie par l''adhérent)';
COMMENT ON COLUMN public.users.passions IS 'Centres d''intérêt / passions de l''adhérent';
