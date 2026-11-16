# How the lab is built

The whole environment is created by one script, [`scripts/deploy-lab.sh`](../scripts/deploy-lab.sh), run in Azure Cloud Shell with the Azure CLI. This file explains each step and why it's there.

## The design

```
Internet (home IP only, port 3389)
        |
   [nsg-office]  firewall on the subnet
        |
vnet-xotic 10.0.0.0/16
  snet-office 10.0.1.0/24
     DC01        10.0.1.4 (static)  Windows Server 2022: AD DS + DNS for corp.xotic.local
     LAPTOP-001  10.0.1.x (dynamic) staff machine, joined to the domain by hand
```

## Step by step

| # | Step | What it does | Why |
| --- | --- | --- | --- |
| 1 | Virtual network and subnet | A private network (10.0.0.0/16) with one subnet (10.0.1.0/24) for the office | Machines need a private network to talk to each other, like an office LAN |
| 2 | Network security group (NSG) | A firewall on the subnet. Only one inbound rule: RDP (port 3389) from my home IP | RDP open to the whole internet gets brute-forced within hours. Least-privilege access |
| 3 | Domain controller VM | Windows Server 2022 with a **static** private IP of 10.0.1.4 | Every other machine finds the domain through the DC's IP, so it must never change |
| 4 | Install AD DS and create the forest | Installs Active Directory Domain Services and DNS, creates the domain `corp.xotic.local` (short name XOTIC) | AD is the central list of users, computers and permissions. DNS is how machines find the DC |
| 5 | Restart | Finishes the promotion to domain controller | Required after creating a new forest |
| 6 | Set network DNS to the DC | Every machine on the network now uses 10.0.1.4 for DNS | Joining a domain fails if a machine can't resolve the domain name. This is the most common cause of "can't find domain" tickets |
| 7 | Staff machine | A second Windows VM, deliberately **not** joined to the domain | Joining it is a helpdesk task, done by hand |
| 8 | Auto-shutdown | Both VMs switch off at 23:00 UTC every night | Cost control: VMs bill per hour while running |

## Security and cost choices

- **Password never stored:** the script asks for it at run time. The AD setup command is passed through the VM extension's *protected* settings, which Azure encrypts.
- **Standard SSD disks and B-series VMs:** cheapest sizes that run Windows Server comfortably for a lab.
- **Budget alert** at US$15/month with emails at 50%, 90% and 100%.
- **`stop-lab.sh` / `start-lab.sh`:** VMs are deallocated between sessions, so only disk storage is billed.

## Why the staff machine runs Windows Server, not Windows 11

Azure's Windows 11 images need an eligible licence with multi-tenant hosting rights (e.g. Microsoft 365 E3/E5), which a free trial doesn't include. Windows Server joins a domain, takes Group Policy and logs in domain users the same way, so it stands in for a staff laptop.

## Interview summary

> I built a small company network in Azure using the Azure CLI: a virtual network and subnet, a network security group that only allowed RDP from my IP, and a Windows Server domain controller with a static IP running Active Directory and DNS. I pointed the network's DNS at the domain controller so client machines could find the domain, added a staff machine that I joined to the domain myself, and set auto-shutdown and a budget alert to control cost. It's all scripted, so I can tear it down and rebuild it.

## Commands worth knowing

| Command | Purpose |
| --- | --- |
| `az vm list -g rg-homelab -d -o table` | Show VMs, IPs and power state |
| `az vm deallocate -g rg-homelab -n DC01` | Stop a VM and stop paying for compute |
| `az network nsg rule list -g rg-homelab --nsg-name nsg-office -o table` | Check firewall rules |
| `ipconfig /all` (on Windows) | Check which DNS server a machine is using |
| `nslookup corp.xotic.local` | Check the domain name resolves to 10.0.1.4 |
