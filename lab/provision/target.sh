#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends nginx openssh-server python3

cat >/var/www/html/index.html <<'EOF'
<!doctype html>
<html lang="en">
  <head><meta charset="utf-8"><title>IDS Lab Target</title></head>
  <body><h1>IDS Lab Target</h1><p>Traffic reached the target VM.</p></body>
</html>
EOF

cat >/etc/systemd/system/ids-lab-route.service <<'EOF'
[Unit]
Description=Route IDS lab attacker traffic through the sensor
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ip route replace 192.168.56.0/24 via 192.168.57.30
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl set-default multi-user.target
systemctl enable --now nginx ssh ids-lab-route.service
