
if [ -d "/etc/ddos-guardian" ]; then
    echo "Removing existing /etc/ddos-guardian directory..."
    rm -rf /etc/ddos-guardian
fi


mkdir /etc/ddos-guardian


cd /etc/ddos-guardian


git clone https://github.com/xlelord9292/ddos-guardian .


if ! command -v node &> /dev/null; then
    curl -sL https://deb.nodesource.com/setup_14.x | bash -
    apt install -y nodejs
fi


npm install


apt update
apt upgrade -y


cat <<EOF > /etc/systemd/system/guardian.service
[Unit]
Description=DDoS Guardian Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/ddos-guardian
ExecStart=/usr/bin/node /etc/ddos-guardian/attacks.js
Restart=always
StandardOutput=syslog
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload


systemctl enable guardian
systemctl start guardian



cd /etc/nginx/conf.d/
sudo apt-get install libnginx-mod-http-lua

if [ -d "ddos-guardian-layer-7" ]; then
    echo "Removing existing /etc/nginx/conf.d/ddos-guardian-layer-7 directory..."
    rm -rf ddos-guardian-layer-7
fi

git clone https://github.com/xlelord9292/ddos-guardian-layer-7

echo "DDoS Guardian Update complete."
