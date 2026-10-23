# Hardened Self-Hosted Minecraft Server

An internet-facing Ubuntu server I built and secured from scratch in July 2026 to host a multiplayer game server for about 130 players. I built it as a hands-on way to learn Linux system administration and security fundamentals: hardening a host that is exposed to the internet, keeping it running reliably, and investigating problems through logs.

> All configs in this repo are sanitized. IP addresses, hostnames, usernames, Wi-Fi credentials, and tokens are replaced with placeholders such as `<USER>` and `<LAN_IP>`.

## Architecture

```
  Internet
     |
     |  TCP 25565 only (no other ports forwarded)
     v
+--------------------+
|  Home router       |   DHCP reservation keeps the server's LAN IP fixed
|  (port forward)    |   Dynamic DNS (DuckDNS) gives players a stable hostname
+--------------------+
     |
     v
+---------------------------------------------+
|  Ubuntu Server                              |
|  UFW: default deny incoming                 |
|     allow 25565/tcp  (game)                 |
|     allow 22/tcp     (SSH, LAN-only)        |
|  SSH: key-only, no root login               |
|  fail2ban: bans repeated SSH failures       |
|  systemd -> screen -> Paper (Java)          |
|  cron: nightly backups + DNS updates        |
+---------------------------------------------+
```

**Stack:** Ubuntu Server, OpenSSH, UFW, fail2ban, systemd, cron, screen, OpenJDK, Paper (Minecraft server), DuckDNS

## Security controls

| Control | What I did | Why |
|---|---|---|
| **Minimal attack surface** | Only TCP 25565 is forwarded on the router. SSH (22) is not forwarded at all. | Anything not exposed can't be attacked from the internet. |
| **Host firewall** | UFW with a default-deny incoming policy, allowing only SSH and the game port. | Defense in depth: even if the router were misconfigured, the host still blocks everything else. |
| **SSH hardening** | Ed25519 key authentication only, password login disabled, root login disabled. | Removes password guessing as an attack path and prevents direct root access. |
| **Brute-force protection** | fail2ban `sshd` jail: 5 failures within 10 minutes = 1-hour ban. | Automatically blocks repeated login attempts. |
| **Access control** | Minecraft whitelist enabled and enforced; only approved players can join. | The game port is public, so the application itself must restrict who gets in. |
| **Least privilege** | The server runs as a regular user, not root. | Limits damage if the game server process is ever compromised. |
| **Secrets handling** | Netplan file (Wi-Fi password) set to `600`; DuckDNS script with its token set to `700`. | Only the owner can read files that contain secrets. |
| **Recoverability** | Nightly automated backups with 7-day retention. | Data can be restored after corruption, mistakes, or an incident. |

## Incident: unrecognized connection attempt

**What happened:** While reviewing the server logs, I noticed a connection attempt from a player name I didn't recognize.

**Investigation:** I traced it through the logs and found the cause was a configuration problem rather than a vulnerability: the whitelist was not being enforced, so the server wasn't restricting joins to approved players.

**Fix:** I re-enabled `white-list=true` and `enforce-whitelist=true` in `server.properties`, restarted the server, and confirmed that unlisted players were rejected.

**Verification:** I reviewed the logs to confirm that no unauthorized player had gained access while the setting was off.

**Lesson learned:** Security settings can silently drift after changes to a system. Regular log review is what caught this, and I now re-check access-control settings after any major change to the server.

## Operations

- **Service management:** A systemd unit (`configs/minecraft.service`) starts the server at boot inside a `screen` session, so I can attach to the live console with `screen -r minecraft`.
- **Automated backups:** `scripts/backup.sh` pauses world saving (`save-off` / `save-all`) so the archive is consistent, compresses the world and key config files, resumes saving, and deletes backups older than 7 days. Cron runs it nightly at 4:00 AM.
- **Dynamic DNS:** A cron job updates DuckDNS every 5 minutes, so players can connect with a hostname even when my home IP changes.
- **Stable addressing:** A DHCP reservation on the router pins the server's LAN IP so the port forward always points at the right machine.
- **Updates:** `scripts/get-paper.sh` queries the PaperMC API and downloads the newest build marked stable.

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| Wi-Fi wouldn't connect reliably | The standalone `wpa_supplicant` service conflicted with the instance netplan manages | Disabled the standalone service and pointed the per-interface service at netplan's generated config |
| Server failed to start | Wrong Java version for the Paper build | Installed the OpenJDK version the build required |
| Inconsistent IP addressing | IPv4/IPv6 DHCP issues and a reservation tied to the old Wi-Fi adapter | Moved to wired Ethernet and created a DHCP reservation for the Ethernet adapter's MAC address |

In each case, I worked from the system logs (`journalctl`, service status output) to find the root cause instead of guessing.

## Future improvements

- **Better service monitoring:** The current unit uses `Type=forking` with `RemainAfterExit=yes`, which means systemd can report the service as active even if the Java process has died. Switching to `Type=simple` would let systemd detect crashes and restart the server automatically.
- **Off-machine backups:** Backups currently live on the same disk as the server. Copying them to a second location would protect against drive failure.
- **Centralized log monitoring:** Forwarding logs to a SIEM such as Wazuh or Splunk would let me set alerts instead of relying on manual review.
- **SSH source restriction:** Limit the UFW SSH rule to the LAN subnet instead of allowing it from any address.

## Repo contents

```
configs/
  sshd_config.snippet          SSH hardening settings
  jail.local                   fail2ban SSH jail
  ufw-rules.sh                 firewall rules
  minecraft.service            systemd unit
  server.properties.snippet    whitelist settings
  netplan-50-cloud-init.yaml   network config
  crontab.txt                  scheduled jobs
scripts/
  backup.sh                    backup with retention
  start.sh                     server launch script
  get-paper.sh                 fetches the latest stable Paper build
  duck.sh                      DuckDNS updater
```
