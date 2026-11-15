# USB autoinstall for a spare PC

Turns an old PC into a node with two USB sticks. Needs x86_64 and 4 GB+ RAM. The disk is wiped.

## 1. Prepare the sticks

**Stick 1: the installer.** Download the stock Ubuntu Server 24.04 live-server ISO (https://ubuntu.com/download/server), check its SHA256 against `SHA256SUMS` on releases.ubuntu.com/24.04, and write it to a stick (Linux: `sudo dd if=ubuntu-24.04.*-live-server-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync`; other OSes: Balena Etcher or Rufus).

**Stick 2: the config.** A small stick (or a second partition) formatted FAT and labelled exactly `CIDATA`, holding `user-data` and `meta-data` from `autoinstall/`. In `user-data`, replace `REPLACE-WITH-YOUR-PUBLIC-KEY` with your SSH public key. No secrets go in it.

Linux (replace `/dev/sdY1` with the partition of stick 2; check with `lsblk`):

```
sudo mkfs.vfat -n CIDATA /dev/sdY1
sudo mount /dev/sdY1 /mnt
sudo cp autoinstall/user-data autoinstall/meta-data /mnt/
sudo umount /mnt
```

Other OSes: format the stick as FAT32 with the volume label `CIDATA` (Windows: Format, set "Volume label"; macOS: Disk Utility, MS-DOS (FAT), name `CIDATA`), then copy the two files onto it.

## 2. Install

1. Plug both sticks in, boot from stick 1 (boot menu key, often F12, F10 or Esc).
2. Wait for the installer to find the config. It asks: "Continue with autoinstall? (yes|no)" and warns the disk will be wiped. Type `yes`. This question is kept on purpose so a wrong-disk wipe needs a human.
3. When the installer says to reboot, remove both sticks, then press Enter.
4. First boot clones this repo to `/opt/claude-node` and runs the installer; give it a few minutes.

## 3. Sign-ins

Log in with `ssh admin@<ip-of-the-pc>` using your key, then follow step 2 (One-time sign-ins) in [add-a-node.md](add-a-node.md).
