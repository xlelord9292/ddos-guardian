if [ -d "/etc/ddos-guardian" ]; then
    echo "Directory /etc/ddos-guardian already exists."
    exit 1
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


iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p udp -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -j DROP

iptables -A INPUT -i lo -j ACCEPT


iptables -A INPUT -p tcp --dport 22 -j ACCEPT


iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT


iptables -A INPUT -m conntrack --ctstate INVALID -j DROP


iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP


iptables -A INPUT -p icmp -m limit --limit 1/s -j ACCEPT

iptables -A INPUT -j LOG --log-prefix "Dropped: "


iptables -A INPUT -j DROP


iptables-save > /etc/iptables/rules.v4


cd /etc/nginx/conf.d/
git clone https://github.com/xlelord9292/ddos-guardian-layer-7

sudo apt-get install libnginx-mod-http-lua

echo "DDoS Guardian setup complete."

