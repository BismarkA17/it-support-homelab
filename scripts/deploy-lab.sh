#!/usr/bin/env bash
# Builds the Xotic Inc lab in Azure: network, firewall, domain controller, staff machine.
# Run in Azure Cloud Shell (Bash):  bash deploy-lab.sh
# You will be asked for your home IP and an admin password. Nothing is saved to disk.
set -euo pipefail

RG="rg-homelab"
LOCATION="uksouth"
VNET="vnet-xotic"
SUBNET="snet-office"
NSG="nsg-office"
DC_NAME="DC01"
DC_IP="10.0.1.4"
CLIENT_NAME="LAPTOP-001"
ADMIN_USER="xoticadmin"
DOMAIN="corp.xotic.local"
NETBIOS="XOTIC"
SIZE="${VM_SIZE:-Standard_B2ms}"    # Standard_B2s ran out of capacity in UK South (Nov 2026); override with VM_SIZE=...
IMAGE="Win2022Datacenter"

echo "== Xotic Inc lab build =="
read -rp "Your home public IP (google 'what is my IP'): " MY_IP
echo "Admin password: 12+ characters, with upper case, lower case, a number and a symbol."
echo "Avoid single quotes. You'll use this to log in, so store it in a password manager."
read -rsp "Admin password: " ADMIN_PW; echo
read -rsp "Confirm password: " ADMIN_PW2; echo
[[ "$ADMIN_PW" == "$ADMIN_PW2" ]] || { echo "Passwords don't match."; exit 1; }

echo "-> Registering Azure services (first run on a new subscription)"
az provider register -n Microsoft.Compute --wait
az provider register -n Microsoft.Network --wait

echo "-> Checking vCPU quota (need 4)"
az vm list-usage --location "$LOCATION" -o table | grep -i "Total Regional vCPUs" || true

echo "-> [1/8] Network and subnet"
az network vnet create -g "$RG" -n "$VNET" -l "$LOCATION" \
  --address-prefixes 10.0.0.0/16 --subnet-name "$SUBNET" --subnet-prefixes 10.0.1.0/24 -o none

echo "-> [2/8] Firewall (NSG): allow RDP only from $MY_IP"
az network nsg create -g "$RG" -n "$NSG" -l "$LOCATION" -o none
az network nsg rule create -g "$RG" --nsg-name "$NSG" -n Allow-RDP-Home --priority 100 \
  --access Allow --protocol Tcp --direction Inbound \
  --source-address-prefixes "$MY_IP/32" --destination-port-ranges 3389 -o none
az network vnet subnet update -g "$RG" --vnet-name "$VNET" -n "$SUBNET" --network-security-group "$NSG" -o none

echo "-> [3/8] Domain controller VM $DC_NAME at $DC_IP (takes a few minutes)"
az vm create -g "$RG" -n "$DC_NAME" -l "$LOCATION" --image "$IMAGE" --size "$SIZE" \
  --vnet-name "$VNET" --subnet "$SUBNET" --private-ip-address "$DC_IP" \
  --public-ip-address "pip-$DC_NAME" --public-ip-sku Standard --nsg "" \
  --admin-username "$ADMIN_USER" --admin-password "$ADMIN_PW" \
  --storage-sku StandardSSD_LRS -o none

echo "-> [4/8] Installing Active Directory and creating domain $DOMAIN (about 10 minutes)"
PW_PS=${ADMIN_PW//\'/\'\'}
PS_SCRIPT="\$ErrorActionPreference='Stop'
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
\$pw = ConvertTo-SecureString '$PW_PS' -AsPlainText -Force
Install-ADDSForest -DomainName '$DOMAIN' -DomainNetbiosName '$NETBIOS' -SafeModeAdministratorPassword \$pw -InstallDns -NoRebootOnCompletion -Force"
ENCODED=$(printf '%s' "$PS_SCRIPT" | iconv -t UTF-16LE | base64 -w0)
az vm extension set -g "$RG" --vm-name "$DC_NAME" --name CustomScriptExtension \
  --publisher Microsoft.Compute --version 1.10 \
  --protected-settings "{\"commandToExecute\":\"powershell -ExecutionPolicy Unrestricted -EncodedCommand $ENCODED\"}" -o none
unset PS_SCRIPT ENCODED PW_PS

echo "-> [5/8] Restarting $DC_NAME to finish promotion"
az vm restart -g "$RG" -n "$DC_NAME" -o none
echo "   waiting 5 minutes for AD services to start..."
sleep 300

echo "-> [6/8] Pointing the network's DNS at the domain controller"
az network vnet update -g "$RG" -n "$VNET" --dns-servers "$DC_IP" -o none

echo "-> [7/8] Staff machine $CLIENT_NAME (not joined to the domain: that's your job)"
az vm create -g "$RG" -n "$CLIENT_NAME" -l "$LOCATION" --image "$IMAGE" --size "$SIZE" \
  --vnet-name "$VNET" --subnet "$SUBNET" \
  --public-ip-address "pip-$CLIENT_NAME" --public-ip-sku Standard --nsg "" \
  --admin-username "$ADMIN_USER" --admin-password "$ADMIN_PW" \
  --storage-sku StandardSSD_LRS -o none
unset ADMIN_PW ADMIN_PW2

echo "-> [8/8] Auto-shutdown at 23:00 UTC on both VMs"
az vm auto-shutdown -g "$RG" -n "$DC_NAME" --time 2300 -o none
az vm auto-shutdown -g "$RG" -n "$CLIENT_NAME" --time 2300 -o none

echo
echo "== Done =="
az vm list -g "$RG" -d --query "[].{VM:name, PublicIP:publicIps, PrivateIP:privateIps, State:powerState}" -o table
echo
echo "Log in to $DC_NAME with RDP as  $NETBIOS\\$ADMIN_USER"
echo "Log in to $CLIENT_NAME with RDP as  $CLIENT_NAME\\$ADMIN_USER  (local account until it joins the domain)"
