#!/usr/bin/env bash
# Run if you can't RDP in because your home IP changed.
read -rp "Your new home public IP: " MY_IP
az network nsg rule update -g rg-homelab --nsg-name nsg-office -n Allow-RDP-Home \
  --source-address-prefixes "$MY_IP/32" -o none
echo "RDP now allowed from $MY_IP"
