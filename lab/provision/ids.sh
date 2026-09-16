#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
echo 'wireshark-common wireshark-common/install-setuid boolean true' | debconf-set-selections
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git iproute2 iptables jq python3 tcpdump tshark wireshark

cat >/etc/sysctl.d/99-ids-lab.conf <<'EOF'
net.ipv4.ip_forward=1
EOF
sysctl --system >/dev/null

install -d -o vagrant -g vagrant /opt/ids-lab/captures
usermod -aG wireshark vagrant

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh |
    env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh
fi

install -d /opt/eye-of-sauron
install -m 0644 /tmp/eye-of-sauron-README.md /opt/eye-of-sauron/README.md
install -m 0644 /tmp/eye-of-sauron-pyproject.toml /opt/eye-of-sauron/pyproject.toml
install -m 0644 /tmp/eye-of-sauron-uv.lock /opt/eye-of-sauron/uv.lock
rm -rf /opt/eye-of-sauron/src
cp -RT /tmp/eye-of-sauron-src /opt/eye-of-sauron/src
UV_PROJECT_ENVIRONMENT=/opt/eye-of-sauron/.venv \
  uv sync --frozen --no-dev --project /opt/eye-of-sauron

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

exec /opt/eye-of-sauron/.venv/bin/eye-of-sauron "$@"
EOF
chmod 0755 /usr/local/bin/eye-of-sauron
