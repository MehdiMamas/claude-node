#!/usr/bin/env bash
# Optional CI runner: installs gh-runners as the unprivileged user "ghrunner"
# and joins this node to the owner's main host with a one-time join code.
# Run by the admin: sudo /opt/claude-node/node/runner.sh [--force]
# --force skips the RAM check. See docs/runner.md.
set -euo pipefail

user=ghrunner
install_url=https://raw.githubusercontent.com/MehdiMamas/gh-runners/main/install.sh
min_kb=8000000 # 8 GB

force=0
for arg in "$@"; do
	case "$arg" in
	--force) force=1 ;;
	*) echo "runner.sh: unknown option $arg" >&2; exit 2 ;;
	esac
done

if [ "$(id -u)" -ne 0 ]; then
	echo "runner.sh: run as root: sudo $0" >&2
	exit 1
fi

mem_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
if [ "$mem_kb" -lt "$min_kb" ] && [ "$force" -ne 1 ]; then
	echo "runner.sh: this node has $((mem_kb / 1024)) MB RAM; a CI runner needs 8 GB or more. Use --force to install anyway." >&2
	exit 1
fi

if ! id "$user" >/dev/null 2>&1; then
	useradd -m -s /bin/bash "$user"
	passwd -l "$user" >/dev/null
fi
uid=$(id -u "$user")
loginctl enable-linger "$user"
systemctl start "user@${uid}.service"

# Read the code hidden, from the terminal or stdin. It stays in this shell
# variable and the child's environment: never argv, a file or history.
printf 'Join code from the main host (Machines, Add a machine); empty to cancel: ' >&2
code=""
IFS= read -rs code || true
echo >&2
if [ -z "$code" ]; then
	echo "No code entered; nothing installed." >&2
	exit 0
fi

# The code goes in the environment only (sudo --preserve-env), not in the
# argv of sudo or env, so it never shows in ps.
export GH_RUNNERS_JOIN="$code"
sudo --preserve-env=GH_RUNNERS_JOIN -u "$user" env "XDG_RUNTIME_DIR=/run/user/${uid}" \
	"HOME=/home/${user}" sh -c "curl -fsSL $install_url | sh"
echo "Done. Check the node under Machines on the main host." >&2
