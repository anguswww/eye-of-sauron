#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends curl hping3 iproute2 nmap netcat-openbsd

cat >/etc/systemd/system/ids-lab-route.service <<'EOF'
[Unit]
Description=Route IDS lab target traffic through the sensor
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ip route replace 192.168.57.0/24 via 192.168.56.30
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now ids-lab-route.service
