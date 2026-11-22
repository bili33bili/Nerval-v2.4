# nerval

Tool CLI untuk **Termux** yang mencadangkan seluruh isi `$HOME` ke penyimpanan lokal perangkat
(`/sdcard/.sys_neban_vault`) dan **menguncinya dengan akun + password**. Jika Termux tidak sengaja
ter-uninstall, pasang ulang, ketik `nerval`, login, dan semua data kembali.

Repo: `bili33ili/nerval` · Versi: **2.4.0**

---

## Fitur

- **Multi-akun** — tiap akun punya username, password, dan vault sendiri. Buat dengan `nerval daftar`.
- **Login sekali, permanen** — `nerval daftar` / `nerval login` meminta `Username` lalu `Tulis password anda:`; jika benar
  muncul `✓ OK` dan Anda tetap masuk di akun itu, di mana pun, sampai menjalankan `nerval logout`. Salah password 3 kali → ditolak.
  Username harus unik.
- **Hapus akun & hapus semua** — `nerval hapus-akun` menghapus akun yang sedang login beserta vault-nya;
  `nerval hapus-semua` menghapus semua akun, vault, data, dan perintah nerval. **File di `$HOME` tidak pernah dihapus.**
- **Kripto** — PBKDF2-HMAC-SHA256 (200.000 iterasi, salt acak) → AES-256-CBC. Backup diverifikasi penuh
  sebelum menggantikan cadangan lama.
- **Tools ikut tersimpan** — daftar paket Termux (mis. `nano`, `python`), `pip`, dan `npm` disimpan di dalam vault
  dan bisa dipasang ulang otomatis setelah restore (`nerval tools`).
- **Tersembunyi** — file vault `.sys_cache_<kode>.bin` tanpa header yang dikenali (tampak seperti data acak),
  nama file tidak memuat username, plus `.nomedia`.
- **Hanya jalan di Termux** — skrip menolak berjalan jika `$PREFIX` tidak mengandung `com.termux`.
- **Auto-sync hemat baterai** — watcher `inotifywait` dengan jeda *debounce* 10 detik.
- **Aman dari kecelakaan** — auto-backup **tidak menimpa vault** pada Termux baru sebelum data dipulihkan.

## Instalasi

```bash
pkg install -y git
git clone https://github.com/bili33ili/nerval.git
cd nerval
bash install.sh
```

Installer: memasang `tar`, `openssl-tool`, `inotify-tools` → meminta izin penyimpanan →
membuat `/sdcard/.sys_neban_vault` + `.nomedia` → memasang `nerval` ke `$PREFIX/bin` →
memasang pengingat di `~/.bashrc` → membuat **akun pertama** (username + password) dan cadangan pertama.

## Penggunaan

| Perintah | Fungsi |
|---|---|
| `nerval daftar` | Buat akun baru + cadangan pertama |
| `nerval login [--ttl MENIT]` | Login & simpan sesi permanen (`--ttl` untuk membatasi waktunya) |
| `nerval logout` | Keluar: hapus sesi & hentikan auto-backup (satu-satunya cara sesi berakhir) |
| `nerval` / `nerval restore` | Login, lalu pulihkan seluruh `$HOME` dari vault akun |
| `nerval restore --keep` | Pulihkan tanpa menimpa file yang sudah ada |
| `nerval restore --no-tools` | Pulihkan tanpa menawarkan pasang ulang tools |
| `nerval backup` | Cadangkan & kunci seluruh `$HOME` ke vault akun |
| `nerval backup --force` | Timpa vault lama walau `$HOME` belum dipulihkan |
| `nerval hide` | Amankan `$HOME` ke vault tersembunyi sekarang juga |
| `nerval tools` | Pasang ulang tools (nano, python, dll.) dari daftar di vault |
| `nerval tools list` | Lihat daftar tools yang tersimpan |
| `nerval tools skip` | Abaikan daftar tools hasil restore |
| `nerval status` | Status akun, auto-backup, waktu cadangan terakhir, ukuran vault |
| `nerval auto on` / `off` | Hidupkan / matikan auto-backup |
| `nerval passwd` | Ganti password akun |
| `nerval hapus-akun` | Hapus akun yang login + vault-nya (ketik username untuk konfirmasi) |
| `nerval hapus-semua` | Hapus SEMUA akun, vault, data, dan perintah nerval (ketik `HAPUS SEMUA`) |
| `nerval reset` | Hapus akun yang lupa password, tanpa login (ketik `HAPUS`) |
| `nerval version` / `help` | Versi / bantuan (tanpa login) |

Username: 3–24 karakter (huruf kecil, angka, `_`, `.`, `-`). Vault versi 2.0 lama dibuka dengan username **`utama`**.

`~/storage`, `~/.cache`, dan state `~/.nerval` dikecualikan dari backup agar tidak terjadi *infinite loop*.

## Sesi login (permanen sampai `nerval logout`)

Login cukup sekali. Setelah itu Anda **tetap masuk di akun yang sama** — di folder mana pun, di tab Termux mana pun,
bahkan setelah HP restart — dan `nerval` (backup, restore, status, tools, dll.) langsung berjalan **tanpa password**.
Sesi **tidak berakhir sendiri**; satu-satunya cara keluar adalah menjalankan:

```bash
nerval logout
```

- `nerval daftar` dan `nerval login` otomatis menyimpan sesi permanen. Mau dibatasi? `nerval login --ttl <menit>`
  (berakhir setelah sekian menit tidak dipakai).
- Auto-backup menyala lagi sendiri setiap Termux dibuka selama Anda masih login. `nerval logout` menghapus sesi dan
  menghentikan auto-backup.
- Sesi juga berakhir jika password akun diganti dari tempat lain atau akunnya dihapus.
- Perintah sensitif — `passwd`, `hapus-akun`, `hapus-semua` — **selalu meminta password lagi** walau sudah login.
- Satu sesi = satu akun. `nerval login` ke akun lain menggantikan sesi sebelumnya.
- **Username harus unik**: nama yang sudah dipakai tidak bisa didaftarkan lagi (huruf besar/kecil dianggap sama).

**Cara sesi disimpan:** file `~/.nerval/session` (izin 600) berisi kunci turunan — **bukan password** — dan tidak ikut
backup. Konsekuensinya: karena sesi permanen, siapa pun yang bisa menjalankan perintah di Termux Anda (HP dalam keadaan
terbuka, atau program yang Anda jalankan di Termux) bisa memakai nerval tanpa password sampai Anda logout. Di HP yang
dipakai bersama, jalankan `nerval logout` setelah selesai atau pakai `--ttl`.

## Tools (nano, python, dll.) ikut tersimpan

Setiap backup juga menyimpan **daftar** tools yang terpasang — bukan file programnya:

- paket Termux yang Anda pasang sendiri (`pkg install ...`, mis. `nano`, `python`),
- paket `pip` dan `npm -g`,
- info arsitektur CPU dan tanggal.

Daftar ini ikut terenkripsi di dalam vault. Setelah `nerval` memulihkan `$HOME`, nerval menawarkan untuk memasang ulang
tools yang hilang (`pkg install`, `pip install`, `npm install -g`). Butuh internet. Bisa juga kapan saja lewat
`nerval tools`; `nerval tools list` untuk melihat daftarnya.

**Kenapa daftar, bukan file programnya?** Program Termux terikat ke versi Termux, arsitektur CPU, dan lokasi
`/data/data/com.termux`. Menyalin file-nya (ratusan MB) rentan rusak saat dipulihkan. Memasang ulang dari repositori
resmi jauh lebih andal dan tetap kompatibel.

**Kompatibilitas**

- Versi tools mengikuti repositori saat ini, bukan versi lama. Jika arsitektur CPU berbeda, nerval memberi peringatan.
- Paket `pip` yang butuh kompilasi bisa gagal di Termux; yang gagal ditampilkan, sisanya tetap terpasang.
- Selama tools hasil restore belum dipasang ulang (status *pending*), backup berikutnya membawa daftar lama agar
  tidak hilang. `nerval tools skip` mengabaikannya.
- Cadangan lama (versi 2.1 ke bawah) belum punya daftar tools; jalankan `nerval backup` sekali di sistem yang
  tools-nya sudah lengkap.

## Cara kerja auto-backup

1. Setelah login berhasil, nerval menjalankan watcher di latar belakang untuk akun tersebut.
   Kunci hanya disimpan **di memori** proses watcher, tidak ditulis ke disk.
2. Watcher memantau `$HOME`. Setelah ada perubahan dan **10 detik tenang** (maksimal tunggu 5 menit bila terus berubah),
   seluruh `$HOME` diarsipkan, dienkripsi, diverifikasi, lalu menggantikan vault akun secara atomik.
3. Hanya satu watcher aktif pada satu waktu. Login ke akun lain memindahkan auto-backup ke akun itu.
4. Jika Termux dimatikan atau perangkat restart, watcher berhenti, lalu menyala lagi otomatis saat Termux dibuka
   berikutnya selama Anda masih login (belum `nerval logout`).
5. Log tersimpan di `~/.nerval/nerval.log` (otomatis dipangkas).

## Mengembalikan data setelah Termux ter-uninstall

1. Pasang ulang Termux (sumber yang sama, mis. F-Droid / GitHub) lalu jalankan `termux-setup-storage`.
2. `pkg install -y git && git clone https://github.com/bili33ili/nerval.git && cd nerval && bash install.sh`
3. Ketik **`nerval`**, masukkan username dan password — seluruh `$HOME` kembali seperti semula.
4. Jawab `Y` saat nerval menawarkan memasang ulang tools (nano, python, dll.) — butuh internet.

> Installer mendeteksi vault lama dan **tidak** membuat cadangan kosong di atasnya.

## Catatan keamanan (baca ini)

- **Sesi login menyimpan kunci turunan di `~/.nerval/session`** selama sesi aktif (lihat bagian *Sesi login*). Ini kompromi kenyamanan; `nerval logout` menghapusnya.
- **Password tidak bisa dipulihkan.** Jika lupa, vault akun itu tidak bisa dibuka. `nerval reset` hanya menghapusnya.
- Kekuatan perlindungan = kekuatan password. Siapa pun yang menyalin file vault bisa menebak password secara offline;
  PBKDF2 memperlambat tebakan tetapi tidak menghentikan password yang lemah. Pakai frasa sandi 12+ karakter.
- `nerval reset` dan `hapus-semua` tidak butuh password lama / hanya butuh konfirmasi ketikan, dan menghapus cadangan
  secara permanen. Siapa pun yang memegang HP Anda yang sudah tidak terkunci bisa memakainya — kunci layar HP Anda.
- Nama file vault memuat kode turunan username (bukan username itu sendiri); ini hanya penyamaran, bukan keamanan.
- Selama watcher aktif, kunci turunan ada di memori proses Termux (bukan di file).
- `$HOME` bisa berisi kunci SSH, token, dan kredensial.
- Setiap backup mengarsipkan seluruh `$HOME` (bukan inkremental). Untuk `$HOME` besar, matikan dengan `nerval auto off`.
- Vault berada di penyimpanan yang sama dengan perangkat; factory reset, kerusakan, atau aplikasi pembersih
  dapat menghapusnya. Simpan juga salinan di luar perangkat untuk data penting.
- Daftar tools berisi nama paket Anda; ikut terenkripsi di vault. `nerval hapus-semua` juga menghapus salinannya di `~/.nerval-manifest`.
- Vault versi 1.x (terikat perangkat) tidak kompatibel dengan versi 2.x.

## Struktur proyek

```
nerval/
├── nerval         # skrip utama (dipasang ke $PREFIX/bin/nerval)
├── install.sh     # installer
├── uninstall.sh   # copot perintah & watcher (akun & vault tidak dihapus)
├── VERSION
├── .gitignore     # blokir backup, log, dan file sementara
└── README.md
```

## Lisensi

Tentukan lisensi sesuai keinginan Anda (mis. MIT) sebelum publish.
