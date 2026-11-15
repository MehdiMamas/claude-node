# Raspberry Pi 4 / 5

Turn a Pi into a node from a flashed card. Same user-data as the cloud guide; then the sign-ins in [add-a-node.md](add-a-node.md).

## Hardware

- Pi 4 or Pi 5 with **4 GB RAM or more**. The installer refuses less.
- **64-bit OS only.** Claude Code ships only aarch64 builds on ARM, so 32-bit images do not work.

## 1. Flash

Use Raspberry Pi Imager (2.0 or newer for Raspberry Pi OS: it generates cloud-init files by default) and pick one:

- Ubuntu Server 24.04 LTS (64-bit), or
- Raspberry Pi OS Lite (64-bit, Debian Trixie). Use an image released 24 November 2025 or later; the earlier Trixie image has no cloud-init.

## 2. Replace `user-data`

After flashing, open the card's FAT boot partition (the one holding `config.txt`; it is labelled `system-boot` on Ubuntu and `bootfs` on Raspberry Pi OS, but the sources below do not state the labels, so go by `config.txt`). It holds `user-data`, `network-config` and `meta-data`.

Replace `user-data` with this repo's `cloud-init/user-data.yaml`, with `REPLACE-WITH-YOUR-PUBLIC-KEY` swapped for your SSH public key. Keep the first line `#cloud-config` (mandatory). Leave `meta-data` alone. No secrets go in the file.

The repo's file creates no user: it keeps the image's default admin user and adds your key. Imager's user and password settings live in the old `user-data`, so they are lost when you replace it.

## 3. No cable: Wi-Fi

Put this in `network-config` on the same partition (YAML, netplan style). Prefer Ethernet when you can.

```yaml
network:
  version: 2
  wifis:
    wlan0:
      dhcp4: true
      optional: true
      regulatory-domain: "XX"   # your two-letter country code
      access-points:
        "YOUR-WIFI-NAME":
          password: "YOUR-WIFI-PASSWORD"
```

Raspberry Pi OS's example also sets `renderer: NetworkManager`; keep any such line already in the file on your card. Check the final layout against the commented template that Imager wrote there.

The password is plain text on the card; do not share the card.

## 4. Boot and sign in

1. Insert the card, power on, wait a few minutes.
2. Find the Pi: your router's client list, or `ping <hostname>.local`.
3. `ssh <user>@<ip>`. The default user is `ubuntu` on Ubuntu. On Raspberry Pi OS it is whatever the user-data or Imager set. Replacing `user-data` drops Imager's user, so on Pi OS add a `users:` block yourself if no default user exists on your image.
4. `cloud-init status --wait` until it prints `status: done`.
5. Follow the one-time sign-ins in [add-a-node.md](add-a-node.md#2-one-time-sign-ins-need-your-hands).

## Notes

- SD cards wear out. For an always-on node, boot from an SSD over USB.
- Memory caps are percentages, so nothing Pi-specific is needed.
- The CI runner needs 8 GB RAM ([runner.md](runner.md)).

## Sources (fetched 2026-11-14)

- Raspberry Pi, [cloud-init on Raspberry Pi OS](https://www.raspberrypi.com/news/cloud-init-on-raspberry-pi-os/): `user-data`, `network-config`, `meta-data` on the FAT boot partition; `#cloud-config` mandatory; Wi-Fi in `network-config`; Imager 2.0; Trixie image of 24 Nov 2025.
- Ubuntu, [headless usage](https://ubuntu.com/hardware/docs/boards/how-to/special_hardware/headless-usage/): seed files, `wifis` example, default user `ubuntu`.
- cloud-init, [NoCloud datasource](https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html): file names `user-data`, `meta-data`, `network-config`.
