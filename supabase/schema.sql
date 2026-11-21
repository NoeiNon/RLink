-- ==============================================================================
-- RF-BUILDERS (RLINK) - SUPABASE DATABASE SCHEMA
-- ==============================================================================
-- Jalankan skrip SQL ini di Supabase Dashboard -> SQL Editor -> New Query -> Run
-- Skrip ini akan membuat tabel, relasi, RLS (Row Level Security), trigger,
-- dan konfigurasi storage untuk blueprint.
-- ==============================================================================

-- 1. TABEL PROFIL PENGGUNA (Terkoneksi dengan auth.users Supabase)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- Trigger otomatis untuk membuat profile saat ada user baru terdaftar di auth.users
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

-- 3. TABEL ANGGOTA SERVER (ADMIN / BUILDER)
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

-- 7. TABEL PEKERJA PROJEK (WORKERS)
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
-- STORAGE BUCKETS (Untuk file Blueprint & Foto Progress)
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('blueprints', 'blueprints', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policy agar user terotentikasi dapat upload dan publik dapat melihat
DROP POLICY IF EXISTS "Public view blueprints" ON storage.objects;
CREATE POLICY "Public view blueprints" ON storage.objects
    FOR SELECT USING (bucket_id = 'blueprints');

DROP POLICY IF EXISTS "Authenticated users upload blueprints" ON storage.objects;
CREATE POLICY "Authenticated users upload blueprints" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'blueprints' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users delete blueprints" ON storage.objects;
CREATE POLICY "Authenticated users delete blueprints" ON storage.objects
    FOR DELETE USING (bucket_id = 'blueprints' AND auth.role() = 'authenticated');

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
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

-- Profiles: Bebas dibaca, bisa diinsert saat register, dan diupdate oleh pemilik
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow insert profile" ON public.profiles;
CREATE POLICY "Allow insert profile" ON public.profiles
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (true) WITH CHECK (true);

-- Servers: Semua authenticated user bisa membaca info server (untuk cari token & gabung)
DROP POLICY IF EXISTS "Members can view servers" ON public.servers;
CREATE POLICY "Members can view servers" ON public.servers
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "Users can create servers" ON public.servers
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Admins can update servers" ON public.servers
    FOR UPDATE TO authenticated
    USING (
        created_by = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.server_members
            WHERE server_members.server_id = servers.id
              AND server_members.user_id = auth.uid()
              AND server_members.role = 'admin'
        )
    );

-- Server Members:
DROP POLICY IF EXISTS "Members can view other members" ON public.server_members;
DROP POLICY IF EXISTS "Users can join servers" ON public.server_members;
DROP POLICY IF EXISTS "Members or admins can leave or kick" ON public.server_members;

CREATE POLICY "Members can view server members" ON public.server_members
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can join servers" ON public.server_members
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Members or admins can leave or kick" ON public.server_members
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- Projects & Content: Akses untuk member server
CREATE POLICY "Server members view projects" ON public.projects
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.server_members
            WHERE server_members.server_id = projects.server_id
              AND server_members.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can insert projects" ON public.projects
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.server_members
            WHERE server_members.server_id = projects.server_id
              AND server_members.user_id = auth.uid()
              AND server_members.role = 'admin'
        )
    );

CREATE POLICY "Admins and workers can update projects" ON public.projects
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.server_members
            WHERE server_members.server_id = projects.server_id
              AND server_members.user_id = auth.uid()
        )
    );

-- Server Messages:
CREATE POLICY "Server members view messages" ON public.server_messages
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.server_members
            WHERE server_members.server_id = server_messages.server_id
              AND server_members.user_id = auth.uid()
        )
    );

CREATE POLICY "Server members send messages" ON public.server_messages
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.server_members
            WHERE server_members.server_id = server_messages.server_id
              AND server_members.user_id = auth.uid()
        )
    );

-- SOP:
CREATE POLICY "Server members view SOP" ON public.server_sops
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.server_members
            WHERE server_members.server_id = server_sops.server_id
              AND server_members.user_id = auth.uid()
        )
    );

CREATE POLICY "Server admins modify SOP" ON public.server_sops
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.server_members
            WHERE server_members.server_id = server_sops.server_id
              AND server_members.user_id = auth.uid()
              AND server_members.role = 'admin'
        )
    );

-- Project Workers:
CREATE POLICY "Members view workers" ON public.project_workers
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Builders can claim" ON public.project_workers
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Project Updates & Blueprints:
CREATE POLICY "Members view updates" ON public.project_updates
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Workers send updates" ON public.project_updates
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Members view blueprints" ON public.project_blueprints
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins insert blueprints" ON public.project_blueprints
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Members view update photos" ON public.update_photos
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Workers insert update photos" ON public.update_photos
    FOR ALL TO authenticated USING (true);

-- Payroll:
CREATE POLICY "Members view payroll" ON public.payroll_ratings
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins modify payroll" ON public.payroll_ratings
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Members view payouts" ON public.payroll_payouts
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins modify payouts" ON public.payroll_payouts
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Members view payout receipts" ON public.payroll_payout_receipts
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins modify payout receipts" ON public.payroll_payout_receipts
    FOR ALL TO authenticated USING (true);

CREATE POLICY "Members view slip lines" ON public.payroll_slip_lines
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins modify slip lines" ON public.payroll_slip_lines
    FOR ALL TO authenticated USING (true);

-- ==============================================================================
-- MASTER GRANTS (Memberi hak akses tabel ke role Supabase)
-- ==============================================================================
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO postgres, anon, authenticated, service_role;

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

    -- Cari server berdasarkan token
    SELECT * INTO target_server FROM public.servers
    WHERE UPPER(token) = UPPER(TRIM(token_input));

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Token server tidak ditemukan. Cek lagi atau hubungi admin server.';
    END IF;

    -- Cek apakah sudah jadi anggota
    SELECT * INTO already_member FROM public.server_members
    WHERE server_id = target_server.id AND user_id = current_uid;

    IF FOUND THEN
        IF already_member.role = 'admin' THEN
            RAISE EXCEPTION 'Kamu adalah admin di server ini.';
        ELSE
            RAISE EXCEPTION 'Kamu sudah bergabung di server ini.';
        END IF;
    END IF;

    -- Cek batas bergabung (maks 5 server sebagai builder)
    SELECT COUNT(*) INTO builder_count FROM public.server_members
    WHERE user_id = current_uid AND role = 'builder';

    IF builder_count >= 5 THEN
        RAISE EXCEPTION 'Kamu sudah bergabung di 5 server (batas maksimum). Tinggalkan salah satu dulu.';
    END IF;

    -- Tambahkan anggota baru sebagai builder
    INSERT INTO public.server_members (server_id, user_id, role)
    VALUES (target_server.id, current_uid, 'builder');

    RETURN to_jsonb(target_server);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
