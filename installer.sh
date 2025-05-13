#!/bin/bash

# اجرای apt-get update و upgrade
echo "📦 Updating and upgrading packages..."
apt-get update -y && apt-get upgrade -y

# نصب اسکریپت Dark
echo "⚙️ Installing DARKSSH-MANAGER..."
wget -q https://raw.githubusercontent.com/sbatrow/DARKSSH-MANAGER/master/Dark -O Dark
chmod 777 Dark
./Dark

# نصب اسکریپت تغییر پورت sshd
echo "🔧 Running SSH port change script..."
curl -s https://raw.githubusercontent.com/simaselxx/sshd/main/update-port-sshd.sh | sudo bash

# نصب BBR
echo "🚀 Installing BBR script..."
wget -N --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
chmod +x bbr.sh
bash bbr.sh
