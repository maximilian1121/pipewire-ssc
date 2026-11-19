# Samsung SSC for PipeWire

Add Samsung Scalable Codec (SSC) support to PipeWire's Bluetooth A2DP source
path. SSC UHQ is the 24-bit, 96 kHz mode used by compatible Samsung earbuds.

This project builds a small PipeWire BlueZ SPA module and an SSC codec module
into a user-local directory. It does not replace the PipeWire daemon or any
distro package. The installer adds a user-service override so PipeWire and
WirePlumber find the modules, then restarts those services to load them.

## Tested

| Component | Tested version / result |
| --- | --- |
| Linux distribution | KDE neon (Ubuntu 24.04 base) |
| PipeWire | 1.6.0 |
| WirePlumber | 0.5.10 |
| BlueZ | 5.72 |
| Earbuds | Samsung Galaxy Buds4 Pro |
| Negotiated codec | SSC (`api.bluez5.codec = "ssc"`) |
| Negotiated format | `s24-32le`, stereo, 96 kHz (SSC UHQ) |

The SSC encoder comes from the public [samsung-ssc-encoder project](https://github.com/WillyBilly06/samsung-ssc-encoder).
The PipeWire integration patch vendors the encoder sources and preserves their
BSD-3-Clause and CELT/Opus notices.

## Install

The installer supports PipeWire 0.3.59 and 1.6.0, and systemd user services.
On KDE neon or Ubuntu 24.04, install the build dependencies:

```sh
sudo apt install build-essential git meson ninja-build pkg-config \
  libspa-0.2-dev libpipewire-0.3-dev libglib2.0-dev libdbus-1-dev \
  libbluetooth-dev libsbc-dev
```

Clone this repository and install the modules as your regular user:

```sh
git clone https://github.com/OWNER/ssc-pipewire.git
cd ssc-pipewire
./install.sh
```

The script detects the installed PipeWire version and builds the modules from
the matching source tag. It stores them under `~/.local/lib/ssc-pipewire/` and
restarts PipeWire and WirePlumber. Audio is briefly interrupted. Do not run
the installer with `sudo`.

## Steam Deck

In Desktop Mode, download the repository files together (or clone the repo),
then double-click `Samsung-SSC-Steam-Deck.desktop` and choose **Execute**. Keep
the `.desktop` file beside `steamdeck-install.sh` and the rest of the repo.
The launcher opens Konsole, checks SteamOS and PipeWire, then runs the
user-local installer. It does not make the OS image writable or install system
packages.

Steam Deck support is still experimental. The launcher currently proceeds only
when PipeWire reports exactly 0.3.59 and the required build tools and
development libraries already exist. SteamOS does not normally include a full
development toolchain, so this may stop with a dependency message. Installing
packages with `pacman` requires disabling SteamOS read-only mode, and [Valve
notes that changes made outside Flatpak may be removed by a SteamOS
update](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C).
The 0.3.59 codec patch has not yet been tested on physical Deck hardware; this
launcher does not claim a guaranteed working install.

Connect your earbuds. SSC should be available as the A2DP profile named
**Samsung Seamless Codec**. To select it from a terminal, use the card name
shown by `pactl list cards`:

```sh
pactl set-card-profile bluez_card.MAC_WITH_UNDERSCORES a2dp-sink
```

Verify the active codec and mode:

```sh
pactl list sinks | grep -E 'Name: bluez_output|Sample Specification|api.bluez5.codec'
```

SSC UHQ should report `api.bluez5.codec = "ssc"` and a sink format of
`s24-32le 2ch 96000Hz`. Other SSC-capable devices or configurations may use a
different SSC mode or sample rate.

## Uninstall

From the cloned repository, run:

```sh
./uninstall.sh
```

This removes the user-local modules and the PipeWire/WirePlumber service
overrides, then restarts both services. It does not remove build files in
`~/.cache/ssc-pipewire/`.

## Compatibility

PipeWire's BlueZ codec interface is private and changes between releases, so
the project carries separate source patches. The 1.6.0 path is confirmed on the
KDE neon setup listed above. The 0.3.59 patch is included for older systems
such as SteamOS, but has not been tested on a Steam Deck; SteamOS compatibility
also depends on its installed PipeWire version matching a supported release.
Other PipeWire versions currently stop with a clear unsupported-version error.
The installer supports systemd user services; other service managers and
distributions still need packaging work.

This project adds A2DP playback using SSC. It does not implement Samsung's
companion-app features, earbud firmware updates, ANC controls, multipoint
management, or LE Audio.

## License

The integration and installer are MIT-licensed. The vendored SSC encoder
retains its BSD-3-Clause license and the upstream CELT/Opus notices; see
[`LICENSES/`](LICENSES/) and the license file carried in the patch.

Samsung and Galaxy Buds are trademarks of Samsung Electronics. This project
is independent and is not affiliated with or endorsed by Samsung.
