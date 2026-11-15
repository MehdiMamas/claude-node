# Remote Control unit

`node/systemd/claude-remote-control.service` is a systemd user unit that keeps `claude remote-control` running on the node, so the node is always reachable from claude.ai/code and the phone.

## What it does

- Starts at boot with nobody logged in (user lingering for the `claude` user) and runs in `~/rc`.
- Restarts by itself whenever the process exits. Remote Control gives up after about 10 minutes without a network and exits; the unit restarts it with a growing delay (10 s up to 120 s) and never stops trying. Once the network is back it is connected again within the next restart, so at most about 2 minutes later (46 s in a test with a 14-minute cut).
- After a network drop of up to about 4 h the same sessions come back. After a longer one it comes back with a new session.
- Sets no `CLAUDE_CODE_OAUTH_TOKEN` and no API key. Remote Control needs a full claude.ai login (Pro, Max, Team or Enterprise); tokens from `claude setup-token` and API keys cannot start it.

## One-time first run

The first run asks questions ("Enable Remote Control?", "Trust this folder?") and with no terminal it exits with `Workspace not trusted`. Answer them once by hand:

1. Sign in as the `claude` user and make sure `claude auth login` is done.
2. Run:
   ```
   mkdir -p ~/rc && cd ~/rc && claude remote-control --spawn same-dir --permission-mode bypassPermissions
   ```
3. Answer every prompt with `y`, then press Ctrl+C.
4. From a user with sudo, start the unit:
   ```
   sudo systemctl --user -M claude@ start claude-remote-control
   ```
   Add `enable` the same way to start it at every boot.

The unit runs in `~/rc`, not `$HOME`, because trust is never saved for the home folder.

## Watching it

```
systemctl --user status claude-remote-control
journalctl --user -u claude-remote-control -f
```

From another user: `sudo systemctl --user -M claude@ status claude-remote-control`.

With no terminal, Remote Control redraws its status screen about once a second (several lines each time). The unit sends that screen to `/dev/null` (`StandardOutput=null`) so it does not fill the journal; errors still go to the journal. To find the node, open claude.ai/code or the Claude app: it is listed under the node's host name. To see the status screen itself, stop the unit and run the command from step 2 of the first run by hand.

## bypassPermissions

Sessions started from the phone or claude.ai run in `bypassPermissions` mode: no approval prompts. That is acceptable only because of the rest of the design:

- sessions run as the unprivileged `claude` user, with no sudo and no password;
- the node has no public ports;
- anyone who holds the owner's claude.ai login can run any command as `claude`.

To turn it off, add a drop-in with `systemctl --user edit claude-remote-control` and put:

```
[Service]
ExecStart=
ExecStart=%h/.local/bin/claude remote-control --spawn same-dir --permission-mode default
```

## Known gaps

- A drop longer than about 4 h gives a new session, not the old ones.
- The running server keeps its Claude Code version until it restarts; an auto-update applies at the next start.
- If the login expires (401 after about 26 h of failed renewals) the unit keeps restarting until someone runs `claude auth login` again.
