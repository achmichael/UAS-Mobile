# 📱 App Limiter - Screen Time Management

## 📖 Deskripsi Aplikasi

**App Limiter** adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu pengguna mengelola dan mengontrol waktu penggunaan aplikasi di smartphone mereka. Dengan fitur monitoring screen time dan pengaturan batasan penggunaan aplikasi, App Limiter membantu pengguna membangun kebiasaan digital yang lebih sehat dan produktif.

### 🎯 Tujuan Aplikasi
- Memantau waktu penggunaan aplikasi
- Memberikan visualisasi statistik screen time harian
- Mengatur batasan waktu untuk aplikasi tertentu
- Membantu pengguna mengurangi ketergantungan pada smartphone
- Meningkatkan produktivitas dan kesehatan digital

### 🔑 Fitur Utama
- **Dashboard Interaktif** - Monitoring penggunaan aplikasi dengan visual yang menarik
- **Statistik Screen Time** - Melihat total waktu layar harian
- **Manajemen Batasan** - Mengatur limit waktu untuk aplikasi individual
- **Profil Pengguna** - Pengaturan akun dan preferensi aplikasi
- **Autentikasi** - Sistem login dan registrasi yang aman

---

## 📄 Daftar Halaman dan Fungsinya

### 1. **Get Started** (`/`)
   - **Fungsi**: Halaman landing/splash screen pertama kali aplikasi dibuka
   - **Fitur**: 
     - Menampilkan informasi singkat tentang aplikasi
     - Tombol navigasi ke halaman Login atau Register
     - Desain menarik dengan tema dark mode

### 2. **Login** (`/login`)
   - **Fungsi**: Halaman autentikasi untuk pengguna yang sudah terdaftar
   - **Fitur**:
     - Input email dan password
     - Validasi form login
     - Integrasi dengan backend API untuk autentikasi
     - Token management untuk session pengguna
     - Navigasi ke halaman Register

### 3. **Register** (`/register`)
   - **Fungsi**: Halaman pendaftaran akun baru
   - **Fitur**:
     - Input nama, email, dan password
     - Validasi form registrasi
     - Integrasi dengan backend API
     - Auto-login setelah registrasi berhasil
     - Navigasi ke halaman Login

### 4. **Dashboard** (`/dashboard`)
   - **Fungsi**: Halaman utama untuk monitoring penggunaan aplikasi
   - **Fitur**:
     - Menampilkan total screen time hari ini
     - List aplikasi yang terinstal dengan ikon dan durasi penggunaan
     - Bar chart visual untuk screen time
     - Real-time update data penggunaan
     - Bottom navigation untuk berpindah halaman

### 5. **Limits** (`/limits`)
   - **Fungsi**: Halaman pengaturan batasan waktu aplikasi
   - **Fitur**:
     - List semua aplikasi terinstal
     - Toggle switch untuk mengaktifkan/menonaktifkan limit
     - Kategorisasi aplikasi (Games, Social, Entertainment, dll)
     - Pengaturan durasi limit per aplikasi
     - Tombol save untuk menyimpan pengaturan

### 6. **Profile** (`/profile`)
   - **Fungsi**: Halaman profil dan pengaturan pengguna
   - **Fitur**:
     - Informasi profil pengguna
     - Edit foto profil
     - Toggle notifikasi
     - Pengaturan tema (Dark/Light mode)
     - Tombol logout
     - Privacy policy dan terms of service

---

## 🚀 Langkah-langkah Menjalankan Aplikasi

### Prasyarat
Pastikan sistem Anda sudah terinstall:
- ✅ **Flutter SDK** (versi 3.9.0 atau lebih baru)
- ✅ **Dart SDK** (versi 3.9.0 atau lebih baru)
- ✅ **Android Studio** atau **VS Code** dengan Flutter extension
- ✅ **Android Emulator** atau **Physical Device** (untuk testing)

### Instalasi dan Running

#### 1️⃣ Clone Repository
```bash
git clone https://github.com/achmichael/UAS-Mobile
cd app_limiter
```

#### 2️⃣ Install Dependencies
Jalankan perintah berikut untuk menginstall semua package yang dibutuhkan:
```bash
flutter pub get
```

#### 3️⃣ Konfigurasi Android
Pastikan file `android/local.properties` sudah dikonfigurasi dengan benar dengan path Android SDK Anda.

#### 4️⃣ Jalankan Aplikasi

**Menggunakan Emulator/Device yang sudah terhubung:**
```bash
flutter run
```

**Atau pilih device tertentu:**
```bash
# Lihat daftar device
flutter devices

# Run di device tertentu
flutter run -d <device-id>
```

#### 5️⃣ Build APK (Optional)
Untuk membuat file APK:
```bash
flutter build apk --release
```
File APK akan tersedia di: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📦 Dependencies Utama

| Package | Versi | Fungsi |
|---------|-------|--------|
| `flutter` | SDK | Framework utama |
| `http` | ^1.2.2 | HTTP client untuk API calls |
| `flutter_secure_storage` | ^9.2.4 | Secure storage untuk token |
| `app_usage` | ^4.0.1 | Monitoring penggunaan aplikasi |
| `screen_time` | ^0.10.2 | Tracking screen time |
| `installed_apps` | ^2.0.0 | Mendapatkan list aplikasi terinstal |
| `font_awesome_flutter` | ^10.4.0 | Icon library |
| `art_sweetalert_new` | ^1.0.2 | Beautiful alert dialogs |
| `flutter_svg` | ^2.0.9 | SVG rendering |

---

## 🏗️ Struktur Proyek

```
lib/
├── main.dart                 # Entry point aplikasi
├── screens/                  # Semua halaman UI
│   ├── get_started.dart
│   ├── login.dart
│   ├── register.dart
│   ├── dashboard.dart
│   ├── limits.dart
│   └── profile.dart
├── components/               # Reusable UI components
│   ├── appbar.dart
│   ├── list_item.dart
│   └── screen_time_bar.dart
├── core/                     # Core utilities
│   ├── common/              # Helper functions
│   └── constants/           # Constants (colors, etc)
├── data/                    # Data layer
│   ├── services/           # API services
│   └── dummy/              # Dummy data
└── types/                  # Type definitions
    └── entities.dart
```

---

## 🎨 Color Scheme
Aplikasi menggunakan tema **Dark Mode** dengan color palette:
- Primary: `#1E00FF` (Electric Blue)
- Background: `#0D0D14` (Dark Navy)
- Accent: Deep Purple

---

## 📝 Catatan Pengembangan

### Permission yang Dibutuhkan (Android)
Aplikasi ini memerlukan beberapa permission khusus:
- `QUERY_ALL_PACKAGES` - Untuk mendapatkan list aplikasi terinstal
- `PACKAGE_USAGE_STATS` - Untuk monitoring penggunaan aplikasi
- Screen Time Permission - Untuk tracking waktu layar

Pastikan permission ini sudah ditambahkan di `AndroidManifest.xml`

### Known Issues
- Backend API masih dalam tahap development
- Fitur save limits masih perlu integrasi dengan persistent storage
- Theme switching belum fully implemented

---

## 👨‍💻 Developer

**Nama**: Achmad Michael Mushoharaoin  
**NIM**: 230605110047  
**Mata Kuliah**: Praktikum Mobile Programming  
**Tugas**: UTS - Flutter Application

---

## 📄 License

This project is created for educational purposes as part of UTS assignment.

---

## 📞 Contact & Support

Jika ada pertanyaan atau issue, silakan hubungi melalui:
- Email: [achmadmichael03@gmail.com]
- GitHub: [achmichael]

---

**Last Updated**: October 28, 2025
