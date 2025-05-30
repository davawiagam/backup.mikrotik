#!/bin/bash

TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_TELEGRAM_ID"
API_URL="https://api.telegram.org/bot$TOKEN"
OFFSET=0

while true; do
  updates=$(curl -s "$API_URL/getUpdates?offset=$OFFSET")
  messages=$(echo $updates | jq -c '.result[]')

  for msg in $messages; do
    OFFSET=$(( $(echo $msg | jq '.update_id') + 1 ))
    chat_id=$(echo $msg | jq -r '.message.chat.id')
    text=$(echo $msg | jq -r '.message.text')

    echo "Received: $text"

    if [[ "$text" =~ ^/backup ]]; then
      router=$(echo $text | cut -d' ' -f2)

      if [[ -z "$router" ]]; then
        curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$chat_id&text=❌ Format salah. Gunakan /backup [router1|all]"
        continue
      fi

      ./backup_router.sh "$router" > output.log 2>&1
      curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$chat_id&text=⏳ Proses backup untuk '$router' sedang dijalankan..."

      # Kirim hasil log dan file backup
      curl -F chat_id="$chat_id" -F document=@"output.log" "$API_URL/sendDocument"

      # Kirim file hasil backup jika ada
      latest_backup=$(ls -t ./backup_files/backup_${router}_*.rsc 2>/dev/null | head -1)
      if [[ -f "$latest_backup" ]]; then
        curl -F chat_id="$chat_id" -F document=@"$latest_backup" "$API_URL/sendDocument"
      else
        curl -s -X POST "$API_URL/sendMessage" -d "chat_id=$chat_id&text=❌ Backup file tidak ditemukan."
      fi
    fi
  done

  sleep 3
done
