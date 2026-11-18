<#
  Offboards a leaver: disables the account, records why, removes all group memberships
  and moves it to the Disabled Users OU.
  Usage on DC01:  .\Remove-XoticLeaver.ps1 -Username jsmith -Ticket TICKET-012
#>
param(
    [Parameter(Mandatory)] [string] $Username,
    [Parameter(Mandatory)] [string] $Ticket
)
Import-Module ActiveDirectory
$user = Get-ADUser -Identity $Username -Properties MemberOf
$disabledOU = "OU=Disabled Users,OU=Xotic,$((Get-ADDomain).DistinguishedName)"

Disable-ADAccount -Identity $user
Set-ADUser -Identity $user -Description "Leaver - disabled $(Get-Date -Format yyyy-MM-dd) - $Ticket"
foreach ($group in $user.MemberOf) { Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false }
Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU

Write-Host "$Username disabled, removed from $($user.MemberOf.Count) groups, moved to Disabled Users." -ForegroundColor Yellow
