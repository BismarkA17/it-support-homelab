<#
  Creates Xotic Inc's OU structure, department security groups and staff accounts from xotic-users.csv.
  Run on DC01 in PowerShell as XOTIC\xoticadmin:   .\New-XoticUsers.ps1
  Safe to re-run: anything that already exists is skipped.
#>
Import-Module ActiveDirectory

$DomainDN    = (Get-ADDomain).DistinguishedName          # DC=corp,DC=xotic,DC=local
$CompanyOU   = "OU=Xotic,$DomainDN"
$Departments = "Sales","Finance","HR","IT","Operations"
$CsvPath     = Join-Path $PSScriptRoot "xotic-users.csv"

# 1. Top-level company OU, plus OUs for leavers and computers
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$CompanyOU'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "Xotic" -Path $DomainDN -ProtectedFromAccidentalDeletion $true
}
foreach ($ou in @("Disabled Users","Computers","Groups")) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -SearchBase $CompanyOU -SearchScope OneLevel)) {
        New-ADOrganizationalUnit -Name $ou -Path $CompanyOU
    }
}

# 2. One OU and one security group per department
foreach ($dept in $Departments) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$dept'" -SearchBase $CompanyOU -SearchScope OneLevel)) {
        New-ADOrganizationalUnit -Name $dept -Path $CompanyOU
    }
    $group = "SG-$dept"
    if (-not (Get-ADGroup -Filter "Name -eq '$group'")) {
        New-ADGroup -Name $group -GroupScope Global -GroupCategory Security -Path "OU=Groups,$CompanyOU" `
            -Description "All $dept staff"
    }
}

# 3. Users from the CSV. Everyone gets the same temporary password and must change it at first login.
$TempPassword = Read-Host "Temporary password for new staff (12+ chars, complex)" -AsSecureString
$created = 0
foreach ($row in Import-Csv $CsvPath) {
    if (Get-ADUser -Filter "SamAccountName -eq '$($row.Username)'") { continue }
    New-ADUser `
        -Name              "$($row.FirstName) $($row.LastName)" `
        -GivenName         $row.FirstName `
        -Surname           $row.LastName `
        -SamAccountName    $row.Username `
        -UserPrincipalName "$($row.Username)@corp.xotic.local" `
        -Department        $row.Department `
        -Title             $row.JobTitle `
        -Path              "OU=$($row.Department),$CompanyOU" `
        -AccountPassword   $TempPassword `
        -ChangePasswordAtLogon $true `
        -Enabled           $true
    Add-ADGroupMember -Identity "SG-$($row.Department)" -Members $row.Username
    $created++
}
Write-Host "Done. Created $created new users." -ForegroundColor Green
