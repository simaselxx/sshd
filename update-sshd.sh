#!/bin/bash

# آدرس فایل sshd_config شما در GitHub
SSHD_CONFIG_URL="https://raw.githubusercontent.com/simaselxx/sshd/main/sshd_config"
DESTINATION="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%F_%T)"

if [ "$EUID" -ne 0 ]; then
  echo "لطفاً اسکریپت را با sudo اجرا کنید."
  exit 1
fi

echo "📦 دانلود فایل sshd_config جدید از GitHub..."
curl -fsSL "$SSHD_CONFIG_URL" -o /tmp/sshd_config || {
  echo "❌ دانلود ناموفق بود!"
  exit 1
}

echo "📁 گرفتن بکاپ از فایل فعلی به $BACKUP"
cp "$DESTINATION" "$BACKUP"

echo "🚚 جایگزینی فایل sshd_config"
cp /tmp/sshd_config "$DESTINATION"
chmod 600 "$DESTINATION"

echo "🧪 بررسی فایل جدید با sshd -t"
sshd -t
if [ $? -ne 0 ]; then
  echo "❌ خطا در پیکربندی جدید! فایل قبلی بازگردانده می‌شود."
  cp "$BACKUP" "$DESTINATION"
  systemctl restart ssh
  exit 1
fi

echo "✅ پیکربندی درست است. ریستارت ssh"
systemctl restart ssh && echo "🔁 SSH با موفقیت ریستارت شد."
