# DankMaterialShell Plugins

A collection of third-party plugins for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell).

[DankLinux](https://danklinux.com) | [Quickshell](https://quickshell.outfoxxed.me/) | [Plugin Registry](https://plugins.danklinux.com/)

## Plugins

### [Tailscale Manager](./dms-tailscale-manager)

A DMS bar widget for managing your Tailscale connection and peers.

> Tested on Hyprland. Untested on Niri/Sway.

![Tailscale](./assets/dms-tailscale.png)

<details>
<summary>Settings</summary>

![Tailscale Settings](./assets/dms-tailscale_settings.png)

</details>

### [Screen Recorder](./dms-screen-recorder)

A DMS bar widget wrapping `gpu-screen-recorder` for screen recording with configurable video, audio, and capture settings.

> Tested on Hyprland. Untested on Niri/Sway.

![Screen Recorder](./assets/dms-screen-recorder.png)

<details>
<summary>Settings</summary>

![Screen Recorder Settings](./assets/dms-screen-recorder-settings.png)

</details>

## Installation

```bash
git clone https://github.com/hxreborn/dms-plugins.git
cp -r dms-plugins/<plugin-dir> ~/.config/DankMaterialShell/plugins/<plugin-id>
```

Then enable in Settings -> Plugins -> Scan for Plugins.

## Credits

Both plugins were inspired by [Noctalia's plugin collection](https://github.com/noctalia-dev/noctalia-plugins).
