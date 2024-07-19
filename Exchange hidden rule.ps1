Install-Module -Name ExchangeOnlineManagement

# Import the Exchange Online Management module
Import-Module ExchangeOnlineManagement

# Prompt for Office 365 credentials
$UserCredential = Get-Credential

# Connect to Exchange Online
Connect-ExchangeOnline -Credential $UserCredential

# Function to check for hidden rules in a mailbox
function Get-HiddenRules {
    param (
        [string]$Mailbox
    )
    
    # Get all inbox rules for the specified mailbox
    $rules = Get-InboxRule -Mailbox $Mailbox
    
    # Check for hidden rules
    foreach ($rule in $rules) {
        if ($rule.IsHidden) {
            Write-Output "Hidden rule found in mailbox $Mailbox: $($rule.Name)"
        }
    }
}

# List of mailboxes to check (can be modified to get from a file or other source)
$mailboxes = Get-Mailbox -ResultSize Unlimited

# Iterate through each mailbox and check for hidden rules
foreach ($mailbox in $mailboxes) {
    Get-HiddenRules -Mailbox $mailbox.UserPrincipalName
}

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
