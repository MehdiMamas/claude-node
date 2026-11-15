# Optional CI runner (gh-runners)

The node can run GitHub Actions jobs for your **private** repos, as the unprivileged user `ghrunner`. It uses [gh-runners](https://github.com/MehdiMamas/gh-runners), which manages the official runner, runs as a systemd user unit and joins a main host with a one-time code. The node stores no GitHub sign-in and no token.

## Never for a public repo

Do not add a runner on this node for a public repo. GitHub says self-hosted runners "should almost never be used for public repositories", because a pull request from a fork can run code on them. This repo is public, so its own CI stays on GitHub-hosted runners.

## Add the node

Needs 8 GB RAM or more (`--force` skips the check).

1. On the main host, open the gh-runners dashboard, go to Machines, then Add a machine. Copy the one-time join code (it starts with `ghr1-`).
2. On the node run `sudo /opt/claude-node/node/runner.sh`.
3. Paste the code at the prompt. It is not echoed. An empty answer cancels and installs nothing.

The script creates `ghrunner` if missing (locked password, no sudo, lingering on) and runs gh-runners' installer as that user. State lives in `/home/ghrunner/.gh-runners`; the service is the systemd user unit `gh-runners`. It checks:

    sudo systemctl --user -M ghrunner@ is-active gh-runners   # active
    sudo crontab -u ghrunner -l                                # no gh-runners line

The node then appears under Machines on the main host.

## Add runners

From the main host's dashboard, add runners for private repos only. Give them only this node's own labels first. Add the shared `heavy`/`light` labels to a repo only after a green test run there.
