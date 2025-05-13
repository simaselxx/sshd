#!/bin/bash

# GitHub sshd_config file URL
SSHD_CONFIG_URL="https://raw.githubusercontent.com/simaselxx/sshd/main/sshd_config"
DESTINATION="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%F_%T)"

if [ "$EUID" -ne 0 ]; then
  echo "Please run the script with sudo."
  exit 1
fi

# Ask the user for the new SSH port using select
echo "Please choose the new SSH port (default is 22):"
select NEW_SSH_PORT in "22" "1001" "Other"; do
  case $NEW_SSH_PORT in
    "22")
      echo "You have chosen port 22"
      break
      ;;
    "1001")
      echo "You have chosen port 1001"
      break
      ;;
    "Other")
      echo "Please enter the new port:"
      read NEW_SSH_PORT
      echo "You have chosen port: $NEW_SSH_PORT"
      break
      ;;
    *)
      echo "Invalid option, please try again."
      ;;
  esac
done

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
