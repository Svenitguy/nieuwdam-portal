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
#
# Version:
# 1.0.0
# ==================================================

# ==================================================
# Get-UserConfiguration
# ==================================================

function Get-UserConfiguration {

    param(
        [Parameter(Mandatory)]
        [string]$ConfigFolder
    )


    $Path =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "users.json"


    if(!(Test-Path $Path)) {

        Write-Logging `
            -Message "User configuration missing: $Path" `
            -Level ERROR `
            -Component "CONFIGURATION"

        throw "User configuration missing: $Path"

    }


    $Configuration =
        Get-Content `
            -Path $Path `
            -Raw `
            -Encoding UTF8 |
        ConvertFrom-Json


    Write-Logging `
        -Message (
            "User configuration loaded. Users: {0}" `
            -f `
            $Configuration.Count
        ) `
        -Level PASS `
        -Component "CONFIGURATION"


    return $Configuration

}


# ==================================================
# Get-GroupConfiguration
# ==================================================

function Get-GroupConfiguration {

    param(
        [Parameter(Mandatory)]
        [string]$ConfigFolder
    )


    $Path =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "groups.json"


    if(!(Test-Path $Path)) {

        Write-Logging `
            -Message "Group configuration missing: $Path" `
            -Level ERROR `
            -Component "CONFIGURATION"

        throw "Group configuration missing: $Path"

    }

    $Configuration =
        Get-Content `
            -Path $Path `
            -Raw `
            -Encoding UTF8 |
        ConvertFrom-Json


    Write-Logging `
        -Message (
            "Group configuration loaded. Groups: {0}" `
            -f `
            $Configuration.Count
        ) `
        -Level PASS `
        -Component "CONFIGURATION"


    return $Configuration

}


# ==================================================
# Get-MembershipConfiguration
#
# Loads group membership configuration
# and calculates total membership assignments.
# ==================================================

function Get-MembershipConfiguration {

    param(
        [Parameter(Mandatory)]
        [string]$ConfigFolder
    )


    $Path =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "group-memberships.json"


    if(!(Test-Path $Path)) {

        Write-Logging `
            -Message "Membership configuration missing: $Path" `
            -Level ERROR `
            -Component "CONFIGURATION"

        throw "Membership configuration missing: $Path"

    }

    $Configuration =
        Get-Content `
            -Path $Path `
            -Raw `
            -Encoding UTF8 |
        ConvertFrom-Json


    $TotalMemberships =
        (
            $Configuration |
            ForEach-Object {
                $_.Groups.Count
            } |
            Measure-Object -Sum
        ).Sum

    Write-Logging `
        -Message (
            "Membership configuration loaded. Users: {0}, Memberships: {1}" `
            -f `
            $Configuration.Count,
            $TotalMemberships
        ) `
        -Level "PASS" `
        -Component "CONFIGURATION"

    return $Configuration

}


# ==================================================
# Get-TenantConfiguration
# ==================================================

function Get-TenantConfiguration {

    param(
        [Parameter(Mandatory)]
        [string]$ConfigFolder
    )

    $Path =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "tenant.json"

    if(!(Test-Path $Path)) {

        Write-Logging `
            -Message "Tenant configuration missing: $Path" `
            -Level ERROR `
            -Component "CONFIGURATION"

        throw "Tenant configuration missing: $Path"

    }

    $Configuration =
        Get-Content `
            -Path $Path `
            -Raw `
            -Encoding UTF8 |
        ConvertFrom-Json

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

    param(

        [Parameter(Mandatory)]
        [string]
        $ConfigFolder

    )


    $Path =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "cleanup.json"


    if(!(Test-Path $Path)) {

        Write-Logging `
            -Message "Cleanup configuration missing: $Path" `
            -Level ERROR `
            -Component "CONFIGURATION"

        throw "Cleanup configuration missing: $Path"

    }


    $Configuration =
        Get-Content `
            -Path $Path `
            -Raw `
            -Encoding UTF8 |
        ConvertFrom-Json


    Write-Logging `
        -Message (
            "Cleanup configuration loaded. Users: {0}, Groups: {1}, Membership entries: {2}" `
            -f `
            $Configuration.Users.Count,
            $Configuration.Groups.Count,
            $Configuration.Memberships.Count
        ) `
        -Level PASS `
        -Component "CONFIGURATION"


    return $Configuration

}


function Get-SecurityConfiguration {

    param(
        [Parameter(Mandatory)]
        [string]$ConfigFolder
    )


    # ==================================================
    # Load security.json
    # ==================================================

    $SecurityPath =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "security.json"


    if(!(Test-Path $SecurityPath)) {

        Write-Message `
            -Status "ERROR" `
            -Message "Security configuration missing: $SecurityPath" `
            -Component "CONFIGURATION"

        throw "Security configuration missing: $SecurityPath"

    }


    $SecurityConfiguration =
        Get-Content `
            -Path $SecurityPath `
            -Raw `
            -Encoding UTF8 |
        ConvertFrom-Json



    # ==================================================
    # Load conditional-access.json
    # ==================================================

    $ConditionalAccessPath =
        Join-Path `
            -Path $ConfigFolder `
            -ChildPath "conditional-access.json"


    if(!(Test-Path $ConditionalAccessPath)) {

        Write-Message `
            -Status "WARNING" `
            -Message "Conditional Access configuration missing: $ConditionalAccessPath" `
            -Component "CONFIGURATION"


        $ConditionalAccessConfiguration = @{
            Policies = @()
        }

    }
    else {


        $ConditionalAccessConfiguration =
            Get-Content `
                -Path $ConditionalAccessPath `
                -Raw `
                -Encoding UTF8 |
            ConvertFrom-Json


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



    Write-Message `
        -Status "PASS" `
        -Message (
            "Security configuration loaded. Conditional Access policies: {0}" `
            -f `
            $ConditionalAccessConfiguration.Policies.Count
        ) `
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
)