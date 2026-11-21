# Setup Backend Supabase untuk RF-Builders (Rlink)

Panduan lengkap untuk menghubungkan aplikasi **RF-Builders** ke backend cloud Supabase (PostgreSQL, Auth, Storage, dan Realtime).

---

## 1. Buat Project di Supabase
1. Buka [https://supabase.com](https://supabase.com) dan login/daftar.
2. Klik **New Project**.
3. Beri nama project (contoh: `rf-builders` atau `rlink`) dan tentukan Database Password.
4. Pilih region terdekat (misal: `Singapore`).
5. Tunggu proses setup selesai (~1-2 menit).

---

## 2. Eksekusi Database Schema
1. Di sidebar kiri Supabase Dashboard, klik icon **SQL Editor** (atau tekan icon query).
2. Klik tombol **New query**.
3. Buka file [`schema.sql`](./schema.sql), lalu salin (copy) seluruh kodenya.
4. Tempel (paste) kode ke dalam editor query Supabase.
5. Klik **Run** (atau tekan `Ctrl+Enter` / `Cmd+Enter`).
6. Pastikan muncul pesan sukses: `Success. No rows returned`.

Skrip ini otomatis menyiapkan:
- Tabel: `profiles`, `servers`, `server_members`, `server_sops`, `server_messages`, `projects`, `project_workers`, `project_updates`, `project_blueprints`, `payroll_ratings`, `payroll_payouts`, dll.
- Trigger otomatis saat registrasi user di `auth.users` ke tabel `profiles`.
- Storage bucket `blueprints` untuk gambar blueprint & attachment progress.
- Kebijakan keamanan **Row Level Security (RLS)**.
- Stored procedure `join_server_by_token(token_input)`.

---

## 3. Masukkan Kredensial ke Flutter
1. Di Supabase Dashboard, buka **Project Settings** (icon gerigi di pojok bawah) -> **API**.
2. Salin:
   - **Project URL** (contoh: `https://xxxxxxxxxxxx.supabase.co`)
   - **Project API Keys** -> `anon` / `public`
3. Buka file [`lib/core/supabase_config.dart`](../lib/core/supabase_config.dart) di proyek Flutter Anda.
4. Ganti nilai variabel berikut:
   ```dart
   static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

---

## 4. Mode Operasi Otomatis (Dual-Mode)
Aplikasi RF-Builders dirancang cerdas dengan arsitektur dual-mode:
- **Mode Mock (Offline / Demo):** Selama `supabaseUrl` atau `supabaseAnonKey` belum diisi, aplikasi tetap bisa dijalankan penuh menggunakan in-memory mock store (dengan akun demo `admin@rf.test` dan `builder@rf.test`).
- **Mode Supabase (Live Backend):** Begitu URL dan Anon Key diisi, aplikasi secara otomatis beralih menggunakan backend Supabase tanpa perlu mengubah kode tampilan UI.

---

## 5. Menjalankan Aplikasi
Jalankan aplikasi di browser Chrome atau desktop:
```bash
flutter run -d chrome
```
