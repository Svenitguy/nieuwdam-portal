# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Wachtwoord standaard voor alle lab accounts
$defaultPassword = "<YourPasswordHere>"

# Lijst van nieuwe gebruikers
$users = @(
    @{FirstName="<FirstName>"; LastName="<LastName>"; DisplayName="<DisplayName>"; JobTitle="<JobTitle>"; Department="<Department>"; UserName="<UserName@yourdomain.onmicrosoft.com>"; EmployeeId="1002"},
    # Voeg hier andere gebruikers toe zoals nodig
)

# Loop om gebruikers aan te maken
foreach ($user in $users) {

    # Maak een wachtwoordprofiel aan
    $PasswordProfile = @{
        ForceChangePasswordNextSignIn = $false
        Password = $defaultPassword
    }

    # Creëer de gebruiker
    New-MgUser `
        -AccountEnabled:$true `
        -DisplayName $user.DisplayName `
        -UserPrincipalName $user.UserName `
        -MailNickname ($user.UserName.Split("@")[0]) `
        -GivenName $user.FirstName `
        -Surname $user.LastName `
        -JobTitle $user.JobTitle `
        -Department $user.Department `
        -UsageLocation "BE" `
        -PasswordProfile $PasswordProfile `
        -EmployeeId $user.EmployeeId
}