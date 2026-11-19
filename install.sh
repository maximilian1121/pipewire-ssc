#!/usr/bin/env bash
set -euo pipefail

# Build only the two PipeWire SPA modules needed for SSC. This does not build
# or replace the PipeWire daemon or any distro packages.

INSTALLED_PIPEWIRE_VERSION="${SSC_PIPEWIRE_VERSION:-$(pipewire --version 2>/dev/null | sed -nE 's/.* ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' | head -n1)}"
case "$INSTALLED_PIPEWIRE_VERSION" in
  0.3.59) PIPEWIRE_VERSION="$INSTALLED_PIPEWIRE_VERSION"; PATCH_VERSION="$PIPEWIRE_VERSION" ;;
  1.6.[0-9]*) PIPEWIRE_VERSION="$INSTALLED_PIPEWIRE_VERSION"; PATCH_VERSION=1.6.0 ;;
  *)
    echo "No SSC patch is available for PipeWire ${INSTALLED_PIPEWIRE_VERSION:-unknown}." >&2
    echo "Supported releases: PipeWire 0.3.59 and the 1.6.x series." >&2
    exit 1
    ;;
esac
SYSTEM_SPA_DIR="$(pkg-config --variable=plugindir libspa-0.2 2>/dev/null || true)"
if [[ -z "$SYSTEM_SPA_DIR" || ! -d "$SYSTEM_SPA_DIR" ]]; then
  echo "Could not find PipeWire's SPA plugin directory (pkg-config libspa-0.2)." >&2
  exit 1
fi

for tool in git meson ninja pkg-config systemctl; do
  command -v "$tool" >/dev/null || { echo "Missing required tool: $tool" >&2; exit 1; }
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PATCH="$SCRIPT_DIR/pipewire-$PATCH_VERSION-ssc.patch"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ssc-pipewire"
SRC_DIR="$CACHE_DIR/pipewire-$PIPEWIRE_VERSION"
BUILD_DIR="$CACHE_DIR/build-$PIPEWIRE_VERSION"
CUSTOM_SPA_DIR="$HOME/.local/lib/ssc-pipewire/spa-0.2"
DROPIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/pipewire.service.d"
DROPIN="$DROPIN_DIR/ssc.conf"
WP_DROPIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/wireplumber.service.d"
WP_DROPIN="$WP_DROPIN_DIR/ssc.conf"

for existing in "$DROPIN" "$WP_DROPIN"; do
  if [[ -e "$existing" ]] && ! grep -Fq "Managed by the SSC PipeWire installer" "$existing"; then
    echo "Refusing to overwrite existing file: $existing" >&2
    exit 1
  fi
done

mkdir -p "$CACHE_DIR"
if [[ ! -d "$SRC_DIR/.git" ]]; then
  git clone --depth 1 --branch "$PIPEWIRE_VERSION" \
    https://gitlab.freedesktop.org/pipewire/pipewire.git "$SRC_DIR"
fi
if [[ ! -f "$SRC_DIR/spa/plugins/bluez5/a2dp-codec-ssc.c" ]]; then
  git -C "$SRC_DIR" apply --check "$PATCH"
  git -C "$SRC_DIR" apply "$PATCH"
elif ! grep -q 'MEDIA_CODEC_FACTORY_LIB("ssc")' "$SRC_DIR/spa/plugins/bluez5/codec-loader.c"; then
  echo "PipeWire source is partially patched; remove $SRC_DIR and retry." >&2
  exit 1
fi

if [[ ! -f "$BUILD_DIR/build.ninja" ]]; then
  meson setup "$BUILD_DIR" "$SRC_DIR" \
    --prefix=/usr \
    -Ddocs=disabled -Dman=disabled -Dtests=disabled -Dexamples=disabled \
    -Dbluez5=enabled \
    -Dbluez5-backend-hsp-native=disabled \
    -Dbluez5-backend-hfp-native=disabled \
    -Dbluez5-backend-ofono=disabled \
    -Dbluez5-backend-hsphfpd=disabled
fi

# Compile only the BlueZ plugin and the SSC codec module.
ninja -C "$BUILD_DIR" \
  spa/plugins/bluez5/libspa-bluez5.so \
  spa/plugins/bluez5/libspa-codec-bluez5-ssc.so

mkdir -p "$CUSTOM_SPA_DIR/bluez5"
install -m 0644 "$BUILD_DIR/spa/plugins/bluez5/libspa-bluez5.so" "$CUSTOM_SPA_DIR/bluez5/"
install -m 0644 "$BUILD_DIR/spa/plugins/bluez5/libspa-codec-bluez5-ssc.so" "$CUSTOM_SPA_DIR/bluez5/"

mkdir -p "$DROPIN_DIR"
cat > "$DROPIN" <<EOF
# Managed by the SSC PipeWire installer
[Service]
Environment=SPA_PLUGIN_DIR=$CUSTOM_SPA_DIR:$SYSTEM_SPA_DIR
EOF

# WirePlumber loads the BlueZ SPA monitor which discovers A2DP codecs.
mkdir -p "$WP_DROPIN_DIR"
cat > "$WP_DROPIN" <<EOF
# Managed by the SSC PipeWire installer
[Service]
Environment=SPA_PLUGIN_DIR=$CUSTOM_SPA_DIR:$SYSTEM_SPA_DIR
EOF

systemctl --user daemon-reload
systemctl --user restart pipewire.service
systemctl --user restart wireplumber.service

echo "SSC modules installed in $CUSTOM_SPA_DIR/bluez5"
echo "PipeWire and WirePlumber restarted. Reconnect your Bluetooth device to load SSC."
