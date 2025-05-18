#!/bin/bash

# Konfigurasi
declare -A routers=(
  ["router1"]="192.168.56.1:8001"
)

userName="admin"
backupPath="./backup_files"
getDate=$(date +%Y%m%d)

mkdir -p "$backupPath"

for routerName in "${!routers[@]}"; do
  address=${routers[$routerName]}
  ip=$(echo $address | cut -d':' -f1)
  port=$(echo $address | cut -d':' -f2)

  echo "========================================"
  echo "Starting backup: $routerName ($ip:$port)"
  echo "========================================"

  backupName="backup_${routerName}_${getDate}"

  # Buat file perintah .rsc sederhana
  cmdFile="cmd_${backupName}.rsc"
  echo "/export file=$backupName" > "$cmdFile"

  # Upload file perintah ke router
  scp -P $port "$cmdFile" $userName@$ip: > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "❌ Gagal upload file perintah ke $ip:$port"
    continue
  fi

  # Jalankan import file perintah di router via ssh
  ssh -p $port $userName@$ip "/import file=$cmdFile" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "❌ Gagal menjalankan import perintah di $ip:$port"
    continue
  fi

  # Download hasil export backup .rsc dari router
  scp -P $port $userName@$ip:/${backupName}.rsc "$backupPath/" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "❌ Gagal download file backup dari $ip:$port"
    continue
  fi

  # Hapus file perintah dan hasil export di router
  ssh -p $port $userName@$ip "file remove $cmdFile" > /dev/null 2>&1
  ssh -p $port $userName@$ip "file remove ${backupName}.rsc" > /dev/null 2>&1

  # Bersihkan file perintah lokal
  rm "$cmdFile"

  echo "✅ Backup selesai untuk $routerName ($ip:$port)"
done

echo "========================================"
echo "Semua backup selesai! File backup ada di: $backupPath"
