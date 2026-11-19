# Samsung SSC for PipeWire

Add Samsung Seamless Codec (SSC) support to PipeWire's Bluetooth A2DP source
path. SSC UHQ is the 24-bit, 96 kHz mode used by compatible Samsung earbuds.

This project builds a small PipeWire BlueZ SPA module and an SSC codec module
into a user-local directory. It does not replace the PipeWire daemon or any
distro package. The installer adds a user-service override so PipeWire and
WirePlumber find the modules, then restarts those services to load them.

## Verified setups

| System | PipeWire | Bluetooth device | Verified result |
| --- | --- | --- | --- |
| KDE neon (Ubuntu 24.04 base) | 1.6.0 | Galaxy Buds4 Pro | SSC UHQ, 24-bit, stereo, 96 kHz |
| Steam Deck LCD (SteamOS) | 1.6.8 | Galaxy Buds4 Pro | SSC UHQ, 24-bit, stereo, 96 kHz |

On both systems, PipeWire reported `api.bluez5.codec = "ssc"` and the sink
format `s24-32le 2ch 96000Hz`. KDE neon used WirePlumber 0.5.10 and BlueZ 5.72.

The SSC encoder comes from the public [samsung-ssc-encoder project](https://github.com/WillyBilly06/samsung-ssc-encoder).
The PipeWire integration patch vendors the encoder sources and preserves their
BSD-3-Clause and CELT/Opus notices.

## Install

The installer supports PipeWire 0.3.59 and the 1.6.x series, and systemd user services.
On KDE neon or Ubuntu 24.04, install the build dependencies:

```sh
sudo apt install build-essential git meson ninja-build pkg-config \
  libspa-0.2-dev libpipewire-0.3-dev libglib2.0-dev libdbus-1-dev \
  libbluetooth-dev libsbc-dev
```

Clone this repository and install the modules as your regular user:

```sh
git clone https://github.com/maximilian1121/pipewire-ssc.git
cd pipewire-ssc
./install.sh
```

The script detects the installed PipeWire version and builds the modules from
the matching source tag. It stores them under `~/.local/lib/ssc-pipewire/` and
restarts PipeWire and WirePlumber. Audio is briefly interrupted. Do not run
the installer with `sudo`.

## Steam Deck

In Desktop Mode, download only `Samsung-SSC-Steam-Deck.desktop` from the
GitHub repository, right-click it, choose **Properties**, allow it to run as a
program, then double-click and choose **Execute**. It opens Konsole, downloads
the current project files from GitHub, checks SteamOS and PipeWire, and runs
the user-local installer.

Steam Deck support is experimental. The launcher supports PipeWire 0.3.59 and
1.6.x. If host build tools are missing, it creates a user-owned Arch Distrobox
and installs build dependencies inside it. On one Steam Deck LCD running PipeWire
1.6.8, the 1.6.0 patch applied, both modules built, and the user service
overrides installed and restarted successfully. A paired Galaxy Buds4 Pro
offered the Samsung Seamless Codec profile; after selecting it, PipeWire
reported `api.bluez5.codec = "ssc"` and `s24-32le 2ch 96000Hz`. The launcher
does not make the SteamOS image writable or install packages on the host. It
downloads project files into `~/.cache/ssc-pipewire-launch` and leaves the build
container and cache in place for later runs.

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
`~/.cache/ssc-pipewire/` or the optional Arch build container. To remove that
container as well, run `distrobox rm ssc-build`.

## Compatibility

PipeWire's BlueZ codec interface is private and changes between releases, so
the project carries separate source patches. The 1.6.0 path is confirmed on the
KDE neon setup listed above, and the same patch built and negotiated SSC with
Galaxy Buds4 Pro on a Steam Deck LCD running PipeWire 1.6.8. The 0.3.59 patch is
included for older systems but has not been tested on hardware. Other PipeWire
versions currently stop with a clear unsupported-version error.
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
