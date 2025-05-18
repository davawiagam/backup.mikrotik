#!/bin/bash

# Script backup konfigurasi Mikrotik ke file .rsc via SSH dan SCP
# Mendukung port custom
# Author: YourName
# Date: 2025-05-18

declare -A routers=(
  ["Ro-1"]="192.168.56.1:8001"
  ["Ro-2"]="192.168.56.1:8002"
  ["Ro-3"]="192.168.56.1:8003"  # Dengan port custom
)

userName="admin"                              # Ganti sesuai username MikroTik kamu
backupPath="$(pwd)/backup_files"              # Folder lokal untuk menyimpan backup
mkdir -p "$backupPath"                        # Buat folder backup jika belum ada

getDate=$(date +%Y%m%d)

for routerName in "${!routers[@]}"; do
  target=${routers[$routerName]}

  # Pisahkan host dan port
  IFS=':' read -r host port <<< "$target"
  port=${port:-22}  # Default ke port 22 jika tidak ada

  echo "========================================"
  echo "📦 Starting backup: $routerName ($host:$port)"
  echo "========================================"

  # Tes koneksi port
  if ! nc -z -w3 "$host" "$port"; then
    echo "❌ Tidak bisa konek ke $host:$port"
    continue
  fi

  # Ambil RouterID
  getRouterID=$(ssh -p "$port" "$userName@$host" 'system identity print' 2>/dev/null)
  getRealRouterID=$(echo "$getRouterID" | grep 'name:' | awk '{print $2}')
  [ -z "$getRealRouterID" ] && getRealRouterID="$routerName"

  backupName="${getRealRouterID}-${getDate}"

  echo "🛠️ Exporting config to: ${backupName}.rsc"
  ssh -p "$port" "$userName@$host" "/export file=${backupName}" < /dev/null || {
    echo "❌ Gagal export konfigurasi dari $host"
    continue
  }

  sleep 5

  echo "⬇️  Mengunduh file .rsc ke lokal..."
  scp -P "$port" "$userName@$host:/${backupName}.rsc" "$backupPath" || {
    echo "❌ Gagal mengunduh file dari $host"
    continue
  }

  echo "🧹 Menghapus file .rsc dari router..."
  ssh -p "$port" "$userName@$host" "file remove ${backupName}.rsc"

  echo "✅ Backup $routerName selesai. File disimpan di: $backupPath/${backupName}.rsc"
  echo ""
done

echo "==============================="
echo "🎉 Semua backup selesai!"
echo "🗂️  Cek folder: $backupPath"
echo "==============================="
