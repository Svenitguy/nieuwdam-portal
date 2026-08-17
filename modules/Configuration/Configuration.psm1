# ==================================================
# Enterprise Configuration Module
#
# Purpose:
# Loads and validates provisioning configuration
# files from the configuration directory.
#
# Functions:
# - Get-UserConfiguration
# - Get-GroupConfiguration
# - Get-MembershipConfiguration
# - Get-TenantConfiguration
# - Get-CleanupConfiguration
# - Get-SecurityConfiguration
# - Get-PlatformConfig
#
# Version:
# 1.1.0
# ==================================================


# ==================================================
# Get-UserConfiguration
#
# Loads and normalizes user configuration.
#
# Supports:
# - Legacy flat JSON array
# - Metadata-based JSON structure
# ==================================================

function Get-UserConfiguration {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFolder
    )


    $UserFile =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "users.json"


    if (-not (Test-Path $UserFile)) {

        throw "users.json not found: $UserFile"

    }


    Write-Verbose "Loading users from: $UserFile"


    # --------------------------------------------------
    # Read JSON
    # --------------------------------------------------

    try {

        $RawJson =
            Get-Content `
                -Path $UserFile `
                -Raw `
                -Encoding UTF8

        $Json =
            $RawJson |
            ConvertFrom-Json

    }
    catch {

        throw "Failed to parse users.json: $($_.Exception.Message)"

    }


    # --------------------------------------------------
    # Normalize JSON structure
    # --------------------------------------------------

    # Format 1:
    #
    # [
    #   { user },
    #   { user },
    #   { user }
    # ]

    if ($Json -is [System.Array]) {

        $Users = @($Json)

    }


    # Format 2:
    #
    # {
    #   "Metadata": {...},
    #   "Users": [
    #       { user },
    #       { user }
    #   ]
    # }

    elseif ($null -ne $Json.PSObject.Properties["Users"]) {

        $Users = @($Json.Users)

    }

    else {

        throw @"
Unsupported users.json structure.

Expected either:

1. A JSON array:
[
    { ... }
]

or:

2. A JSON object containing a Users array:
{
    "Metadata": { ... },
    "Users": [
        { ... }
    ]
}

File:
$UserFile
"@

    }


    # --------------------------------------------------
    # Make absolutely sure we have an array
    # --------------------------------------------------

    $Users = @($Users)


    # --------------------------------------------------
    # Validate count
    # --------------------------------------------------

    if ($Users.Count -eq 0) {

        throw "users.json contains no users: $UserFile"

    }


    # --------------------------------------------------
    # Validate individual users
    # --------------------------------------------------

    $RequiredProperties = @(
        "FirstName",
        "LastName",
        "DisplayName",
        "JobTitle",
        "Department",
        "UserName",
        "EmployeeId",
        "AccountType"
    )


    $Index = 0


    foreach ($User in $Users) {

        $Index++


        if ($null -eq $User) {

            throw "User record #$Index is null."

        }


        foreach ($Property in $RequiredProperties) {

            $PropertyObject =
                $User.PSObject.Properties[$Property]


            if ($null -eq $PropertyObject) {

                throw `
                    "User record #$Index is missing required property '$Property'."

            }


            if (
                $null -eq $PropertyObject.Value -or
                [string]::IsNullOrWhiteSpace(
                    [string]$PropertyObject.Value
                )
            ) {

                throw `
                    "User record #$Index has an empty required property '$Property'."

            }

        }

    }


    Write-Logging `
        -Message (
            "User configuration loaded. Users: {0}" `
            -f `
            $Users.Count
        ) `
        -Level PASS `
        -Component "CONFIGURATION"


    return @($Users)

}


# ==================================================
# Get-GroupConfiguration
#
# Loads and normalizes group configuration.
#
# Supports:
# - Legacy flat JSON array
# - Metadata-based JSON structure
# ==================================================

function Get-GroupConfiguration {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFolder
    )


    $GroupFile =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "groups.json"


    if (-not (Test-Path $GroupFile)) {

        throw "groups.json not found: $GroupFile"

    }


    Write-Verbose "Loading groups from: $GroupFile"


    # --------------------------------------------------
    # Read JSON
    # --------------------------------------------------

    try {

        $RawJson =
            Get-Content `
                -Path $GroupFile `
                -Raw `
                -Encoding UTF8

        $Json =
            $RawJson |
            ConvertFrom-Json

    }
    catch {

        throw "Failed to parse groups.json: $($_.Exception.Message)"

    }


    # --------------------------------------------------
    # Normalize JSON structure
    # --------------------------------------------------

    # Format 1:
    #
    # [
    #   { group },
    #   { group },
    #   { group }
    # ]

    if ($Json -is [System.Array]) {

        $Groups = @($Json)

    }


    # Format 2:
    #
    # {
    #   "Metadata": {...},
    #   "Groups": [
    #       { group },
    #       { group }
    #   ]
    # }

    elseif ($null -ne $Json.PSObject.Properties["Groups"]) {

        $Groups = @($Json.Groups)

    }

    else {

        throw @"
Unsupported groups.json structure.

Expected either:

1. A JSON array:
[
    { ... }
]

or:

2. A JSON object containing a Groups array:
{
    "Metadata": { ... },
    "Groups": [
        { ... }
    ]
}

File:
$GroupFile
"@

    }


    $Groups = @($Groups)


    if ($Groups.Count -eq 0) {

        throw "groups.json contains no groups: $GroupFile"

    }


    # --------------------------------------------------
    # Normalize group properties
    # --------------------------------------------------

    $NormalizedGroups = foreach ($Group in $Groups) {

        if ($null -eq $Group) {

            throw "A group record is null."

        }


        # --------------------------------------------------
        # New JSON format
        #
        # {
        #   Name
        #   Category
        #   Purpose
        #   RiskLevel
        #   ManagedBy
        # }
        # --------------------------------------------------

        if (
            $null -ne
            $Group.PSObject.Properties["Name"]
        ) {

            $MailNickname =
                (
                    [string]$Group.Name
                ).ToLower() `
                -replace '[^a-z0-9_]', '_'


            [PSCustomObject]@{

                DisplayName =
                    [string]$Group.Name

                Description =
                    [string]$Group.Purpose

                MailNickname =
                    $MailNickname

                GroupType =
                    "Security"

                SecurityEnabled =
                    $true

                MailEnabled =
                    $false

                Department =
                    [string]$Group.Category

                DynamicMembership =
                    $false

                Owners =
                    @()

            }

        }


        # --------------------------------------------------
        # Legacy JSON format
        #
        # {
        #   DisplayName
        #   Description
        #   MailNickname
        #   GroupType
        #   ...
        # }
        # --------------------------------------------------

        elseif (
            $null -ne
            $Group.PSObject.Properties["DisplayName"]
        ) {

            [PSCustomObject]@{

                DisplayName =
                    $Group.DisplayName

                Description =
                    $Group.Description

                MailNickname =
                    $Group.MailNickname

                GroupType =
                    $Group.GroupType

                SecurityEnabled =
                    $Group.SecurityEnabled

                MailEnabled =
                    $Group.MailEnabled

                Department =
                    $Group.Department

                DynamicMembership =
                    $Group.DynamicMembership

                Owners =
                    @($Group.Owners)

            }

        }

        else {

            throw @"
Unsupported group record structure.

A group must contain either:

- Name

or:

- DisplayName

File:
$GroupFile
"@

        }

    }


    Write-Logging `
        -Message (
            "Group configuration loaded. Groups: {0}" `
            -f `
            $NormalizedGroups.Count
        ) `
        -Level PASS `
        -Component "CONFIGURATION"


    return @($NormalizedGroups)

}


# ==================================================
# Get-MembershipConfiguration
#
# Supports:
# - Legacy flat array with Groups[]
# - New Metadata + Memberships[] structure
# - New flat Memberships[] structure
#
# Normalizes everything to:
#
# UserName
# Groups[]
# ==================================================

function Get-MembershipConfiguration {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFolder
    )

    $Path = Join-Path `
        -Path $ConfigFolder `
        -ChildPath "group-memberships.json"

    if (-not (Test-Path $Path)) {

        throw "Membership configuration missing: $Path"

    }

    Write-Verbose "Loading memberships from: $Path"

    try {

        $RawJson =
            Get-Content `
                -Path $Path `
                -Raw `
                -Encoding UTF8

        $Json =
            $RawJson |
            ConvertFrom-Json

    }
    catch {

        throw "Failed to parse group-memberships.json: $($_.Exception.Message)"

    }


    # ==================================================
    # Detect format
    # ==================================================

    $Entries = @()


    # --------------------------------------------------
    # Format 1
    #
    # [
    #   {
    #       UserName: "...",
    #       Groups: [...]
    #   }
    # ]
    # --------------------------------------------------

    if ($Json -is [System.Array]) {

        $Entries = @($Json)

    }


    # --------------------------------------------------
    # Format 2
    #
    # {
    #   "Metadata": {...},
    #   "Memberships": [...]
    # }
    # --------------------------------------------------

    elseif (
        $null -ne
        $Json.PSObject.Properties["Memberships"]
    ) {

        $Entries = @($Json.Memberships)

    }

    else {

        throw @"
Unsupported group-memberships.json structure.

Supported formats:

1. Legacy:

[
    {
        "UserName": "user@tenant.com",
        "Groups": [
            "GroupA",
            "GroupB"
        ]
    }
]

2. Current:

{
    "Metadata": {...},
    "Memberships": [
        {
            "UserName": "user@tenant.com",
            "GroupName": "GroupA",
            "Source": "Department",
            "Reason": "..."
        }
    ]
}

File:
$Path
"@

    }


    # ==================================================
    # Normalize
    # ==================================================

    $Normalized = [System.Collections.ArrayList]::new()


    foreach ($Entry in $Entries) {

        if ($null -eq $Entry) {
            continue
        }


        if (
            [string]::IsNullOrWhiteSpace(
                [string]$Entry.UserName
            )
        ) {

            throw "Membership entry is missing UserName."

        }


        # --------------------------------------------------
        # Legacy format
        # --------------------------------------------------

        if (
            $null -ne
            $Entry.PSObject.Properties["Groups"]
        ) {

            foreach ($GroupName in @($Entry.Groups)) {

                if (
                    [string]::IsNullOrWhiteSpace(
                        [string]$GroupName
                    )
                ) {
                    continue
                }

                [void]$Normalized.Add(
                    [PSCustomObject]@{

                        UserName = $Entry.UserName

                        GroupName = [string]$GroupName

                        Source =
                            if ($Entry.PSObject.Properties["Source"]) {
                                $Entry.Source
                            }
                            else {
                                "Legacy"
                            }

                        Reason =
                            if ($Entry.PSObject.Properties["Reason"]) {
                                $Entry.Reason
                            }
                            else {
                                "Legacy membership configuration"
                            }

                    }
                )

            }

            continue

        }


        # --------------------------------------------------
        # New format
        # --------------------------------------------------

        if (
            $null -ne
            $Entry.PSObject.Properties["GroupName"]
        ) {

            if (
                [string]::IsNullOrWhiteSpace(
                    [string]$Entry.GroupName
                )
            ) {

                continue

            }


            [void]$Normalized.Add(
                [PSCustomObject]@{

                    UserName = [string]$Entry.UserName

                    GroupName = [string]$Entry.GroupName

                    Source =
                        if ($Entry.PSObject.Properties["Source"]) {
                            $Entry.Source
                        }
                        else {
                            "Unknown"
                        }

                    Reason =
                        if ($Entry.PSObject.Properties["Reason"]) {
                            $Entry.Reason
                        }
                        else {
                            ""
                        }

                }
            )

            continue

        }


        throw `
            "Unsupported membership entry for user '$($Entry.UserName)'. Expected Groups or GroupName."

    }


    Write-Logging `
        -Message (
            "Membership configuration loaded. Memberships: {0}" `
            -f `
            $Normalized.Count
        ) `
        -Level "PASS" `
        -Component "CONFIGURATION"


    return @($Normalized)

}

# ==================================================
# Get-TenantConfiguration
# ==================================================

function Get-TenantConfiguration {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFolder
    )


    $Path =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "tenant.json"


    if (-not (Test-Path $Path)) {

        Write-Logging `
            -Message "Tenant configuration missing: $Path" `
            -Level ERROR `
            -Component "CONFIGURATION"

        throw "Tenant configuration missing: $Path"

    }


    try {

        $Configuration =
            Get-Content `
                -Path $Path `
                -Raw `
                -Encoding UTF8 |
            ConvertFrom-Json

    }
    catch {

        throw `
            "Failed to parse tenant.json: $($_.Exception.Message)"

    }


    Write-Logging `
        -Message (
            "Tenant configuration loaded. Tenant: {0}" `
            -f `
            $Configuration.TenantName
        ) `
        -Level PASS `
        -Component "CONFIGURATION"


    return $Configuration

}


# ==================================================
# Get-CleanupConfiguration
#
# Loads cleanup configuration
# for deprovisioning operations.
# ==================================================

function Get-CleanupConfiguration {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFolder
    )


    $Path =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "cleanup.json"


    if (-not (Test-Path $Path)) {

        Write-Logging `
            -Message "Cleanup configuration missing: $Path" `
            -Level ERROR `
            -Component "CONFIGURATION"

        throw "Cleanup configuration missing: $Path"

    }


    try {

        $Configuration =
            Get-Content `
                -Path $Path `
                -Raw `
                -Encoding UTF8 |
            ConvertFrom-Json

    }
    catch {

        throw `
            "Failed to parse cleanup.json: $($_.Exception.Message)"

    }


    Write-Logging `
        -Message (
            "Cleanup configuration loaded. Users: {0}, Groups: {1}, Membership entries: {2}" `
            -f `
            @($Configuration.Users).Count,
            @($Configuration.Groups).Count,
            @($Configuration.Memberships).Count
        ) `
        -Level PASS `
        -Component "CONFIGURATION"


    return $Configuration

}


# ==================================================
# Get-SecurityConfiguration
# ==================================================

function Get-SecurityConfiguration {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFolder
    )


    # ==================================================
    # Load security.json
    # ==================================================

    $SecurityPath =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "security.json"


    if (-not (Test-Path $SecurityPath)) {

        Write-Message `
            -Status "ERROR" `
            -Message "Security configuration missing: $SecurityPath" `
            -Component "CONFIGURATION"

        throw "Security configuration missing: $SecurityPath"

    }


    try {

        $SecurityConfiguration =
            Get-Content `
                -Path $SecurityPath `
                -Raw `
                -Encoding UTF8 |
            ConvertFrom-Json

    }
    catch {

        throw `
            "Failed to parse security.json: $($_.Exception.Message)"

    }


    # ==================================================
    # Load conditional-access.json
    # ==================================================

    $ConditionalAccessPath =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "conditional-access.json"


    if (-not (Test-Path $ConditionalAccessPath)) {

        Write-Message `
            -Status "WARNING" `
            -Message "Conditional Access configuration missing: $ConditionalAccessPath" `
            -Component "CONFIGURATION"


        $ConditionalAccessConfiguration = [PSCustomObject]@{
            Policies = @()
        }

    }
    else {

        try {

            $ConditionalAccessConfiguration =
                Get-Content `
                    -Path $ConditionalAccessPath `
                    -Raw `
                    -Encoding UTF8 |
                ConvertFrom-Json

        }
        catch {

            throw `
                "Failed to parse conditional-access.json: $($_.Exception.Message)"

        }

    }


    # ==================================================
    # Combine configuration
    # ==================================================

    $Configuration = @{

        PasswordPolicy =
            $SecurityConfiguration.PasswordPolicy

        AuthenticationMethods =
            $SecurityConfiguration.AuthenticationMethods

        MFA =
            $SecurityConfiguration.MFA

        ConditionalAccess =
            $ConditionalAccessConfiguration

        SecurityDefaults =
            $SecurityConfiguration.SecurityDefaults

        BreakGlassAccounts =
            $SecurityConfiguration.BreakGlassAccounts

    }


    return [PSCustomObject]$Configuration

}


# ==================================================
# Get-PlatformConfig
#
# Loads central platform configuration
# from platform.config.psd1.
# ==================================================

function Get-PlatformConfig {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFolder
    )


    $Path =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "platform.config.psd1"


    if (-not (Test-Path $Path)) {

        Write-Logging `
            -Message "Platform configuration missing: $Path" `
            -Level ERROR `
            -Component "CONFIGURATION"

        throw "Platform configuration missing: $Path"

    }


    $Configuration =
        Import-PowerShellDataFile `
            -Path $Path


    if (
        [string]::IsNullOrWhiteSpace(
            $Configuration.FrameworkName
        )
    ) {

        throw "FrameworkName is missing from platform.config.psd1"

    }


    if (
        [string]::IsNullOrWhiteSpace(
            $Configuration.FrameworkVersion
        )
    ) {

        throw "FrameworkVersion is missing from platform.config.psd1"

    }


    Write-Logging `
        -Message (
            "Platform configuration loaded. Framework: {0}, Version: {1}" `
            -f `
            $Configuration.FrameworkName,
            $Configuration.FrameworkVersion
        ) `
        -Level PASS `
        -Component "CONFIGURATION"


    return [PSCustomObject]$Configuration

}


# ==================================================
# Export
# ==================================================

Export-ModuleMember -Function @(
    "Get-UserConfiguration"
    "Get-GroupConfiguration"
    "Get-MembershipConfiguration"
    "Get-TenantConfiguration"
    "Get-CleanupConfiguration"
    "Get-SecurityConfiguration"
    "Get-PlatformConfig"
)