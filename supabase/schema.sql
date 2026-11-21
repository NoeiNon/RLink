-- ==============================================================================
-- RF-BUILDERS (RLINK) - SUPABASE DATABASE SCHEMA (FULL UNLOCKED)
-- ==============================================================================

-- 1. TABEL PROFIL PENGGUNA
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO UPDATE
    SET username = EXCLUDED.username;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. TABEL SERVER / WORKSPACE
CREATE TABLE IF NOT EXISTS public.servers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    token TEXT UNIQUE NOT NULL,
    color_index INT DEFAULT 0 NOT NULL,
    icon_index INT DEFAULT 0 NOT NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- 3. TABEL ANGGOTA SERVER
CREATE TABLE IF NOT EXISTS public.server_members (
    server_id UUID REFERENCES public.servers(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'builder')),
    joined_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    PRIMARY KEY (server_id, user_id)
);

-- 4. TABEL SOP KERJA SERVER
CREATE TABLE IF NOT EXISTS public.server_sops (
    server_id UUID PRIMARY KEY REFERENCES public.servers(id) ON DELETE CASCADE,
    text TEXT DEFAULT '' NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

-- 5. TABEL DISKUSI / CHAT SERVER
CREATE TABLE IF NOT EXISTS public.server_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id UUID REFERENCES public.servers(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    author_name TEXT NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE NOT NULL,
    text TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- 6. TABEL PROJEK BUILDER
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id UUID REFERENCES public.servers(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    from_client TEXT NOT NULL,
    payment_amount BIGINT DEFAULT 0 NOT NULL,
    payment_note TEXT DEFAULT '' NOT NULL,
    detail TEXT NOT NULL,
    deadline TIMESTAMPTZ NOT NULL,
    max_workers INT DEFAULT 1 NOT NULL,
    author_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL,
    status TEXT DEFAULT 'available' NOT NULL CHECK (status IN ('available', 'onProgress', 'review', 'finished')),
    tags TEXT[] DEFAULT '{}'::TEXT[] NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- 7. TABEL PEKERJA PROJEK
CREATE TABLE IF NOT EXISTS public.project_workers (
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    worker_name TEXT NOT NULL,
    joined_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    PRIMARY KEY (project_id, user_id)
);

-- 8. TABEL UPDATE PROGRESS PROJEK
CREATE TABLE IF NOT EXISTS public.project_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL,
    text TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- 9. TABEL BLUEPRINT / GAMBAR ATTACHMENT
CREATE TABLE IF NOT EXISTS public.project_blueprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.update_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    update_id UUID REFERENCES public.project_updates(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- 10. TABEL GAJI & SLIP (PAYROLL)
CREATE TABLE IF NOT EXISTS public.payroll_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id UUID REFERENCES public.servers(id) ON DELETE CASCADE NOT NULL,
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
    worker_name TEXT NOT NULL,
    score INT CHECK (score BETWEEN 1 AND 10) NOT NULL,
    overall INT CHECK (overall BETWEEN 1 AND 10) NOT NULL,
    amount BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    UNIQUE (server_id, project_id, worker_name)
);

CREATE TABLE IF NOT EXISTS public.payroll_payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id UUID REFERENCES public.servers(id) ON DELETE CASCADE NOT NULL,
    number INT NOT NULL,
    worker_name TEXT NOT NULL,
    paid_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.payroll_payout_receipts (
    payout_id UUID REFERENCES public.payroll_payouts(id) ON DELETE CASCADE NOT NULL,
    rating_id UUID REFERENCES public.payroll_ratings(id) ON DELETE CASCADE NOT NULL,
    PRIMARY KEY (payout_id, rating_id)
);

CREATE TABLE IF NOT EXISTS public.payroll_slip_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payout_id UUID REFERENCES public.payroll_payouts(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('bonus', 'deduction')),
    label TEXT NOT NULL,
    amount BIGINT NOT NULL
);

-- ==============================================================================
-- STORAGE BUCKET BLUEPRINTS
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('blueprints', 'blueprints', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ==============================================================================
-- MASTER GRANTS (Hak akses tabel ke role Supabase)
-- ==============================================================================
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO postgres, anon, authenticated, service_role;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES - DIBUKA PENUH UNTUK AUTHENTICATED
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.server_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.server_sops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.server_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_blueprints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.update_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_payout_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_slip_lines ENABLE ROW LEVEL SECURITY;

-- Profiles
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Allow insert profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow insert profile" ON public.profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (true) WITH CHECK (true);

-- Servers & Members
DROP POLICY IF EXISTS "Members can view servers" ON public.servers;
DROP POLICY IF EXISTS "Users can create servers" ON public.servers;
DROP POLICY IF EXISTS "Admins can update servers" ON public.servers;
CREATE POLICY "Allow all servers" ON public.servers FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Members can view server members" ON public.server_members;
DROP POLICY IF EXISTS "Users can join servers" ON public.server_members;
DROP POLICY IF EXISTS "Members or admins can leave or kick" ON public.server_members;
CREATE POLICY "Allow all server_members" ON public.server_members FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Projects, Workers, Updates, Blueprints (UNLOCKED)
DROP POLICY IF EXISTS "Server members view projects" ON public.projects;
DROP POLICY IF EXISTS "Admins can insert projects" ON public.projects;
DROP POLICY IF EXISTS "Admins and workers can update projects" ON public.projects;
DROP POLICY IF EXISTS "Allow all projects" ON public.projects;
CREATE POLICY "Allow all projects" ON public.projects FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Members view workers" ON public.project_workers;
DROP POLICY IF EXISTS "Builders can claim" ON public.project_workers;
DROP POLICY IF EXISTS "Allow all project_workers" ON public.project_workers;
CREATE POLICY "Allow all project_workers" ON public.project_workers FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Members view updates" ON public.project_updates;
DROP POLICY IF EXISTS "Workers send updates" ON public.project_updates;
DROP POLICY IF EXISTS "Allow all project_updates" ON public.project_updates;
CREATE POLICY "Allow all project_updates" ON public.project_updates FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Members view blueprints" ON public.project_blueprints;
DROP POLICY IF EXISTS "Admins insert blueprints" ON public.project_blueprints;
DROP POLICY IF EXISTS "Allow all project_blueprints" ON public.project_blueprints;
CREATE POLICY "Allow all project_blueprints" ON public.project_blueprints FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Members view update photos" ON public.update_photos;
DROP POLICY IF EXISTS "Workers insert update photos" ON public.update_photos;
DROP POLICY IF EXISTS "Allow all update_photos" ON public.update_photos;
CREATE POLICY "Allow all update_photos" ON public.update_photos FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Messages & SOP
DROP POLICY IF EXISTS "Server members view messages" ON public.server_messages;
DROP POLICY IF EXISTS "Server members send messages" ON public.server_messages;
DROP POLICY IF EXISTS "Allow all server_messages" ON public.server_messages;
CREATE POLICY "Allow all server_messages" ON public.server_messages FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Server members view SOP" ON public.server_sops;
DROP POLICY IF EXISTS "Server admins modify SOP" ON public.server_sops;
DROP POLICY IF EXISTS "Allow all server_sops" ON public.server_sops;
CREATE POLICY "Allow all server_sops" ON public.server_sops FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Payroll
DROP POLICY IF EXISTS "Members view payroll" ON public.payroll_ratings;
DROP POLICY IF EXISTS "Admins modify payroll" ON public.payroll_ratings;
DROP POLICY IF EXISTS "Allow all payroll_ratings" ON public.payroll_ratings;
CREATE POLICY "Allow all payroll_ratings" ON public.payroll_ratings FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Members view payouts" ON public.payroll_payouts;
DROP POLICY IF EXISTS "Admins modify payouts" ON public.payroll_payouts;
DROP POLICY IF EXISTS "Allow all payroll_payouts" ON public.payroll_payouts;
CREATE POLICY "Allow all payroll_payouts" ON public.payroll_payouts FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Members view payout receipts" ON public.payroll_payout_receipts;
DROP POLICY IF EXISTS "Admins modify payout receipts" ON public.payroll_payout_receipts;
DROP POLICY IF EXISTS "Allow all payroll_payout_receipts" ON public.payroll_payout_receipts;
CREATE POLICY "Allow all payroll_payout_receipts" ON public.payroll_payout_receipts FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Members view slip lines" ON public.payroll_slip_lines;
DROP POLICY IF EXISTS "Admins modify slip lines" ON public.payroll_slip_lines;
DROP POLICY IF EXISTS "Allow all payroll_slip_lines" ON public.payroll_slip_lines;
CREATE POLICY "Allow all payroll_slip_lines" ON public.payroll_slip_lines FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Storage Policies
DROP POLICY IF EXISTS "Public view blueprints" ON storage.objects;
DROP POLICY IF EXISTS "Allow upload blueprints" ON storage.objects;
DROP POLICY IF EXISTS "Allow delete blueprints" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users upload blueprints" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users delete blueprints" ON storage.objects;

CREATE POLICY "Public view blueprints" ON storage.objects FOR SELECT USING (bucket_id = 'blueprints');
CREATE POLICY "Allow upload blueprints" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'blueprints');
CREATE POLICY "Allow delete blueprints" ON storage.objects FOR ALL USING (bucket_id = 'blueprints');

-- Function Join Server
CREATE OR REPLACE FUNCTION public.join_server_by_token(token_input TEXT)
RETURNS jsonb AS $$
DECLARE
    target_server RECORD;
    current_uid UUID := auth.uid();
    already_member RECORD;
    builder_count INT;
BEGIN
    IF current_uid IS NULL THEN
        RAISE EXCEPTION 'Pengguna belum terautentikasi.';
    END IF;

    SELECT * INTO target_server FROM public.servers
    WHERE UPPER(token) = UPPER(TRIM(token_input));

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Token server tidak ditemukan. Cek lagi atau hubungi admin server.';
    END IF;

    SELECT * INTO already_member FROM public.server_members
    WHERE server_id = target_server.id AND user_id = current_uid;

    IF FOUND THEN
        IF already_member.role = 'admin' THEN
            RAISE EXCEPTION 'Kamu adalah admin di server ini.';
        ELSE
            RAISE EXCEPTION 'Kamu sudah bergabung di server ini.';
        END IF;
    END IF;

    SELECT COUNT(*) INTO builder_count FROM public.server_members
    WHERE user_id = current_uid AND role = 'builder';

    IF builder_count >= 5 THEN
        RAISE EXCEPTION 'Kamu sudah bergabung di 5 server (batas maksimum). Tinggalkan salah satu dulu.';
    END IF;

    INSERT INTO public.server_members (server_id, user_id, role)
    VALUES (target_server.id, current_uid, 'builder');

    RETURN to_jsonb(target_server);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
