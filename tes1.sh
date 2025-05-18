#!/bin/bash

# Backup konfigurasi Mikrotik via SSH dan SCP
# Author: davawiagam
# Date: 2025-05-18

# Daftar router (nama -> IP:port)
declare -A routers=(
  ["router1"]="192.168.56.1:8001"
  ["router2"]="192.168.56.1:8002"
  ["router3"]="192.168.56.1:8003"
)

userName="admin"                          # Username login MikroTik
backupPath="./backup_files"              # Folder lokal untuk menyimpan file .rsc
getDate=$(date +%Y%m%d)                  # Tanggal backup

# Buat folder backup jika belum ada
mkdir -p "$backupPath"

for routerName in "${!routers[@]}"; do
  address=${routers[$routerName]}
  ip=$(echo $address | cut -d':' -f1)
  port=$(echo $address | cut -d':' -f2)

  echo "========================================"
  echo "📦 Starting backup: $routerName ($ip:$port)"
  echo "========================================"

  # Ambil system identity dari router
  getRouterID=$(ssh -p $port $userName@$ip 'system identity print' 2>/dev/null)
  getRealRouterID=$(echo "$getRouterID" | grep "name:" | awk '{print $2}')

  if [[ -z "$getRealRouterID" ]]; then
    getRealRouterID=$routerName
  fi

  backupName="backup_${getRealRouterID}_${getDate}"

  echo "📁 Exporting config to file: $backupName"

  # Ekspor konfigurasi dari router
  ssh -p $port $userName@$ip "/export file=$backupName" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Gagal export konfigurasi dari $ip:$port"
    continue
  fi

  sleep 3

  echo "⬇️  Mengunduh file: $backupName.rsc"
  scp -P $port $userName@$ip:/${backupName}.rsc "$backupPath" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Gagal mengunduh file dari $ip:$port"
    continue
  fi

  echo "🧹 Menghapus file backup dari router..."
  ssh -p $port $userName@$ip "file remove ${backupName}.rsc" 2>/dev/null

  echo "✅ Backup selesai untuk $routerName ($ip:$port)"
done

echo "==============================="
echo "🎉 Semua backup selesai!"
echo "🗂️  Cek folder backup di: $backupPath"
