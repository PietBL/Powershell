#Import Active Directory Module
Import-Module ActiveDirectory 

#Variables for Script
$_Name=Read-Host "Input sAMAccountname you wish to disable"
$_Date=Get-Date -Format "MM/dd/yyyy"
$_Creds=Get-Credential

# Disable the Account
if ((Get-ADUser $_Name).Enabled -eq $false) {
    Write-Host "$_Name is already disabled" -ForegroundColor Yellow
} else {
    Disable-ADAccount -Identity $_Name -Credential $_Creds
    Write-Host "Disabling $_Name" -ForegroundColor Green
}

# OU Variable for Disabled Users
$_TargetOU="OU=Disabled,DC=example,DC=com"
Move-ADObject -Identity $_Name -TargetPath $_TargetOU -Credential $_Creds
Write-Host "Moving $_Name to Disabled Users" -ForegroundColor Green

# Clear Dynamic Fields, keep personal details like Title and PhoneNumber
Set-ADUser $_Name -Description "Disabled on $_Date" -Office $null -Department $null -Credential $_Creds
Write-Host "Updated Description and cleared dynamic fields for $_Name" -ForegroundColor Green

# Remove all group memberships except specific group (adjusted to your custom group name)
$group = get-adgroup "Custom Group Name"
$groupSid = $group.sid
$groupSid
[int]$GroupID = $groupSid.Value.Substring($groupSid.Value.LastIndexOf("-")+1)
Get-ADUser $_Name | Set-ADObject -Replace @{primaryGroupID="$GroupID"} -Credential $_Creds

$groupsRemoved = Get-ADPrincipalGroupMembership -Identity $_Name | Where-Object {$_.Name -ne "Custom Group Name"}
Remove-ADPrincipalGroupMembership -Identity $_Name -MemberOf $groupsRemoved -Confirm:$false 
Write-Host "Removed from groups: $($groupsRemoved.Name)" -ForegroundColor Green

# Remote Exchange Session explanation:
# A remote Exchange session is a PowerShell session that connects to your Exchange server remotely,
# allowing you to run Exchange-specific commands (like modifying mailboxes) from your machine.

# Creating and Importing Exchange Session
$s = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri http://yourexchangeserver.yourdomain.local/powershell -Credential $_Creds -AllowRedirection
Write-Host "Created and imported remote Exchange session" -ForegroundColor Green

Import-PSSession $s -DisableNameChecking

# Hide User from the GAL
Set-Mailbox -Identity $_Name -HiddenFromAddressListsEnabled $true
Write-Host "Hiding $_Name from the GAL" -ForegroundColor Green

# Disable ActiveSync
Set-CASMailbox -Identity $_Name -ActiveSyncEnabled $false 
write-host "ActiveSync has been Disabled for $_Name" -ForegroundColor Green

# Lock the account to prevent new sessions
Set-ADUser -Identity $_Name -AccountLockoutTime (Get-Date)
Write-Host "Account for $_Name is now locked" -ForegroundColor Green

# Remove Remote Session
Remove-PSSession $s  
Write-Host "Closing Exchange Session" -ForegroundColor Green

# Logging actions
$logPath = "C:\Logs\OffboardingScript.log"
Add-Content -Path $logPath -Value "[$(Get-Date)] Disabled $_Name and moved to Disabled OU"

# Hard Stop to keep window open
Read-Host "Press any key to close!"
