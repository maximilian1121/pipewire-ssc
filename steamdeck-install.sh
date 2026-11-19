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

version="$(pipewire --version 2>&1 | sed -nE 's/.*libpipewire ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' | head -n1)"
if [[ -z "$version" ]]; then
  version="$(pipewire --version 2>/dev/null | sed -nE 's/.* ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' | head -n1)"
fi
if [[ "$version" != 0.3.59 && ! "$version" =~ ^1\.6\.[0-9]+$ ]]; then
  fail "This repository supports PipeWire 0.3.59 and the 1.6.x series, but this Deck reports ${version:-an unknown version}. Continuing could install an incompatible module."
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
[[ -x "$script_dir/install.sh" ]] || fail 'install.sh is missing from the downloaded project files.'

if command -v meson >/dev/null && command -v ninja >/dev/null && \
   command -v pkg-config >/dev/null && command -v cc >/dev/null && \
   pkg-config --exists libspa-0.2 libpipewire-0.3 glib-2.0 dbus-1 bluez sbc; then
  SSC_PIPEWIRE_VERSION="$version" "$script_dir/install.sh" || fail 'The SSC module build or install failed.'
else
  command -v distrobox >/dev/null || fail 'Build tools are missing and Distrobox is not installed.'
  command -v podman >/dev/null || fail 'Build tools are missing and Podman is not installed.'

  say 'Creating or preparing a user-owned Arch build container. SteamOS itself stays untouched; the first setup downloads several hundred megabytes.'
  if ! distrobox list | grep -Fq 'ssc-build'; then
    distrobox create --name ssc-build --image archlinux:latest --yes || fail 'Could not create the Arch build container.'
  fi

  distrobox enter ssc-build -- sudo pacman -Syu --needed --noconfirm \
    gcc meson ninja pkgconf git glib2 glib2-devel dbus bluez-libs sbc || \
    fail 'Could not install the build dependencies inside the Arch container.'

  distrobox enter ssc-build -- env SSC_PIPEWIRE_VERSION="$version" \
    "$script_dir/install.sh" || fail 'The SSC module build or install failed.'
fi

say 'SSC modules are installed. Reconnect your Samsung earbuds and select the Samsung Seamless Codec A2DP profile.'
read -r -p 'Press Enter to close this window…' _ || true
