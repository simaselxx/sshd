#!/bin/bash

# URL of the sshd_config template
SSHD_CONFIG_URL="https://raw.githubusercontent.com/simaselxx/sshd/main/sshd_config"
DESTINATION="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%F_%T)"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

# Ask for new SSH port
read -p "Please enter the new SSH port (default is 22): " NEW_SSH_PORT
NEW_SSH_PORT=${NEW_SSH_PORT:-22}
echo "You have chosen port: $NEW_SSH_PORT"

# Download the base sshd_config
echo "📦 Downloading the new sshd_config file from GitHub..."
if ! curl -fsSL "$SSHD_CONFIG_URL" -o /tmp/sshd_config; then
  echo "❌ Download failed!"
  exit 1
fi

# Backup current config
echo "📁 Backing up the current file to $BACKUP"
cp "$DESTINATION" "$BACKUP"

# Inject new port
echo "🚚 Replacing the sshd_config file and setting the new port"
# Remove old port line(s)
sed -i '/^Port /d' /tmp/sshd_config
# Add new port at the top
echo "Port $NEW_SSH_PORT" | cat - /tmp/sshd_config > /tmp/sshd_config.new
mv /tmp/sshd_config.new /tmp/sshd_config

# Copy to destination
cp /tmp/sshd_config "$DESTINATION"
chmod 600 "$DESTINATION"

# Test configuration
echo "🧪 Testing the new configuration with sshd -t"
if ! sshd -t; then
  echo "❌ Error in the new configuration! Reverting to the backup."
  cp "$BACKUP" "$DESTINATION"
  systemctl restart ssh
  exit 1
fi

# Restart SSH
echo "✅ The configuration is correct. Restarting SSH..."
systemctl restart ssh && echo "🔁 SSH restarted successfully."
