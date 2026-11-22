#!/data/data/com.termux/files/usr/bin/bash
# nerval uninstaller — hanya mencopot perintah & watcher. Akun & vault TIDAK dihapus.
# Untuk menghapus SEMUA (akun, vault, data, perintah): login lalu jalankan `nerval hapus-semua`.
set -u
case "${PREFIX:-}" in
  *com.termux*) ;;
  *) echo "[nerval] Hanya untuk Termux." >&2; exit 1 ;;
esac

BASHRC="$HOME/.bashrc"
P=$(cat "$HOME/.nerval/watcher.pid" 2>/dev/null)
[ -n "$P" ] && kill "$P" 2>/dev/null
[ -f "$BASHRC" ] && sed -i '/# >>> nerval auto-sync >>>/,/# <<< nerval auto-sync <<</d' "$BASHRC"
rm -f "$PREFIX/bin/nerval"
rm -rf "$HOME/.nerval"

echo "✓ nerval dilepas dari Termux."
echo "• Akun & vault tetap aman di /sdcard/.sys_neban_vault (hapus manual bila tidak diperlukan)."
echo "• Untuk membukanya lagi: pasang nerval kembali, lalu ketik 'nerval' dan login."
