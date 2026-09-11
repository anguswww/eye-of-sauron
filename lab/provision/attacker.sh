#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends curl git hping3 iproute2 nmap netcat-openbsd

lab_mac='00:50:56:00:02:10'
lab_interface=''

for interface_path in /sys/class/net/*; do
  if [[ "$(<"${interface_path}/address")" == "${lab_mac}" ]]; then
    lab_interface=${interface_path##*/}
    break
  fi
done

if [[ -z "${lab_interface}" ]]; then
  echo "Could not locate the Kali lab interface with MAC ${lab_mac}." >&2
  exit 1
fi

connection_name=$(nmcli -g GENERAL.CONNECTION device show "${lab_interface}")
if [[ -z "${connection_name}" || "${connection_name}" == "--" ]]; then
  connection_name='IDS lab network'
  nmcli connection add type ethernet \
    ifname "${lab_interface}" \
    con-name "${connection_name}"
fi

nmcli connection modify "${connection_name}" \
  connection.autoconnect yes \
  ipv4.method manual \
  ipv4.addresses 192.168.56.10/24 \
  ipv4.gateway '' \
  ipv4.dns '' \
  ipv4.never-default yes \
  ipv6.method disabled
nmcli connection up "${connection_name}"

cat >/etc/systemd/system/ids-lab-route.service <<'EOF'
[Unit]
Description=Route IDS lab target traffic through the sensor
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/ip route replace 192.168.57.0/24 via 192.168.56.30 dev LAB_INTERFACE
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sed -i "s/LAB_INTERFACE/${lab_interface}/" /etc/systemd/system/ids-lab-route.service

systemctl daemon-reload
systemctl enable ids-lab-route.service
systemctl restart ids-lab-route.service
