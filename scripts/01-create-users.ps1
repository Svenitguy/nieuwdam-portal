# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Vraag tijdelijk wachtwoord veilig op (wordt gebruikt voor alle nieuwe users)
$securePassword = Read-Host "Enter temporary password for new users" -AsSecureString
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
)

# Lijst van gebruikers wordt ingelezen vanuit JSON (bijv. ../config/users.json)
$users = Get-Content "../config/users.json" | ConvertFrom-Json

foreach ($user in $users) {

    # Check of de gebruiker al bestaat
    $existingUser = Get-MgUser -Filter "userPrincipalName eq '$($user.UserName)'" -ErrorAction SilentlyContinue

    if ($existingUser) {
        Write-Host "User $($user.UserName) already exists. Skipping..."
    } else {
        Write-Host "Creating user $($user.UserName)..."

        # Maak wachtwoordprofiel aan
        $PasswordProfile = @{
            ForceChangePasswordNextSignIn = $false
            Password = $plainPassword
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
}