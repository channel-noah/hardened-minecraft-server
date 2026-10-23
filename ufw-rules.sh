#!/bin/bash
# UFW firewall setup. Default policy: deny incoming, allow outgoing.
# SSH is allowed here but is only reachable from the LAN, because the router does not forward port 22.
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 25565/tcp   # Minecraft (the only port forwarded on the router)
sudo ufw enable
sudo ufw status verbose
