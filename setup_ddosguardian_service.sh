
if [ -d "/etc/ddos-guardian" ]; then
    echo "Directory /etc/ddos-guardian already exists."
    exit 1
fi

mkdir /etc/ddos-guardian

cd /etc/ddos-gurdian

git clone https://github.com/xlelord9292/ddos-guardian

npm install



apt update
apt upgrade

cat <<EOF > /etc/systemd/system/guardian.service
[Unit]
Description=DDoS Guardian Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /etc/ddos-guardian/attack.js
WorkingDirectory=/etc/ddos-guardian
Restart=always
RestartSec=3
StandardOutput=syslog
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload


systemctl enable guardian
systemctl start guardian

echo "DDoS Guardian setup complete."

echo "[DDoS Guardian] Please Read Docs To Learn How To Set This Up With Nginx"
