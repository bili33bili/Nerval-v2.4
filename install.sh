#!/data/data/com.termux/files/usr/bin/bash
# nerval installer — jalankan dengan: bash install.sh
set -u

case "${PREFIX:-}" in
  *com.termux*) ;;
  *) echo "[nerval] Installer ini hanya untuk Termux." >&2; exit 1 ;;
esac

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_DIR="/sdcard/.sys_neban_vault"
BASHRC="$HOME/.bashrc"
MARK_START="# >>> nerval auto-sync >>>"
MARK_END="# <<< nerval auto-sync <<<"

if [ -t 1 ]; then
  C_R=$'\033[31m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_B=$'\033[36m'; C_W=$'\033[1m'; C_0=$'\033[0m'
else
  C_R=""; C_G=""; C_Y=""; C_B=""; C_W=""; C_0=""
fi
step() { printf '\n%s[%s]%s %s\n' "$C_B" "$1" "$C_0" "$2"; }
ok()   { printf '  %s✓%s %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_Y" "$C_0" "$*"; }
fail() { printf '  %s✗%s %s\n' "$C_R" "$C_0" "$*" >&2; exit 1; }

printf '%snerval · installer%s  (v%s)\n' "$C_W" "$C_0" "$(cat "$SRC_DIR/VERSION" 2>/dev/null || echo '?')"

SRC_FILE=""
for c in nerval nerval.sh; do
  [ -f "$SRC_DIR/$c" ] && { SRC_FILE="$SRC_DIR/$c"; break; }
done
[ -n "$SRC_FILE" ] || fail "File utama 'nerval' (atau 'nerval.sh') tidak ditemukan di $SRC_DIR"
[ "$(wc -c < "$SRC_FILE")" -gt 1000 ] || fail "File utama rusak/kosong: $SRC_FILE"

# 1. Dependensi ---------------------------------------------------------------
step "1/5" "Memeriksa dependensi"
need=()
command -v tar          >/dev/null 2>&1 || need+=(tar)
command -v openssl      >/dev/null 2>&1 || need+=(openssl-tool)
command -v inotifywait  >/dev/null 2>&1 || need+=(inotify-tools)
for c in od stat df sha256sum comm; do
  command -v "$c" >/dev/null 2>&1 || { need+=(coreutils); break; }
done
if [ ${#need[@]} -gt 0 ]; then
  warn "Menginstal: ${need[*]}"
  pkg install -y "${need[@]}" || { pkg update -y && pkg install -y "${need[@]}"; } \
    || fail "Gagal menginstal dependensi. Periksa koneksi internet."
fi
for c in tar openssl inotifywait od sha256sum; do
  command -v "$c" >/dev/null 2>&1 || fail "Dependensi '$c' masih belum tersedia."
done
openssl kdf -keylen 8 -kdfopt digest:SHA256 -kdfopt pass:a -kdfopt salt:b \
  -kdfopt iter:1000 PBKDF2 >/dev/null 2>&1 \
  || fail "openssl Anda belum mendukung PBKDF2. Jalankan: pkg upgrade -y openssl-tool"
ok "tar, openssl-tool (PBKDF2), inotify-tools siap"

# 2. Izin penyimpanan ---------------------------------------------------------
step "2/5" "Memeriksa izin penyimpanan Android"
_sd_writable() { [ -d /sdcard ] && touch /sdcard/.nerval_wtest 2>/dev/null && rm -f /sdcard/.nerval_wtest; }
if ! _sd_writable; then
  warn "Meminta izin penyimpanan — tekan 'Izinkan' pada dialog Android."
  termux-setup-storage
  for _ in $(seq 1 30); do _sd_writable && break; sleep 2; done
fi
_sd_writable || fail "Izin penyimpanan belum aktif. Jalankan 'termux-setup-storage', lalu ulangi."
ok "/sdcard dapat diakses"

# 3. Vault tersembunyi --------------------------------------------------------
step "3/5" "Menyiapkan vault tersembunyi"
mkdir -p "$VAULT_DIR" || fail "Gagal membuat $VAULT_DIR"
: > "$VAULT_DIR/.nomedia"
ok "$VAULT_DIR (+ .nomedia)"

# 4. Pasang perintah nerval ---------------------------------------------------
step "4/5" "Memasang perintah 'nerval'"
install -m 755 "$SRC_FILE" "$PREFIX/bin/nerval" || fail "Gagal menyalin ke $PREFIX/bin"
sed -i 's/\r$//' "$PREFIX/bin/nerval"
chmod +x "$PREFIX/bin/nerval"
ok "$PREFIX/bin/nerval"

# 5. Pengingat auto-sync di ~/.bashrc ----------------------------------------
step "5/5" "Memasang pengingat auto-sync di ~/.bashrc"
touch "$BASHRC"
sed -i '/# >>> nerval auto-sync >>>/,/# <<< nerval auto-sync <<</d' "$BASHRC"
{
  echo ""
  echo "$MARK_START"
  echo 'if [ -n "${PS1:-}" ] && command -v nerval >/dev/null 2>&1; then'
  echo '  nerval _hint 2>/dev/null'
  echo 'fi'
  echo "$MARK_END"
} >> "$BASHRC"
ok "Ditambahkan ke ~/.bashrc"

echo
have_vault=0
for f in "$VAULT_DIR"/.sys_cache_*.bin; do [ -f "$f" ] && have_vault=1; done
if [ "$have_vault" -eq 1 ]; then
  printf '%s!%s Vault/akun lama ditemukan.\n' "$C_Y" "$C_0"
  printf '  Ketik %snerval%s, masukkan username & password untuk memulihkan seluruh data $HOME.\n' "$C_W" "$C_0"
  printf '  Auto-backup tidak akan menimpa vault sebelum data dipulihkan.\n'
  printf '  (Vault versi 2.0 lama dibuka dengan username "utama".)\n'
else
  printf '%s•%s Membuat akun pertama — pilih username & password.\n' "$C_B" "$C_0"
  printf '  %sPassword tidak bisa dipulihkan. Catat dan simpan baik-baik.%s\n\n' "$C_Y" "$C_0"
  nerval daftar
fi

echo
printf '%s✓ Instalasi selesai.%s  Coba: %snerval status%s\n' "$C_G" "$C_0" "$C_W" "$C_0"
