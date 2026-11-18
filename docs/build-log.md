# Build log

One entry per session: what was done, what broke, what was learned.

## Session 1: Stage 0 setup

Date: 2026-11-16

- Created GitHub repo and folder structure
- Azure free trial active ("Azure subscription 1", $200 credit for 30 days, spending limit on)
- Budget `homelab-budget`: US$15/month (billing currency is USD), email alerts at 50%, 90% and 100% of actual cost
- Resource group `rg-homelab` created in UK South

Notes:

- Fictional company: Xotic Inc (logistics), domain corp.xotic.local
- Free trial ends 30 days after sign-up; aim to finish Stages 1-4 inside that window

## Session 2: Active Directory basics

Date: 2026-11-18

- Connected to DC01 over RDP (Windows App). First fault: typo in the IP (40.120.59.239 vs .58.239), fixed by checking the address
- Fixed clipboard not pasting into the RDP session (clipboard redirection, reconnect)
- Explored ADUC: default containers vs OUs (Group Policy only links to OUs)
- Ran New-XoticUsers.ps1: created Xotic OU structure (5 department OUs, Computers, Disabled Users, Groups), 5 SG-<Dept> security groups, 50 users from xotic-users.csv with change-password-at-next-logon
- TICKET-001: password reset for Chloe Harris (Finance) in ADUC
- Default Domain Policy: account lockout threshold 5, lockout duration 10 min, reset counter 10 min, minimum password length 12. Verified with Get-ADDefaultDomainPasswordPolicy
- TICKET-002: simulated 6 failed logins for charris, confirmed LockedOut = True, unlocked via ADUC Account tab, verified LockedOut = False
- TICKET-003: offboarded leaver Jack Hughes (Sales) with Remove-XoticLeaver.ps1: disabled, groups removed, moved to Disabled Users

Notes:

- Script doesn't set DisplayName; fix in a later session
- Password and lockout policies must be set at domain level (Default Domain Policy), not on an OU
- Disable leavers rather than deleting, to keep files, mailbox and audit trail
