# RLink

Aplikasi Flutter (mobile dan web) yang mempertemukan pencari kerja, penjual, supplier, dan pembangun komunitas di satu tempat.

> **Status: dalam pengembangan.** Sebagian fitur sudah berjalan, sebagian masih direncanakan. Lihat daftar di bawah.

## Ide Utama

RLink dibuat untuk orang yang ingin:

- **Mencari pekerjaan**: melihat info lowongan kerja (loker).
- **Berjualan**: memasarkan barang sendiri atau menjadi supplier.
- **Membentuk tim**: mengumpulkan rekan untuk project bisnis.
- **Membangun komunitas**: membuat dan mengelola komunitas sendiri.

## Status Fitur

| Fitur | Status |
| --- | --- |
| Login dan daftar akun | Sudah ada |
| Buat atau gabung server (tim/komunitas) | Sudah ada (tahap awal) |
| Project dalam server (buat, lihat detail) | Sudah ada (tahap awal) |
| Info lowongan kerja | Direncanakan |
| Jual barang dan supplier | Direncanakan |
| Tim untuk project bisnis | Direncanakan |
| Komunitas | Direncanakan |

> Daftar ini akan diperbarui seiring perkembangan.

## Teknologi

- [Flutter](https://flutter.dev) (Material 3, tema gelap), untuk Android, iOS, dan web
- [Supabase](https://supabase.com) sebagai backend (autentikasi dan database)
- Mode **mock** (data lokal) bila Supabase belum dikonfigurasi, sehingga aplikasi tetap bisa dicoba tanpa backend
- Versi web di-deploy di [Vercel](https://vercel.com)

## Struktur Singkat

```
lib/
  core/       tema, validator, sesi
  data/       penyimpanan data (mock dan Supabase)
  screens/    halaman (login, register, home, dan lainnya)
  widgets/    komponen UI bersama
```

## Kontribusi

Proyek ini masih tahap awal. Saran dan masukan dipersilakan lewat Issues.

## Lisensi

Belum ditentukan.
