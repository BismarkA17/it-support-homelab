#!/usr/bin/env bash
# Starts the lab. DC01 first so the domain is up before the staff machine.
az vm start -g rg-homelab -n DC01
az vm start -g rg-homelab -n LAPTOP-001
az vm list -g rg-homelab -d --query "[].{VM:name, PublicIP:publicIps, State:powerState}" -o table
