#!/usr/bin/env bash
set -euo pipefail

# Keep all lab guests reachable when their desktops are idle.
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# Kali uses Xfce; Ubuntu desktop guests use the GNOME settings in desktop.sh.
if command -v xfconf-query >/dev/null 2>&1; then
  user_id=$(id -u vagrant)
  if [[ -S "/run/user/${user_id}/bus" ]]; then
    xfconf=(runuser -u vagrant -- env "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${user_id}/bus" xfconf-query)
  else
    xfconf=(runuser -u vagrant -- dbus-run-session -- xfconf-query)
  fi

  for property in dpms-enabled lock-screen-suspend-hibernate; do
    "${xfconf[@]}" -c xfce4-power-manager -p "/xfce4-power-manager/${property}" -n -t bool -s false
  done
  for property in inactivity-on-ac inactivity-on-battery blank-on-ac blank-on-battery; do
    "${xfconf[@]}" -c xfce4-power-manager -p "/xfce4-power-manager/${property}" -n -t uint -s 0
  done
fi
