-- Migration 008 : Politiques RLS pour le storage bucket 'events'

-- Lecture publique (SELECT) — déjà couvert par le bucket public, mais explicite ici
CREATE POLICY "events_storage_select"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'events');

-- Upload (INSERT) — admins uniquement
CREATE POLICY "events_storage_insert_admin"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'events'
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Mise à jour (UPDATE) — admins uniquement
CREATE POLICY "events_storage_update_admin"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'events'
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Suppression (DELETE) — admins uniquement
CREATE POLICY "events_storage_delete_admin"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'events'
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
