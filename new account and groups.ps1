# Stap 1: Verbind met Azure AD
Connect-AzureAD

# Stap 2: Definieer de brongebruiker en de nieuwe gebruiker
$sourceUserUPN = "Pibilesta@Ms102company.onmicrosoft.com"
$newUserUPN = "testgroups5@itpb.nl"

# Haal de brongebruiker op
$sourceUser = Get-AzureADUser -ObjectId $sourceUserUPN
$sourceUserId = $sourceUser.ObjectId
Write-Host "Brongebruiker opgehaald: $($sourceUser.DisplayName), ID: $sourceUserId"

# Stap 3: Maak een nieuwe gebruiker aan
$passwordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$passwordProfile.Password = "Wachtwoord123!"

$newUser = New-AzureADUser -DisplayName "Testgroups5 Test" -UserPrincipalName $newUserUPN `
    -AccountEnabled $true -PasswordProfile $passwordProfile -MailNickname "testgroups5"
$newUserId = $newUser.ObjectId
Write-Host "Nieuwe gebruiker aangemaakt: $($newUser.DisplayName), ID: $newUserId"

# Stap 4: Haal de groepen op waarvan de brongebruiker lid is
$sourceUserGroups = Get-AzureADUserMembership -ObjectId $sourceUserId | Where-Object {
    $_.ObjectType -eq "Group"
}

# Log het aantal opgehaalde groepen
Write-Host "Aantal opgehaalde groepen: $($sourceUserGroups.Count)"
foreach ($group in $sourceUserGroups) {
    Write-Host "Groep gevonden: $($group.DisplayName)"
}

# Stap 5: Voeg de nieuwe gebruiker toe aan de niet-dynamische groepen van de brongebruiker
foreach ($group in $sourceUserGroups) {
    # Haal de details van de groep op
    $groupDetails = Get-AzureADGroup -ObjectId $group.ObjectId

    # Controleer of de groep dynamisch is
    if ($groupDetails.GroupTypes -notcontains "DynamicMembership" -and $group.DisplayName -ne "All Users") {
        try {
            Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $newUserId
            Write-Host "Nieuwe gebruiker toegevoegd aan groep: $($groupDetails.DisplayName)"
        } catch {
            Write-Host "Er is een fout opgetreden bij het toevoegen van de gebruiker aan groep: $($groupDetails.DisplayName)"
            Write-Host "Foutmelding: $_"
        }
    } else {
        Write-Host "Groep $($groupDetails.DisplayName) is dynamisch of speciaal en wordt overgeslagen."
    }
}
