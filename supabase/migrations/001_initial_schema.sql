-- =============================================================
-- Migration initiale : schéma Coentrepreneurs
-- =============================================================

-- ---------------------------------------------------------------
-- TABLE : users (étend auth.users de Supabase)
-- ---------------------------------------------------------------
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  nom TEXT NOT NULL DEFAULT '',
  prenom TEXT NOT NULL DEFAULT '',
  phone TEXT,
  photo_url TEXT,
  role TEXT NOT NULL DEFAULT 'invite' CHECK (role IN ('admin', 'adherent', 'invite')),
  company_name TEXT,
  skills TEXT,
  professional_address TEXT,
  website TEXT,
  share_pro_info BOOLEAN DEFAULT false,
  blocked BOOLEAN DEFAULT false,
  approval_status TEXT DEFAULT NULL CHECK (approval_status IN ('pending', 'approved', 'rejected') OR approval_status IS NULL),
  approved_at TIMESTAMPTZ,
  read_notification_event_ids TEXT[] DEFAULT '{}',
  read_notification_message_ids TEXT[] DEFAULT '{}',
  read_new_member_ids TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger : créer une ligne dans public.users à chaque inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------
-- TABLE : events
-- ---------------------------------------------------------------
CREATE TABLE public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date TIMESTAMPTZ NOT NULL,
  theme TEXT NOT NULL,
  intervenant TEXT,
  entreprise TEXT,
  lieu TEXT NOT NULL,
  max_participants INTEGER NOT NULL DEFAULT 20,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'started', 'finished')),
  summary TEXT,
  description TEXT,
  link_url TEXT,
  image_url TEXT,
  file_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ---------------------------------------------------------------
-- TABLE : registrations
-- Remplace les arrays Firestore : registeredUserIds, confirmedParticipants,
-- declinedUserIds, collationParticipants
-- ---------------------------------------------------------------
CREATE TABLE public.registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'registered' CHECK (status IN ('registered', 'confirmed', 'declined')),
  has_collation BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  UNIQUE(event_id, user_id)
);

-- ---------------------------------------------------------------
-- TABLE : invitations
-- ---------------------------------------------------------------
CREATE TABLE public.invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  invited_by_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  invited_user_email TEXT NOT NULL,
  invited_user_prenom TEXT NOT NULL,
  invited_user_nom TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ
);

-- ---------------------------------------------------------------
-- TABLE : feedbacks
-- ---------------------------------------------------------------
CREATE TABLE public.feedbacks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  user_email TEXT NOT NULL,
  user_prenom TEXT NOT NULL,
  user_nom TEXT NOT NULL,
  what_you_liked TEXT,
  rating INTEGER CHECK (rating >= 0 AND rating <= 10),
  what_you_learned TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);

-- ---------------------------------------------------------------
-- TABLE : cgu_acceptances
-- ---------------------------------------------------------------
CREATE TABLE public.cgu_acceptances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  has_accepted BOOLEAN NOT NULL DEFAULT false,
  accepted_date TEXT,
  cgu_version TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, cgu_version)
);

-- ---------------------------------------------------------------
-- TABLE : messages
-- Messages envoyés par les utilisateurs via le formulaire de contact
-- ---------------------------------------------------------------
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  user_name TEXT NOT NULL,
  user_email TEXT NOT NULL,
  user_role TEXT,
  category TEXT NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  published BOOLEAN DEFAULT false,
  link_url TEXT,
  image_url TEXT,
  file_url TEXT,
  file_name TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ---------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ---------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cgu_acceptances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- users : lecture publique (pour afficher les profils), modification soi-même ou admin
CREATE POLICY "users_select" ON public.users FOR SELECT USING (true);
CREATE POLICY "users_insert_own" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "users_update_own" ON public.users FOR UPDATE USING (
  auth.uid() = id OR
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- events : lecture publique, insertion/modification pour les admins
CREATE POLICY "events_select" ON public.events FOR SELECT USING (true);
CREATE POLICY "events_insert_admin" ON public.events FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "events_update_admin" ON public.events FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "events_delete_admin" ON public.events FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- registrations : lecture publique, modification par l'utilisateur concerné ou admin
CREATE POLICY "registrations_select" ON public.registrations FOR SELECT USING (true);
CREATE POLICY "registrations_insert" ON public.registrations FOR INSERT WITH CHECK (
  auth.uid() = user_id OR
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "registrations_update" ON public.registrations FOR UPDATE USING (
  auth.uid() = user_id OR
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "registrations_delete" ON public.registrations FOR DELETE USING (
  auth.uid() = user_id OR
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- invitations : lecture publique, modification par invitant ou admin
CREATE POLICY "invitations_select" ON public.invitations FOR SELECT USING (true);
CREATE POLICY "invitations_insert" ON public.invitations FOR INSERT WITH CHECK (
  auth.uid() = invited_by_user_id OR
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "invitations_update" ON public.invitations FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('admin', 'adherent'))
);
CREATE POLICY "invitations_delete" ON public.invitations FOR DELETE USING (
  auth.uid() = invited_by_user_id OR
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- feedbacks : lecture publique, modification par le créateur ou admin
CREATE POLICY "feedbacks_select" ON public.feedbacks FOR SELECT USING (true);
CREATE POLICY "feedbacks_insert" ON public.feedbacks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "feedbacks_update" ON public.feedbacks FOR UPDATE USING (
  auth.uid() = user_id OR
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "feedbacks_delete" ON public.feedbacks FOR DELETE USING (
  auth.uid() = user_id OR
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);

-- cgu_acceptances : lecture/écriture par le propriétaire uniquement
CREATE POLICY "cgu_select" ON public.cgu_acceptances FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "cgu_insert" ON public.cgu_acceptances FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "cgu_update" ON public.cgu_acceptances FOR UPDATE USING (auth.uid() = user_id);

-- messages : insertion par tout utilisateur connecté, lecture/modification/suppression par admin uniquement
CREATE POLICY "messages_insert" ON public.messages FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "messages_select_admin" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "messages_update_admin" ON public.messages FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "messages_delete_admin" ON public.messages FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
);
-- Les messages publiés sont visibles par tous les utilisateurs connectés (pour les notifications)
CREATE POLICY "messages_select_published" ON public.messages FOR SELECT USING (
  published = true AND auth.uid() IS NOT NULL
);
