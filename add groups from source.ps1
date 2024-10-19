# Stap 1: Verbind met Azure AD
Connect-AzureAD

# Stap 2: Vraag invoer voor de brongebruiker (voorbeeldgebruiker) en de nieuwe medewerker
$sourceUserUPN = Read-Host "Voer de UPN in van de voorbeeldgebruiker (bijv. voorbeeld.gebruiker@domein.com)"
$newUserUPN = Read-Host "Voer de UPN in van de nieuwe medewerker (bijv. nieuwe.medewerker@domein.com)"

# Haal de brongebruiker op
$sourceUser = Get-AzureADUser -ObjectId $sourceUserUPN
$sourceUserId = $sourceUser.ObjectId
Write-Host "Brongebruiker opgehaald: $($sourceUser.DisplayName), ID: $sourceUserId"

# Haal de nieuwe gebruiker op
$newUser = Get-AzureADUser -ObjectId $newUserUPN
$newUserId = $newUser.ObjectId
Write-Host "Nieuwe gebruiker opgehaald: $($newUser.DisplayName), ID: $newUserId"

# Stap 3: Haal de groepen op waarvan de brongebruiker lid is
$sourceUserGroups = Get-AzureADUserMembership -ObjectId $sourceUserId | Where-Object {
    $_.ObjectType -eq "Group"
}

# Log het aantal opgehaalde groepen
Write-Host "Aantal opgehaalde groepen: $($sourceUserGroups.Count)"
foreach ($group in $sourceUserGroups) {
    Write-Host "Groep gevonden: $($group.DisplayName)"
}

# Stap 4: Voeg de nieuwe gebruiker toe aan de niet-dynamische groepen van de brongebruiker
foreach ($group in $sourceUserGroups) {
    # Haal de details van de groep op
    $groupDetails = Get-AzureADGroup -ObjectId $group.ObjectId

    # Controleer of de groep dynamisch is
    if ($groupDetails.GroupTypes -notcontains "DynamicMembership") {
        try {
            Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $newUserId
            Write-Host "Nieuwe gebruiker toegevoegd aan groep: $($groupDetails.DisplayName)"
        } catch {
            Write-Host "Er is een fout opgetreden bij het toevoegen van de gebruiker aan groep: $($groupDetails.DisplayName)"
            Write-Host "Foutmelding: $_"
        }
    } else {
        Write-Host "Groep $($groupDetails.DisplayName) is dynamisch en wordt overgeslagen."
    }
}
