# CineList: Katalog Film dan Watchlist Pribadi

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![TMDB](https://img.shields.io/badge/API-TMDB%20v3-01D277?logo=themoviedatabase&logoColor=white)](https://www.themoviedb.org)

> **Tugas Ujian Tengah Semester (UTS) Pemrograman Mobile**  
> **Dosen Pengampu:** Dr. Ir. I Ketut Resika Arthana, S.T., M.Kom  
> **Nama:** Dewa Putu Bagus Mahadinata  
> **NIM:** 2415051023  
> **Kelas:** PTI 5 IKI  
> **Program Studi:** Pendidikan Teknik Informatika  
> **Universitas:** Universitas Pendidikan Ganesha  

---

## 📌 Deskripsi Proyek
**CineList** adalah aplikasi mobile berbasis Flutter untuk menjelajahi katalog film dunia dan mengelola daftar tontonan pribadi secara interaktif.

Aplikasi ini menerapkan pemisahan peran yang tegas antara dua sumber data:
1. **REST API TMDB (The Movie Database):** Berfungsi sebagai sumber katalog data publik (daftar film trending mingguan, pencarian film real-time, filter genre, dan sinopsis lengkap).
2. **Database Supabase (PostgreSQL):** Berfungsi khusus menyimpan data personal milik pengguna (watchlist film, rating pribadi 1–10, catatan/review, status sudah ditonton, dan jadwal pengingat nonton).

---

## 🌟 Fitur Utama
- **Katalog Film Trending:** Hero carousel responsif bergaya IDLIX dan daftar film terpopuler.
- **Pencarian Film Real-time:** Pencarian cepat berdasarkan judul film melalui TMDB API.
- **Filter Berdasarkan Genre:** Filter instan kategori Action, Drama, Comedy, Horror, Sci-Fi.
- **Detail Film Lengkap:** Poster beresolusi tinggi, tahun rilis, rating TMDB, sinopsis cerita, dan indikator status watchlist.
- **CRUD Watchlist Personal (Supabase):**
  - **Create:** Menambahkan film ke watchlist dengan status tontonan dan pengingat.
  - **Read:** Menampilkan watchlist dengan tab filter (Semua, Belum Ditonton, Sudah Ditonton).
  - **Update:** Mengubah review, rating bintang & slider (1–10), serta status tontonan.
  - **Delete:** Menghapus film dari watchlist dengan dialog konfirmasi keamanan.
- **Pengingat Nonton:** Pengguna dapat mengatur tanggal & jam pengingat untuk film yang ingin ditonton. Jika status diubah menjadi *Sudah Ditonton*, pengingat otomatis dibersihkan.
- **🎲 Rekomendasi Film Acak:** Memilih film secara acak dari daftar yang belum ditonton untuk ditonton malam ini.
- **Layout Responsif Adaptif:**
  - Layar ponsel compact (< 700px): Bottom NavigationBar & grid 3 kolom.
  - Layar lebar/tablet (≥ 700px): Floating Pill Navbar di atas & grid 4–6 kolom.
- **Profil Mahasiswa & Personalisasi:** Ganti foto profil avatar, nama, dan ringkasan statistik tontonan real-time.
- **Pengaturan Aplikasi:** Toggle tema gelap/terang (Dark Mode) beraksen IDLIX Red dan pembersih cache.

---

## 🏗️ Arsitektur Aplikasi
Aplikasi mengadopsi pola arsitektur berlapis (*Clean Layered Architecture*):
```
lib/
├── models/          # Data model Dart (Movie, WatchlistItem)
├── services/        # Komunikasi HTTP TMDB API & Supabase Client
├── repositories/    # Abstraksi data layer (MovieRepository, WatchlistRepository)
├── providers/       # State management Provider & ChangeNotifier
├── screens/         # Tampilan antarmuka layar aplikasi
├── widgets/         # Reusable widgets (MovieCard, RatingBadge, StateViews, ProfileAvatar)
└── main.dart        # Entry point aplikasi & tema Material 3
```

---

## 🛠️ Tech Stack
- **Framework:** Flutter & Dart
- **State Management:** Provider (`MultiProvider`, `ChangeNotifier`)
- **HTTP Client:** `http`
- **Backend / Database:** Supabase PostgreSQL (`supabase_flutter`)
- **Local Storage:** `shared_preferences`
- **Image Picker:** `image_picker`
- **Konfigurasi Lingkungan:** `flutter_dotenv`

---

## 🚀 Cara Menjalankan Aplikasi

1. **Clone repository ini:**
   ```bash
   git clone https://github.com/dotubagus/UTS_2415051023_Dewa_Putu_Bagus_Mahadinata.git
   cd UTS_2415051023_Dewa_Putu_Bagus_Mahadinata
   ```

2. **Pasang seluruh dependensi:**
   ```bash
   flutter pub get
   ```

3. **Buat file `.env` di root proyek:**
   ```env
   TMDB_API_KEY=YOUR_TMDB_API_KEY
   TMDB_ACCESS_TOKEN=YOUR_TMDB_ACCESS_TOKEN
   SUPABASE_URL=YOUR_SUPABASE_URL
   SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```

4. **Jalankan aplikasi:**
   ```bash
   flutter run
   ```
