# IT Support Home Lab

A simulated small-company IT environment built in Azure to practise first and second line support end to end: user accounts, Group Policy, file permissions, ticketing, troubleshooting, Microsoft 365 and automation.

> Work in progress. See [Progress](#progress) for what's built so far.

## What's in the lab

| Component | Purpose | Status |
| --- | --- | --- |
| Windows Server 2022 domain controller | Active Directory, DNS, Group Policy | Not started |
| Windows 11 client | Domain-joined laptop used as a normal staff member | Not started |
| File shares | Department shares with access through security groups | Not started |
| Helpdesk | Ticket queue with priorities and SLAs | Not started |
| Entra ID and Microsoft 365 | Hybrid identity, mailboxes, MFA, Intune | Not started |
| Terraform | Builds and tears down the whole lab | Not started |

Network diagram: coming in Stage 6.

## Fictional company

See [docs/company-profile.md](docs/company-profile.md) for the made-up organisation the lab supports.

## Progress

- [x] Stage 0: Setup (Azure account, budget alert, repo)
- [ ] Stage 1: Build the domain
- [ ] Stage 2: Daily support work
- [ ] Stage 3: Break and fix
- [ ] Stage 4: Cloud identity and Microsoft 365
- [ ] Stage 5: Automation
- [ ] Stage 6: Write-up

## Repo layout

```
docs/
  company-profile.md  the fictional company: departments, staff, locations
  build-log.md        what was done each session
  how-the-lab-is-built.md  every build step explained
  tickets/            one file per support ticket
  runbooks/           step-by-step guides for common tasks and fixes
  kb/                 end-user knowledge-base articles
scripts/              PowerShell scripts
terraform/            infrastructure as code for the whole lab
screenshots/
```

## Skills practised

Filled in as each stage is completed.

## Cost controls

- Budget alert at US$15/month (about £12) on the Azure account
- Auto-shutdown at 23:00 on every VM
- VMs stopped (deallocated) at the end of each session
- From Stage 5, the lab is destroyed between sessions and rebuilt with Terraform
