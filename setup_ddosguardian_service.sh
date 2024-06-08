
if [ -d "/etc/ddos-guardian" ]; then
    echo "Directory /etc/ddos-guardian already exists."
    exit 1
fi


mkdir /etc/ddos-guardian


cd /etc/ddos-guardian


git clone https://github.com/xlelord9292/ddos-guardian

cd ddos-guardian

npm install


apt update
apt upgrade -y


cat <<EOF > /etc/systemd/system/guardian.service
[Unit]
Description=DDoS Guardian Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /etc/ddos-guardian/ddos-guardian/attack.js
WorkingDirectory=/etc/ddos-guardian/ddos-guardian
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


iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p udp -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -j DROP


iptables-save > /etc/iptables/rules.v4

echo "DDoS Guardian setup complete."


