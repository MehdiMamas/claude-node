# claude-node

A one-command setup that turns a plain Linux server (Ubuntu Server LTS, minimal) into an always-on Claude Code node: Claude Code, Remote Control kept alive, departments, a self-hosted CI runner, joined to the node pool. First target: Oracle Always Free (Ampere ARM). Also: Raspberry Pi, old PCs via a USB autoinstall, any Debian/Ubuntu box.

## Rules
- Base OS stays stock Ubuntu Server LTS: no custom distro, no forked packages. Our layer goes on top with cloud-init (servers) and Ubuntu autoinstall (USB).
- Use maintained tools first (cloud-init, systemd, actions/runner, Tailscale); home-made code only for the gap, with the reason written in the issue.
- Security: no secrets in this repo or in cloud-init user-data; sign-ins happen on the node once. SSH by key only, Tailscale only, no public ports. Runner as an unprivileged user, private repos only.
- One Claude account per node owner; never rotate accounts to get around usage limits.
- Every change starts from an issue with a Plan; work in `.worktrees/<branch>`.
- Must work on arm64 and x86_64, including Raspberry Pi 4/5 (Ubuntu Server for Pi or Raspberry Pi OS, both Debian-family). Follow normal Linux conventions: systemd units, /etc and /opt layout, apt packages, FHS paths, no distro-specific hacks.
- Public repo: anyone can contribute. Self-hosted runners never run this repo's CI (fork PRs could run code on them); CI uses GitHub-hosted runners.

## Layout (planned)
- `cloud-init/` user-data for Oracle and other clouds
- `autoinstall/` Ubuntu autoinstall for USB installs
- `node/` scripts and systemd units installed on the node
- `docs/` how to add a node
