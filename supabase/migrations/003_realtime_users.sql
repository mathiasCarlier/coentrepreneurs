-- Migration 003 : Activer Realtime pour la table users
-- Nécessaire pour que le StreamBuilder de DirectoryPageDynamic reçoive les UPDATE

-- REPLICA IDENTITY FULL permet à Supabase Realtime d'envoyer la ligne complète
-- lors des événements UPDATE et DELETE (requis avec RLS)
ALTER TABLE public.users REPLICA IDENTITY FULL;

-- Ajouter la table users à la publication supabase_realtime
-- (si elle n'est pas déjà présente)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'users'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
  END IF;
END $$;
