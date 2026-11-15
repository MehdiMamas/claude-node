# Add a node

A node is a plain Ubuntu Server LTS box (arm64 or x86_64, at least 4 GB RAM) set up for Claude Code. Raspberry Pi and other Debian-family boxes work too.

## 1. Install

**a) New cloud VM.** Copy `cloud-init/user-data.yaml`, replace `REPLACE-WITH-YOUR-PUBLIC-KEY` with your SSH public key, and paste it as the user-data when you create the VM. At first boot it clones this repo to `/opt/claude-node` and runs the installer. No secrets go in it.

**b) Existing box.** Over SSH:

```
sudo git clone --depth 1 https://github.com/MehdiMamas/claude-node /opt/claude-node && sudo /opt/claude-node/node/install.sh
```

Running the installer again is safe.

## 2. One-time sign-ins (need your hands)

1. `sudo tailscale up`, open the printed URL, approve the node.
2. From your own machine run `ssh <admin>@<node-name>` over Tailscale. Only when that works, run `sudo /opt/claude-node/node/install.sh --close-public-ssh`. Public SSH closes. (The script refuses if Tailscale is not running. If you ever lock yourself out of a cloud VM, use the provider's serial console; on Oracle Cloud that is the OCI serial console connection.)
   Later runs of `install.sh` keep it closed (marker `/etc/claude-node/public-ssh-closed`; delete it and re-run to open 22 again).
3. `sudo -iu claude`, then `claude auth login` (open the URL, paste the code). Then `cd ~/rc && claude remote-control --spawn same-dir --permission-mode bypassPermissions`, answer every prompt with y, press Ctrl+C. Then `exit`, then `sudo systemctl --user -M claude@ start claude-remote-control`.

## What you see when it worked

- The node appears in the Tailscale admin list.
- The node name appears in claude.ai/code.

## Note on Claude sign-in

Sign in fresh on each node. Do not copy `.credentials.json` from another machine: the same login refreshing on two machines can sign one of them out. This is not confirmed in Anthropic's docs, so the safe path is used.
