#!/usr/bin/env bash
# claude-node installer: turns a stock Ubuntu/Debian server into a node.
# Run as root. Safe to run again. Flag: --close-public-ssh (see step 6).
set -euo pipefail

CLOSE_SSH=0
for a in "$@"; do
  case "$a" in
    --close-public-ssh) CLOSE_SSH=1 ;;
    *) echo "unknown flag: $a" >&2; exit 2 ;;
  esac
done

[ "$(id -u)" -eq 0 ] || { echo "run as root (sudo)" >&2; exit 1; }
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APT=(-o DPkg::Lock::Timeout=600)
export DEBIAN_FRONTEND=noninteractive

# write_file PATH MODE: stdin -> PATH, only touches it when content differs
write_file() {
  local tmp
  tmp="$(mktemp)"
  cat >"$tmp"
  if [ -f "$1" ] && cmp -s "$tmp" "$1"; then rm -f "$tmp"; return 0; fi
  install -D -m "$2" "$tmp" "$1"
  rm -f "$tmp"
}

echo "== 1. checks"
case "$(uname -m)" in
  aarch64|x86_64) ;;
  *) echo "unsupported CPU $(uname -m): Claude Code ships only aarch64 and x86_64" >&2; exit 1 ;;
esac
mem_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
# 4 GB machines report a bit under 4000000 kB, so the floor is 3.5 GB
if [ "$mem_kb" -lt 3500000 ]; then
  echo "under 4 GB RAM ($((mem_kb / 1024)) MB): Claude Code needs at least 4 GB" >&2
  exit 1
fi

echo "== 2. packages"
apt-get "${APT[@]}" update
apt-get "${APT[@]}" install -y curl git jq ufw unattended-upgrades openssh-server
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "== 3. users"
for u in claude ghrunner; do
  id "$u" >/dev/null 2>&1 || useradd -m -s /bin/bash "$u"
  passwd -l "$u" >/dev/null
done
loginctl enable-linger claude ghrunner
systemctl start "user@$(id -u claude).service" "user@$(id -u ghrunner).service"

echo "== 3b. memory limits"
write_file /etc/systemd/system/user.slice.d/50-claude-node.conf 0644 <<'CONF'
[Slice]
MemoryHigh=80%
MemoryMax=90%
CONF
systemctl daemon-reload

echo "== 4. ssh"
write_file /etc/ssh/sshd_config.d/10-claude-node.conf 0644 <<'CONF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
CONF
mkdir -p /run/sshd
sshd -t && systemctl try-reload-or-restart ssh

echo "== 5. tailscale"
command -v tailscale >/dev/null 2>&1 || curl -fsSL https://tailscale.com/install.sh | sh
TS_NOTE=""
if ! tailscale status >/dev/null 2>&1; then
  TS_NOTE="Run: sudo tailscale up"
  echo "$TS_NOTE"
fi

echo "== 6. firewall"
if virt="$(systemd-detect-virt --container 2>/dev/null)"; then
  echo "skipped: running in a container ($virt)"
else
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow in on tailscale0
  # Once closed, public SSH stays closed on later runs (marker file).
  SSH_CLOSED=/etc/claude-node/public-ssh-closed
  if [ -f "$SSH_CLOSED" ]; then
    echo "public SSH stays closed ($SSH_CLOSED)"
  else
    ufw allow 22/tcp
  fi
  if [ "$CLOSE_SSH" -eq 1 ] && [ ! -f "$SSH_CLOSED" ]; then
    if tailscale status --json | jq -e '.BackendState=="Running"' >/dev/null; then
      ufw delete allow 22/tcp
      install -D -m 0644 /dev/null "$SSH_CLOSED"
      echo "public SSH closed"
    else
      echo "not closing public SSH: Tailscale is not running" >&2
    fi
  fi
  ufw --force enable
fi

echo "== 7. claude code"
if [ ! -x /home/claude/.local/bin/claude ]; then
  sudo -iu claude bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
fi
sudo -u claude mkdir -p /home/claude/rc

echo "== 8. remote-control unit"
UNIT="$SRC/systemd/claude-remote-control.service"
if [ -f "$UNIT" ]; then
  install -d -o claude -g claude /home/claude/.config /home/claude/.config/systemd /home/claude/.config/systemd/user
  install -o claude -g claude -m 0644 "$UNIT" /home/claude/.config/systemd/user/claude-remote-control.service
  systemctl --user -M claude@ daemon-reload
  systemctl --user -M claude@ enable claude-remote-control
else
  echo "no node/systemd/claude-remote-control.service in this checkout: skipped"
fi

echo "== 9. summary"
cat <<MSG
Done: users claude and ghrunner, memory limits, SSH by key only, Tailscale installed, firewall, Claude Code.
Remaining one-time steps, in order (see docs/add-a-node.md):
  1. sudo tailscale up            (open the URL, approve the node)
  2. ssh <admin>@<node-name> over Tailscale; only if that works:
     sudo $SRC/install.sh --close-public-ssh
  3. sudo -iu claude, then: claude auth login
     then: cd ~/rc && claude remote-control --spawn same-dir --permission-mode bypassPermissions
     (answer y, Ctrl+C, exit), then:
     sudo systemctl --user -M claude@ start claude-remote-control
  4. optional: node/runner.sh
MSG
