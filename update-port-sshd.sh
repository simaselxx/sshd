#!/bin/bash

# GitHub sshd_config file URL
SSHD_CONFIG_URL="https://raw.githubusercontent.com/simaselxx/sshd/main/sshd_config"
DESTINATION="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%F_%T)"

if [ "$EUID" -ne 0 ]; then
  echo "Please run the script with sudo."
  exit 1
fi

# Ask the user for the new SSH port
echo "Please enter the new SSH port (default is 22):"
read NEW_SSH_PORT

# If the user doesn't enter anything, set default port to 22
if [ -z "$NEW_SSH_PORT" ]; then
  NEW_SSH_PORT=22
fi

echo "You have chosen port: $NEW_SSH_PORT"

echo "📦 Downloading the new sshd_config file from GitHub..."
curl -fsSL "$SSHD_CONFIG_URL" -o /tmp/sshd_config || {
  echo "❌ Download failed!"
  exit 1
}

echo "📁 Backing up the current file to $BACKUP"
cp "$DESTINATION" "$BACKUP"

echo "🚚 Replacing the sshd_config file and setting the new port"
# Check if Port is commented and update accordingly
if grep -q "^#Port" /tmp/sshd_config; then
  sed -i "s/^#Port 22/Port $NEW_SSH_PORT/" /tmp/sshd_config
else
  sed -i "s/^Port .*/Port $NEW_SSH_PORT/" /tmp/sshd_config
fi

# Replace the current sshd_config with the updated one
cp /tmp/sshd_config "$DESTINATION"
chmod 600 "$DESTINATION"

echo "🧪 Testing the new configuration with sshd -t"
sshd -t
if [ $? -ne 0 ]; then
  echo "❌ Error in the new configuration! The previous file will be restored."
  cp "$BACKUP" "$DESTINATION"
  systemctl restart ssh
  exit 1
fi

echo "✅ The configuration is correct. Restarting SSH"
systemctl restart ssh && echo "🔁 SSH has been successfully restarted."
