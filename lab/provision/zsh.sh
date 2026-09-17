#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git zsh

user_home=$(getent passwd vagrant | cut -d: -f6)
user_shell=$(command -v zsh)

if [[ ! -d "${user_home}/.oh-my-zsh" ]]; then
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${user_home}/.oh-my-zsh"
fi

chown -R vagrant:vagrant "${user_home}/.oh-my-zsh"

# Preserve the existing interactive setup once, then use the tracked config.
if [[ -e "${user_home}/.zshrc" && ! -e "${user_home}/.zshrc.eye-of-sauron-backup" ]]; then
  cp -a "${user_home}/.zshrc" "${user_home}/.zshrc.eye-of-sauron-backup"
fi
install -o vagrant -g vagrant -m 0644 \
  /tmp/eye-of-sauron-zshrc "${user_home}/.zshrc"

if [[ "$(getent passwd vagrant | cut -d: -f7)" != "${user_shell}" ]]; then
  chsh -s "${user_shell}" vagrant
fi
