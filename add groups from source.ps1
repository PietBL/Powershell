# Stap 1: Verbinding maken met Azure AD
Connect-AzureAD

# Stap 2: Vraag om invoer voor de voorbeeldgebruiker en de nieuwe medewerker
$exampleUserUPN = Read-Host "Voer de UPN in van de voorbeeldgebruiker (bijv. voorbeeld.gebruiker@jouwdomein.com)"
$newUserUPN = Read-Host "Voer de UPN in van de nieuwe medewerker (bijv. nieuwe.gebruiker@jouwdomein.com)"

# Stap 3: Haal de voorbeeldgebruiker op en zijn groepen
$exampleUserId = (Get-AzureADUser -ObjectId $exampleUserUPN).ObjectId
$exampleUserGroups = Get-AzureADUserMembership -ObjectId $exampleUserId

# Stap 4: Haal de nieuwe medewerker op
$newUserId = (Get-AzureADUser -ObjectId $newUserUPN).ObjectId

# Stap 5: Voeg de groepen van de voorbeeldgebruiker toe aan de nieuwe medewerker, maar sluit dynamische groepen uit
foreach ($group in $exampleUserGroups) {
    $groupDetails = Get-AzureADGroup -ObjectId $group.ObjectId
    if ($groupDetails.GroupTypes -notcontains "DynamicMembership") {
        # Alleen statische groepen toevoegen
        Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $newUserId
    } else {
        Write-Host "Dynamische groep overgeslagen: $($groupDetails.DisplayName)"
    }
}

Write-Host "De statische groepen van de voorbeeldgebruiker zijn succesvol toegevoegd aan de nieuwe medewerker."
