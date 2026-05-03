# 🚀 Ultimate Converter & Merger
Aplikasi serbaguna berbasis PowerShell untuk mengonversi, menggabungkan, dan memanipulasi file Dokumen (Word, Excel, PPT, PDF), Gambar, serta Media (Audio & Video) secara otomatis dan mudah.
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/25d6e0db-2f63-4ce4-ac9a-4d6685cae997" />

**Downlod versi lengkap via google drive:**  https://drive.google.com/drive/folders/192bPfg_mQY5o06QiuURqlzxwnyQTQGjU?usp=drive_link 

---

**Informasi Rilis:**
- **Developer:** Riyan
- **Tanggal Rilis:** 4 Mei 2026
- **Versi:** Rilis Pertama (V1)

---

## 🌟 Fitur Utama

Aplikasi ini dibagi menjadi 3 kategori fitur utama:

### 📁 Konversi Dokumen & Foto
1. Word (`.docx`) ke PDF
2. PowerPoint (`.pptx`) ke PDF
3. Excel (`.xlsx`) ke PDF
4. Gambar (`.jpg`, `.png`, dll) ke PDF
5. PDF ke Word (Bisa diedit kembali)

### 📑 Gabung & Pisah Dokumen
6. Gabungkan beberapa file Word
7. Gabungkan beberapa file PowerPoint
8. Gabungkan beberapa file PDF
9. Ekstrak / Pisah halaman tertentu dari PDF

### 🎬 Media (Audio & Video)
10. Konversi Video ke Audio (MP3)
11. Konversi Audio ke Video (Layar Hitam - MP4)
12. Gabungkan beberapa file Audio
13. Gabungkan beberapa file Video

---

## 💻 Persyaratan Sistem (System Requirements)
Agar tools ini berjalan lancar, pastikan komputer/laptop Anda memiliki:
- **Sistem Operasi:** Windows 10 atau Windows 11.
- **Microsoft Office:** Telah terinstal Microsoft Word, Excel, dan PowerPoint (digunakan untuk mesin konversi dokumen).
- **Koneksi Internet (Hanya untuk penggunaan pertama):** Tools akan otomatis mengunduh komponen mesin PDF dan Media (FFmpeg) saat pertama kali dijalankan.

---

## 📖 Panduan Penggunaan (Langkah demi Langkah)

### Tahap 1: Mengunduh Tools
1. Klik tombol hijau **`<> Code`** di atas, lalu pilih **`Download ZIP`**.
2. Ekstrak (Unzip) file yang sudah didownload ke folder mana saja di komputer Anda (misalnya di Desktop atau Documents).

### Tahap 2: Menjalankan Aplikasi
1. Buka folder hasil ekstrak tadi.
2. Cari file bernama **`Jalankan.bat`**.
3. **Klik ganda (Double Click)** pada file `Jalankan.bat` tersebut.
4. Jendela terminal berwarna biru/hitam akan terbuka secara otomatis.

### Tahap 3: Cara Mengonversi / Menggabungkan File
1. **Pindahkan Bahan:** Pindahkan file yang ingin Anda proses (misal: file Word, PDF, atau Video) ke dalam satu folder dengan file `Jalankan.bat`. Aplikasi akan **otomatis memindahkan** file bahan Anda ke dalam folder bernama `PROJECT`.
   *(Catatan: Anda juga bisa memasukkan bahan langsung ke dalam folder `PROJECT`).*
2. **Pilih Menu:** Di layar terminal, Anda akan melihat daftar angka dari 1 hingga 13. Ketik angka sesuai kebutuhan Anda, lalu tekan **Enter**.
3. **Pilih File:** Aplikasi akan mendeteksi file yang ada di folder `PROJECT`. Ketik angka file yang ingin diproses (contoh: ketik `1` untuk file pertama, atau `1,2` untuk beberapa file, atau `A` untuk memilih semua file).
4. **Tunggu Proses:** Bar loading (animasi proses) akan berjalan.
5. **Selesai!** Buka folder bernama **`Hasil`** untuk melihat file yang sudah berhasil dikonversi atau digabung.

---

## 📂 Struktur Folder Otomatis
Saat dijalankan, aplikasi akan otomatis merapikan file Anda ke dalam folder berikut:
- 📁 **`PROJECT`** : Tempat Anda meletakkan file mentahan/bahan yang akan diproses.
- 📁 **`Hasil`** : Tempat file hasil akhir setelah proses konversi/penggabungan selesai.
- 📁 **`ALAT BANTU`** : Folder sistem tempat aplikasi mengunduh mesin pendukung (seperti FFmpeg dan iTextSharp). *Jangan hapus folder ini agar aplikasi tidak perlu mengunduh ulang.*
<img width="951" height="897" alt="image" src="https://github.com/user-attachments/assets/bf9dff02-65b6-4b77-9c5a-e204f4a9f0f6" />


---

## 💡 Catatan Tambahan
* **Aman & Ringan:** Aplikasi ini tidak memerlukan proses instalasi rumit yang memberatkan PC.
* **Otomatis Mengunduh Dependensi:** Jika folder `ALAT BANTU` kosong, aplikasi akan meminta izin untuk mengunduh FFmpeg (untuk video) dan iTextSharp (untuk PDF) dari internet secara otomatis. Pastikan internet menyala saat pertama kali menekan menu!

---
*Dibuat oleh Riyan | © 2026*
