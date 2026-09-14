#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
echo 'wireshark-common wireshark-common/install-setuid boolean true' | debconf-set-selections
apt-get update
apt-get install -y --no-install-recommends git iproute2 iptables jq python3 tcpdump tshark wireshark

cat >/etc/sysctl.d/99-ids-lab.conf <<'EOF'
net.ipv4.ip_forward=1
EOF
sysctl --system >/dev/null

install -d -o vagrant -g vagrant /opt/ids-lab/captures
install -d /usr/local/lib/eye-of-sauron
cp -RT /tmp/eye_of_sauron /usr/local/lib/eye-of-sauron/eye_of_sauron
usermod -aG wireshark vagrant

cat >/usr/local/bin/capture-lab <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

output=${1:-/opt/ids-lab/captures/lab-$(date +%Y%m%d-%H%M%S).pcap}
capture_interface=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.57\.30\// {print $2; exit}')

if [[ -z "${capture_interface}" ]]; then
  echo "Could not locate the IDS target-side interface." >&2
  exit 1
fi

echo "Capturing ${capture_interface} to ${output}; press Ctrl-C to stop."
exec tcpdump -i "${capture_interface}" -nn -s 0 -w "${output}"
EOF
chmod 0755 /usr/local/bin/capture-lab

cat >/usr/local/bin/eye-of-sauron <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH=/usr/local/lib/eye-of-sauron
exec python3 -m eye_of_sauron "$@"
EOF
chmod 0755 /usr/local/bin/eye-of-sauron
