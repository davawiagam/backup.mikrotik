#!/bin/bash

# Script backup konfigurasi Mikrotik ke file .rsc via SSH dan SCP
# Author: YourName
# Date: 2025-05-18

declare -A routers=(
  ["router1"]="192.168.1.1"
  ["router2"]="192.168.1.2"
  ["router3"]="192.168.1.3"
  ["router4"]="192.168.1.4"
  ["router5"]="192.168.1.5"
)

userName="admin"              # Ganti sesuai username Mikrotik kamu
backupPath="./backup_files"   # Folder lokal untuk menyimpan backup

mkdir -p "$backupPath"        # Buat folder backup jika belum ada

getDate=$(date +%Y%m%d)

for routerName in "${!routers[@]}"; do
  target=${routers[$routerName]}

  echo "==============================="
  echo "Starting backup router $routerName ($target)"
  echo "==============================="

  getRouterID=$(ssh $userName@$target 'sys ide pr' 2>/dev/null)
  getRealRouterID=$(echo ${getRouterID:7:-3} | cut -d':' -f 2)
  if [ -z "$getRealRouterID" ]; then
    getRealRouterID=$routerName
  fi

  backupName="${getRealRouterID}-${getDate}"

  echo "Exporting configuration to file: ${backupName}.rsc"
  ssh $userName@$target "/export file=${backupName}" || { echo "Failed to export config from $target"; continue; }

  sleep 5

  echo "Downloading backup file..."
  scp $userName@$target:"/${backupName}.rsc" "$backupPath" || { echo "Failed to download backup from $target"; continue; }

  echo "Removing backup file from router..."
  ssh $userName@$target "file remove ${backupName}.rsc"

  echo "Backup of $routerName ($target) completed."
  echo ""
done

echo "All backups completed. Files are in $backupPath"
