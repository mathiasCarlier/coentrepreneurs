-- Migration 007 : lecture individuelle des messages par admin
-- Remplace le booléen partagé `read` par un tableau `read_by` (liste des admin UIDs qui ont lu)

ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS read_by TEXT[] DEFAULT '{}';

-- Migrer les messages déjà marqués comme lus (read = true) :
-- On ne peut pas savoir quel admin les a lus, donc on laisse read_by vide.
-- L'ancien booléen read est conservé pour compatibilité mais n'est plus utilisé par l'app.
