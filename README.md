# DankMaterialShell Plugins

A collection of third-party plugins for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell).

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) ![Wayland](https://img.shields.io/badge/Wayland-FFBC00?style=for-the-badge&logo=wayland&logoColor=black) ![Qt](https://img.shields.io/badge/Qt-%23217346.svg?style=for-the-badge&logo=Qt&logoColor=white) ![QML](https://img.shields.io/badge/QML-41CD52?style=for-the-badge&logo=qt&logoColor=white) ![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=hyprland&logoColor=black)

[DankLinux](https://danklinux.com) | [Quickshell](https://quickshell.outfoxxed.me/)

## Plugins

Should work on any Quickshell-supported compositor (Hyprland, Niri, Sway, labwc, MangoWC, Scroll). Tested on Hyprland.

### [Tailscale Manager](./dms-tailscale-manager)

A DMS bar widget for managing your Tailscale connection and peers.

![Tailscale](./assets/dms-tailscale.png)

<details>
<summary>Settings</summary>

![Tailscale Settings](./assets/dms-tailscale_settings.png)

</details>

Install:

```bash
git clone --depth 1 https://github.com/hxreborn/dms-plugins.git /tmp/dms-plugins \
  && cp -r /tmp/dms-plugins/dms-tailscale-manager ~/.config/DankMaterialShell/plugins/tailscaleManager \
  && rm -rf /tmp/dms-plugins
```

### [Screen Recorder](./dms-screen-recorder)

A DMS bar widget wrapping `gpu-screen-recorder` for screen recording with configurable video, audio, and capture settings.

![Screen Recorder](./assets/dms-screen-recorder.png)

<details>
<summary>Settings</summary>

![Screen Recorder Settings](./assets/dms-screen-recorder-settings.png)

</details>

Install:

```bash
git clone --depth 1 https://github.com/hxreborn/dms-plugins.git /tmp/dms-plugins \
  && cp -r /tmp/dms-plugins/dms-screen-recorder ~/.config/DankMaterialShell/plugins/screenRecorder \
  && rm -rf /tmp/dms-plugins
```

Then enable in Settings -> Plugins -> Scan for Plugins.

## Credits

Both plugins were inspired by [Noctalia's plugin collection](https://github.com/noctalia-dev/noctalia-plugins).

## License

[MIT](./LICENSE)
