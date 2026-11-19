#!/usr/bin/env bash
set -euo pipefail

DROPIN="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/pipewire.service.d/ssc.conf"
WP_DROPIN="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/wireplumber.service.d/ssc.conf"
CUSTOM_DIR="$HOME/.local/lib/ssc-pipewire"

if [[ -f "$DROPIN" ]] && grep -Fq "Managed by the SSC PipeWire installer" "$DROPIN"; then
  rm -f "$DROPIN"
fi
if [[ -f "$WP_DROPIN" ]] && grep -Fq "Managed by the SSC PipeWire installer" "$WP_DROPIN"; then
  rm -f "$WP_DROPIN"
fi
rmdir --ignore-fail-on-non-empty "$(dirname -- "$DROPIN")" 2>/dev/null || true
rmdir --ignore-fail-on-non-empty "$(dirname -- "$WP_DROPIN")" 2>/dev/null || true
rm -rf "$CUSTOM_DIR"
systemctl --user daemon-reload
systemctl --user restart pipewire.service
systemctl --user restart wireplumber.service
echo "Removed the user-local SSC PipeWire modules."
