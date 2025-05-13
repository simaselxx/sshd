#!/bin/bash

# تنظیمات
GITHUB_URL="https://raw.githubusercontent.com/USERNAME/REPO/BRANCH/sshd_config"
DESTINATION="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%F_%T)"

# بررسی دسترسی ریشه
if [ "$EUID" -ne 0 ]; then
  echo "لطفاً اسکریپت را با sudo اجرا کنید."
  exit 1
fi

echo "📦 دانلود فایل sshd_config جدید از GitHub..."
curl -fsSL "$GITHUB_URL" -o /tmp/sshd_config || {
  echo "❌ دانلود ناموفق بود!"
  exit 1
}

# گرفتن بکاپ
echo "📁 گرفتن بکاپ از فایل فعلی به $BACKUP"
cp "$DESTINATION" "$BACKUP"

# جایگزینی فایل
echo "🚚 جایگزینی فایل sshd_config"
cp /tmp/sshd_config "$DESTINATION"
chmod 600 "$DESTINATION"

# بررسی صحت فایل جدید
echo "🧪 بررسی فایل جدید با sshd -t"
sshd -t
if [ $? -ne 0 ]; then
  echo "❌ خطا در پیکربندی جدید! فایل قبلی بازگردانده می‌شود."
  cp "$BACKUP" "$DESTINATION"
  systemctl restart ssh
  exit 1
fi

# ریستارت SSH
echo "✅ پیکربندی درست است. ریستارت ssh"
systemctl restart ssh && echo "🔁 SSH با موفقیت ریستارت شد."
