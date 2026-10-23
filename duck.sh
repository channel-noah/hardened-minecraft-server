#!/bin/bash
# DuckDNS updater (chmod 700 — the real file contains a secret token)
echo url="https://www.duckdns.org/update?domains=<DUCK_SUBDOMAIN>&token=<DUCK_TOKEN>&ip=" | curl -k -o ~/duckdns/duck.log -K -
