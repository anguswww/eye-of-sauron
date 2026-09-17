#!/usr/bin/env bash
set -euo pipefail

# A lab VM must remain visible and reachable when it is left unattended.
# Apply system defaults as well as the existing vagrant user's settings.
install -d /etc/dconf/profile /etc/dconf/db/local.d /etc/dconf/db/local.d/locks
cat >/etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF

cat >/etc/dconf/db/local.d/00-ids-lab-desktop <<'EOF'
[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/desktop/screensaver]
idle-activation-enabled=false
lock-enabled=false
ubuntu-lock-on-suspend=false

[org/gnome/settings-daemon/plugins/power]
idle-dim=false
sleep-inactive-ac-timeout=0
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-timeout=0
sleep-inactive-battery-type='nothing'
EOF

cat >/etc/dconf/db/local.d/locks/00-ids-lab-desktop <<'EOF'
/org/gnome/desktop/session/idle-delay
/org/gnome/desktop/screensaver/idle-activation-enabled
/org/gnome/desktop/screensaver/lock-enabled
/org/gnome/desktop/screensaver/ubuntu-lock-on-suspend
/org/gnome/settings-daemon/plugins/power/idle-dim
/org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-timeout
/org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type
/org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-timeout
/org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-type
EOF

dconf update
