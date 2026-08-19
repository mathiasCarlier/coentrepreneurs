-- =============================================================
-- Migration 011 : durcissement sécurité
--
-- Corrige l'escalade de privilèges : la policy "users_update_own"
-- (migration 001) autorise un utilisateur à modifier SA PROPRE ligne
-- sans restreindre les colonnes. Un membre peut donc s'auto-promouvoir
-- admin via  PATCH /rest/v1/users?id=eq.<son_uid>  {"role":"admin"}.
--
-- Une policy RLS ne sait pas figer une colonne : on passe par un
-- trigger BEFORE UPDATE, qui restaure les colonnes sensibles à leur
-- ancienne valeur quand l'appelant n'est pas admin.
--
-- Idempotent : rejouable sans risque.
-- =============================================================

-- ---------------------------------------------------------------
-- Helper : rôle JWT de l'appelant ('anon', 'authenticated',
-- 'service_role', ou NULL pour une connexion psql directe).
-- Gère les deux formats de claims selon la version de GoTrue.
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_jwt_role()
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  r TEXT;
BEGIN
  r := current_setting('request.jwt.claim.role', true);
  IF r IS NULL OR r = '' THEN
    BEGIN
      r := current_setting('request.jwt.claims', true)::json ->> 'role';
    EXCEPTION WHEN OTHERS THEN
      r := NULL;
    END;
  END IF;
  RETURN nullif(r, '');
END;
$$;

-- ---------------------------------------------------------------
-- Trigger : fige role / blocked / approval_status / approved_at
-- pour tout appelant qui n'est pas admin.
--
-- SECURITY DEFINER est indispensable : le SELECT sur public.users
-- doit contourner la RLS, sinon la policy de users se rappelle
-- elle-même (erreur « infinite recursion detected in policy »).
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_privilege_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  jwt_role TEXT := public.current_jwt_role();
BEGIN
  -- service_role (Edge Functions, webhooks) et connexions psql
  -- directes (sans JWT) conservent tous leurs droits.
  IF jwt_role IS NULL OR jwt_role = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Un admin peut tout modifier, y compris sur les autres comptes.
  IF EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN NEW;
  END IF;

  -- Tous les autres : les colonnes de privilège sont ignorées
  -- silencieusement (l'UPDATE réussit, mais ne les change pas).
  NEW.role            := OLD.role;
  NEW.blocked         := OLD.blocked;
  NEW.approval_status := OLD.approval_status;
  NEW.approved_at     := OLD.approved_at;
  NEW.id              := OLD.id;
  NEW.email           := OLD.email;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_privilege_columns ON public.users;
CREATE TRIGGER trg_protect_privilege_columns
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_privilege_columns();

-- ---------------------------------------------------------------
-- Ceinture + bretelles : la policy 001 n'avait pas de WITH CHECK.
-- Sans lui, Postgres réutilise le USING — un utilisateur ne peut
-- donc pas « donner » sa ligne à quelqu'un d'autre, mais on le rend
-- explicite pour que l'intention soit lisible.
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "users_update_own" ON public.users;
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = id
    OR EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.role = 'admin')
  )
  WITH CHECK (
    auth.uid() = id
    OR EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.role = 'admin')
  );

-- ---------------------------------------------------------------
-- Lecture de l'annuaire : réservée aux comptes connectés.
-- La migration 001 utilisait USING (true) sans clause TO, ce qui
-- inclut le rôle 'anon' — donc n'importe qui muni de la clé anon
-- (publique, embarquée dans le bundle web) pouvait aspirer emails
-- et téléphones. La prod semble déjà durcie ; on aligne le dépôt.
-- ---------------------------------------------------------------
DROP POLICY IF EXISTS "users_select" ON public.users;
CREATE POLICY "users_select" ON public.users
  FOR SELECT
  TO authenticated
  USING (true);

-- Même logique pour les tables laissées en USING (true) sans TO.
DROP POLICY IF EXISTS "events_select" ON public.events;
CREATE POLICY "events_select" ON public.events
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "registrations_select" ON public.registrations;
CREATE POLICY "registrations_select" ON public.registrations
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "invitations_select" ON public.invitations;
CREATE POLICY "invitations_select" ON public.invitations
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "feedbacks_select" ON public.feedbacks;
CREATE POLICY "feedbacks_select" ON public.feedbacks
  FOR SELECT TO authenticated USING (true);

-- ---------------------------------------------------------------
-- Vérification post-application (à lancer manuellement) :
--
--   SELECT policyname, cmd, roles, qual, with_check
--   FROM pg_policies WHERE schemaname='public' AND tablename='users';
--
--   SELECT tgname, tgenabled FROM pg_trigger
--   WHERE tgrelid = 'public.users'::regclass AND NOT tgisinternal;
-- ---------------------------------------------------------------
