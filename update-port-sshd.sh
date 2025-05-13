#!/bin/bash

SSHD_CONFIG_URL="https://raw.githubusercontent.com/simaselxx/sshd/main/sshd_config"
DESTINATION="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%F_%T)"

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

# دریافت پورت از کاربر با استفاده از read
echo "Please enter the new SSH port (default is 22):"
read -r NEW_SSH_PORT
NEW_SSH_PORT=${NEW_SSH_PORT:-22}
echo "You have chosen port: $NEW_SSH_PORT"

echo "📦 Downloading the new sshd_config file from GitHub..."
curl -fsSL "$SSHD_CONFIG_URL" -o /tmp/sshd_config || {
  echo "❌ Download failed!"
  exit 1
}

echo "📁 Backing up the current file to $BACKUP"
cp "$DESTINATION" "$BACKUP"

echo "🚚 Replacing the sshd_config file and setting the new port"
# حذف خطوط قبلی Port و اضافه کردن Port جدید
sed -i '/^Port /d' /tmp/sshd_config
echo "Port $NEW_SSH_PORT" | cat - /tmp/sshd_config > /tmp/sshd_config.new
mv /tmp/sshd_config.new /tmp/sshd_config

cp /tmp/sshd_config "$DESTINATION"
chmod 600 "$DESTINATION"

echo "🧪 Testing the new configuration with sshd -t"
if ! sshd -t; then
  echo "❌ Error in the new configuration! Reverting to the backup."
  cp "$BACKUP" "$DESTINATION"
  systemctl restart ssh
  exit 1
fi

echo "✅ The configuration is correct. Restarting SSH..."
systemctl restart ssh && echo "🔁 SSH restarted successfully."
