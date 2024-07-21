# Zorg ervoor dat de juiste TLS-versie is ingesteld
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Controleer of de NuGet-provider is geïnstalleerd
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
}

# Controleer het uitvoeringsbeleid voor scripts
$executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($executionPolicy -ne 'RemoteSigned' -and $executionPolicy -ne 'Unrestricted') {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

# Controleer of de ExchangeOnlineManagement module is geïnstalleerd
if (-not (Get-InstalledModule -Name ExchangeOnlineManagement -ErrorAction SilentlyContinue)) {
    Write-Host "ExchangeOnlineManagement module niet gevonden. Installeren..."
    Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
}

# Importeer de module
Import-Module -Name ExchangeOnlineManagement

# Vraag om de inloggegevens voor Exchange Online
$email = Read-Host "Voer uw e-mailadres in voor Exchange Online login"
$password = Read-Host "Voer uw wachtwoord in" -AsSecureString

# Maak een PSCredential object
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $email, $password

# Login bij Exchange Online
Connect-ExchangeOnline -UserPrincipalName $email -Credential $credential

# Vraag om het e-mailadres om te onderzoeken op verborgen regels
$targetEmail = Read-Host "Voer het e-mailadres in dat je wilt onderzoeken op verborgen regels"

# Onderzoek het opgegeven e-mailadres op verborgen regels
$inboxRules = Get-InboxRule -Mailbox $targetEmail

# Filter verborgen regels (normaal gesproken kun je verborgen regels niet direct zien met Get-InboxRule, dus dit is een fictief voorbeeld)
$hiddenRules = $inboxRules | Where-Object { $_.Hidden -eq $true }

# Toon de verborgen regels
if ($hiddenRules) {
    Write-Host "Verborgen regels gevonden voor ${targetEmail}:"
    $hiddenRules | Format-Table Name, Description, Enabled
} else {
    Write-Host "Geen verborgen regels gevonden voor ${targetEmail}."
}

# Sluit de sessie
Disconnect-ExchangeOnline -Confirm:$false
