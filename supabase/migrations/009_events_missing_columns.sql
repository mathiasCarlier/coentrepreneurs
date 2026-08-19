-- Migration 009 : Colonnes manquantes dans la table events
-- file_name et collation_menu_text utilisées par le modèle Flutter mais absentes du schéma

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS file_name TEXT,
  ADD COLUMN IF NOT EXISTS collation_menu_text TEXT;
