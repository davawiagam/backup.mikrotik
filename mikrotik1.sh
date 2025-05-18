#!/bin/bash

# Script backup konfigurasi Mikrotik ke file .rsc via SSH dan SCP
# Author: YourName
# Date: 2025-05-18

declare -A routers=(
  ["Ro-1"]="192.168.56.1:8001"
  ["Ro-2"]="192.168.56.1:8002"
  ["Ro-3"]="192.168.56.1:8003"
)

userName="admin"              # Ganti sesuai username Mikrotik kamu
backupPath="./backup_files"   # Folder lokal untuk menyimpan backup

mkdir -p "$backupPath"        # Buat folder backup jika belum ada

getDate=$(date +%Y%m%d)

for routerName in "${!routers[@]}"; do
  target=${routers[$routerName]}
  # Pisahkan IP dan port jika ada
  ip="${target%%:*}"
  port="${target##*:}"
  if [ "$ip" == "$port" ]; then
    # Tidak ada port di string, pakai default SSH port 22
    port=22
  fi

  echo "========================================"
  echo "📦 Starting backup: $routerName ($ip:$port)"
  echo "========================================"

  # Ambil Router ID, fallback ke routerName jika gagal
  getRouterID=$(ssh -p $port $userName@$ip 'system identity print' 2>/dev/null)
  getRealRouterID=$(echo "$getRouterID" | grep "name:" | awk '{print $2}')
  if [[ -z "$getRealRouterID" ]]; then
    getRealRouterID="$routerName"
  fi

  # Buat nama file backup, pastikan tidak diawali tanda minus
  backupName="backup-${getRealRouterID}-${getDate}"

  echo "DEBUG backupName = $backupName"

  # Export konfigurasi ke file .rsc
  ssh -p $port $userName@$ip "/export file=$backupName" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Gagal export konfigurasi dari $ip:$port"
    continue
  fi

  # Tunggu sebentar supaya file selesai dibuat
  sleep 5

  echo "Downloading backup file..."
  scp -P $port $userName@$ip:"/${backupName}.rsc" "$backupPath/"
  if [ $? -ne 0 ]; then
    echo "❌ Gagal download backup dari $ip:$port"
    continue
  fi

  echo "Removing backup file from router..."
  ssh -p $port $userName@$ip "file remove ${backupName}.rsc"

  echo "Backup of $routerName ($ip:$port) completed."
  echo ""
done

echo "🎉 Semua backup selesai!"
echo "🗂️  Cek folder backup di: $(realpath $backupPath)"
