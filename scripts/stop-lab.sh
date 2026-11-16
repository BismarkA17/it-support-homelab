#!/usr/bin/env bash
# Stops (deallocates) both VMs so they stop using credit. Run at the end of every session.
az vm deallocate -g rg-homelab -n LAPTOP-001 --no-wait
az vm deallocate -g rg-homelab -n DC01
echo "Lab stopped."
