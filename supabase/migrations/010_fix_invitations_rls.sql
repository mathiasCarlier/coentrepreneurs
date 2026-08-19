-- Migration 010 : Correction RLS invitations_update
-- Avant : tout adhérent pouvait modifier n'importe quelle invitation
-- Après : seul le créateur de l'invitation ou un admin peut la modifier

DROP POLICY IF EXISTS "invitations_update" ON public.invitations;

CREATE POLICY "invitations_update" ON public.invitations FOR UPDATE USING (
  auth.uid() = invited_by_user_id OR
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
