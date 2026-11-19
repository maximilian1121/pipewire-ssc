#!/usr/bin/env bash
set -euo pipefail

say() { printf '\n%s\n' "$*"; }
fail() {
  say "Steam Deck SSC setup stopped: $*"
  read -r -p 'Press Enter to close this window…' _ || true
  exit 1
}

if [[ ! -r /etc/os-release ]] || ! grep -qi 'steamos' /etc/os-release; then
  fail 'This launcher is intended for SteamOS on Steam Deck.'
fi

if ! command -v pipewire >/dev/null 2>&1; then
  fail 'PipeWire was not found. Check that SteamOS Desktop Mode is fully updated.'
fi

version="$(pipewire --version 2>/dev/null | sed -nE 's/.*libpipewire ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' | head -n1)"
if [[ -z "$version" ]]; then
  version="$(pipewire --version 2>/dev/null | sed -nE 's/.* ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' | head -n1)"
fi
if [[ "$version" != 0.3.59 && ! "$version" =~ ^1\.6\.[0-9]+$ ]]; then
  fail "This repository supports PipeWire 0.3.59 and the 1.6.x series, but this Deck reports ${version:-an unknown version}. The codec interface is version-specific; continuing could install an incompatible module."
fi

for tool in git meson ninja pkg-config systemctl; do
  command -v "$tool" >/dev/null 2>&1 || fail "Required build tool '$tool' is missing. SteamOS does not include the full development toolchain by default. See the Steam Deck setup notes in README.md; this installer will not change the read-only OS image or install packages for you."
done

if ! pkg-config --exists libspa-0.2 libpipewire-0.3 glib-2.0 dbus-1 bluez sbc; then
  fail 'One or more PipeWire/BlueZ development libraries are missing. See the Steam Deck setup notes in README.md.'
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
[[ -x "$script_dir/install.sh" ]] || fail 'install.sh is missing. Keep this launcher beside the repository files.'

say 'Building the SSC modules for this SteamOS installation. PipeWire will restart briefly.'
"$script_dir/install.sh" || fail 'The SSC module build or install failed. The error above should identify the failing step.'
say 'SSC modules installed. Reconnect your Samsung earbuds and select the Samsung Seamless Codec A2DP profile.'
read -r -p 'Press Enter to close this window…' _ || true
