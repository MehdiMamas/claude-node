# claude-node

Turn a plain Linux box (Ubuntu Server, Raspberry Pi, a cloud VM, an old PC) into an always-on [Claude Code](https://docs.anthropic.com/en/docs/claude-code) node.

Status: planning. Nothing is released yet; the plan is tracked in the [issues](../../issues).

## Why

A laptop sleeps, a phone is not a build machine, and a spare computer or free cloud VM sits idle. One cloud-init file that sets up the same node everywhere means you can reach Claude Code from your phone at any hour and have a place for CI and long jobs.

## What a node will have

- Claude Code installed, with Remote Control kept alive by a systemd service that comes back by itself after a network drop.
- A self-hosted GitHub Actions runner for private repos.
- Tailscale for access, key-only SSH, no public ports.
- Memory limits (systemd slices) so several sessions can share one small machine.

## Roadmap

1. [cloud-init base for Ubuntu Server LTS](../../issues/1) (arm64 and x86_64)
2. [Remote Control kept alive](../../issues/2)
3. [Self-hosted CI runner](../../issues/3)
4. [First node on Oracle Always Free](../../issues/4)
5. [USB autoinstall for spare PCs](../../issues/5)
6. [Raspberry Pi 4/5 support](../../issues/6)

## Contributing

Contributions welcome, see CONTRIBUTING.md. MIT licensed.
