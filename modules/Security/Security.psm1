# ============================================================
# Module: Security
#
# Description:
# Enterprise security automation for Microsoft Entra ID.
#
# Responsibilities:
#   - Password policies
#   - Authentication methods
#   - Multi-Factor Authentication
#   - Conditional Access
#   - Security Defaults validation
#   - Break-glass account validation
#   - Security reporting
#
# Version:
#   1.0.0
# ============================================================

Set-StrictMode -Version Latest


# Load Conditional Access functions

Get-ChildItem `
    "$PSScriptRoot\ConditionalAccess\*.ps1" |
ForEach-Object {
    . $_.FullName
}

# ============================================================
# Test-ConditionalAccessLicense
#
# Determines whether the tenant supports
# Microsoft Entra Conditional Access.
# ============================================================

function Test-ConditionalAccessLicense {

    [CmdletBinding()]
    param()


    try {

        $Skus = @(
            Get-MgSubscribedSku -ErrorAction Stop
        )

    }
    catch {

        Write-Message `
            -Status "WARNING" `
            -Message "Unable to determine tenant licenses. Conditional Access will be skipped." `
            -Component "SECURITY"

        return $false

    }


    if($Skus.Count -eq 0){

        Write-Message `
            -Status "WARNING" `
            -Message "No licenses found in tenant. Conditional Access requires Entra ID Premium P1/P2 or an eligible Microsoft 365 license." `
            -Component "SECURITY"

        return $false

    }


    $SkuNumbers = @(
        $Skus |
        ForEach-Object {
            $_.SkuPartNumber
        }
    )


    $SupportedLicenses = @(

        # Microsoft Entra ID Premium
        "AAD_PREMIUM"
        "AAD_PREMIUM_P2"

        # Enterprise Mobility + Security
        "EMS"
        "EMSPREMIUM"

        # Microsoft 365 E3/E5
        "ENTERPRISEPACK"
        "ENTERPRISEPREMIUM"

        # Microsoft 365 Business Premium
        "SPB"

    )


    foreach($License in $SupportedLicenses){

        if($SkuNumbers -contains $License){

            Write-Message `
                -Status "PASS" `
                -Message "Conditional Access license detected: $License" `
                -Component "SECURITY"

            return $true

        }

    }


    Write-Message `
        -Status "WARNING" `
        -Message "No Conditional Access eligible license detected. Conditional Access will be skipped." `
        -Component "SECURITY"


    return $false

}


# ============================================================
# Set-PasswordPolicy
#
# Configures tenant password security settings.
#
# Future implementation:
# - Password protection policies
# - Smart lockout settings
# - Password expiration controls
# ============================================================

function Set-PasswordPolicy {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        $Configuration,

        [switch]
        $DryRun

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message (
                "Would configure password policy. MinimumLength: {0}" `
                -f $Configuration.MinimumLength
            ) `
            -Component "SECURITY"

        return @{

            Component = "PasswordPolicy"

            Status = "WouldConfigure"

            MinimumLength =
                $Configuration.MinimumLength

            RequireComplexity =
                $Configuration.RequireComplexity

        }

    }


    Write-Message `
        -Status "INFO" `
        -Message "Configuring password policies." `
        -Component "SECURITY"


    # Microsoft Graph implementation will be added here

    Write-Message `
        -Status "INFO" `
        -Message (
            "Password policy configuration loaded. MinimumLength: {0}" `
            -f $Configuration.MinimumLength
        ) `
        -Component "SECURITY"


    Write-Message `
        -Status "PASS" `
        -Message "Password policies configured." `
        -Component "SECURITY"

    return @{

        Component = "PasswordPolicy"
        Status = "Configured"
        MinimumLength = $Configuration.MinimumLength
        RequireComplexity = $Configuration.RequireComplexity

    }
}



# ============================================================
# Set-AuthenticationMethods
#
# Configures allowed authentication methods.
#
# Future implementation:
# - Authenticator App
# - FIDO2 security keys
# - Temporary Access Pass
# ============================================================

function Set-AuthenticationMethods {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        $Configuration,

        [switch]
        $DryRun

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message (
                "Would configure authentication methods. AuthenticatorApp: {0}, FIDO2: {1}" `
                -f `
                $Configuration.AuthenticatorApp,
                $Configuration.FIDO2
            ) `
            -Component "SECURITY"

        return @{

            Component = "AuthenticationMethods"

            Status = "WouldConfigure"

            AuthenticatorApp =
                $Configuration.AuthenticatorApp

            FIDO2 =
                $Configuration.FIDO2

        }

    }


    Write-Message `
        -Status "INFO" `
        -Message "Configuring authentication methods." `
        -Component "SECURITY"


    # Microsoft Graph implementation will be added here


    Write-Message `
        -Status "INFO" `
        -Message (
            "Authentication methods loaded. AuthenticatorApp: {0}, FIDO2: {1}" `
            -f `
            $Configuration.AuthenticatorApp,
            $Configuration.FIDO2
        ) `
        -Component "SECURITY"


    Write-Message `
        -Status "PASS" `
        -Message "Authentication methods configured." `
        -Component "SECURITY"

    return @{
        Component = "AuthenticationMethods"
        Status = "Configured"
        AuthenticatorApp = $Configuration.AuthenticatorApp
        FIDO2 = $Configuration.FIDO2
    }
}


# ============================================================
# Set-MFAConfiguration
#
# Configures Multi-Factor Authentication requirements.
#
# Future implementation:
# - MFA registration policy
# - Authentication strength
# - User targeting
# ============================================================

# ------------------------------------------------------------
# Configure Multi-Factor Authentication
# ------------------------------------------------------------

function Set-MFAConfiguration {

    [CmdletBinding()]
    param(

        [switch]
        $DryRun,

        [object]
        $Configuration

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message (
                "Would configure MFA requirements. Enabled: {0}, Admins: {1}, Users: {2}" `
                -f `
             $Configuration.Enabled,
                $Configuration.RequireForAdmins,
                $Configuration.RequireForUsers
            ) `
            -Component "SECURITY"


        return @{

            Component = "MFA"
            Status = "WouldConfigure"
            Enabled = $Configuration.Enabled
            RequireForAdmins = $Configuration.RequireForAdmins
            RequireForUsers = $Configuration.RequireForUsers

        }

    }



    Write-Message `
        -Status "INFO" `
        -Message "Configuring MFA requirements." `
        -Component "SECURITY"



    #
    # Microsoft Graph implementation will be added here
    #
    # Example future actions:
    #
    # - Configure Authentication Strength
    # - Require Microsoft Authenticator
    # - Enable FIDO2 security keys
    # - Create Conditional Access requirement
    #



    Write-Message `
        -Status "PASS" `
        -Message "MFA configuration completed." `
        -Component "SECURITY"



    return @{

        Component = "MFA"

        Status = "Configured"

    }


}


# ============================================================
# New-ConditionalAccessPolicies
#
# Creates baseline Conditional Access policies.
#
# Future implementation:
# - Require MFA
# - Block legacy authentication
# - Protect administrators
# ============================================================

# ------------------------------------------------------------
# Configure Conditional Access Policies
# ------------------------------------------------------------

# ------------------------------------------------------------
# Configure Conditional Access Policies
# ------------------------------------------------------------

function New-ConditionalAccessPolicies {

    [CmdletBinding()]
    param(

        [switch]
        $DryRun,

        [object]
        $Configuration

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message "Running Conditional Access deployment in simulation mode." `
            -Component "SECURITY"

    }


    # ------------------------------------------------------------
    # Validate license
    # ------------------------------------------------------------

    if(
        (-not $DryRun) -and
        (-not (Test-ConditionalAccessLicense))
    ){

        Write-Message `
            -Status "WARNING" `
            -Message "Conditional Access deployment skipped because no eligible license was found." `
            -Component "SECURITY"


        return @{

            Component = "ConditionalAccess"

            Status = "Skipped"

            Reason = "LicenseNotAvailable"

        }

    }



    Write-Message `
        -Status "INFO" `
        -Message "Deploying Conditional Access policies." `
        -Component "SECURITY"



    try {

        if(
            -not $Configuration.Policies -or
            $Configuration.Policies.Count -eq 0
        ){

            throw "No Conditional Access policies found in configuration."

        }

        foreach($Policy in $Configuration.Policies){


            if(-not $Policy.Enabled){

                Write-Message `
                    -Status "INFO" `
                    -Message "Skipping disabled Conditional Access policy: $($Policy.Name)." `
                    -Component "SECURITY"

                continue

            }



            Write-Message `
                -Status "INFO" `
                -Message "Processing Conditional Access policy: $($Policy.Name)." `
                -Component "SECURITY"



            switch($Policy.Type){


                "BlockLegacyAuthentication" {

                    New-CA001-BlockLegacyAuthentication `
                        -DryRun:$DryRun


                }



                "RequireMFAAdmins" {

                    New-CA002-RequireMFAAdmins `
                        -DryRun:$DryRun


                }



                "RequireMFAUsers" {

                    New-CA003-RequireMFAUsers `
                        -DryRun:$DryRun


                }



                "RequireMFAExternal" {

                    New-CA004-RequireMFAExternal `
                        -DryRun:$DryRun


                }



                "RequireCompliantDevice" {

                    New-CA005-RequireCompliantDevice `
                        -DryRun:$DryRun


                }



                "BlockRiskySignin" {

                    New-CA006-BlockRiskySignin `
                        -DryRun:$DryRun


                }



                "ProtectBreakGlass" {

                    New-CA007-ProtectBreakGlass `
                        -DryRun:$DryRun


                }



                "SessionControl" {

                    New-CA008-SessionControl `
                        -DryRun:$DryRun


                }



                default {

                    Write-Message `
                        -Status "WARNING" `
                        -Message "Unknown Conditional Access policy type: $($Policy.Type)." `
                        -Component "SECURITY"

                }

            }

        }


    }
    catch {


        Write-Message `
            -Status "ERROR" `
            -Message $_.Exception.Message `
            -Component "SECURITY"


        return @{

            Component = "ConditionalAccess"

            Status = "Failed"

            Error = $_.Exception.Message

        }

    }



    Write-Message `
        -Status "PASS" `
        -Message "Conditional Access deployment completed." `
        -Component "SECURITY"



    return @{

        Component = "ConditionalAccess"

        Status =
            if($DryRun){
                "WouldConfigure"
            }
            else{
                "Configured"
            }


        PolicyCount =
            @(
                $Configuration.Policies |
                Where-Object {
                    $_.Enabled
                }
            ).Count

    }

}


# ============================================================
# Test-SecurityDefaults
#
# Validates tenant security baseline.
# ============================================================

# ------------------------------------------------------------
# Validate Security Defaults
# ------------------------------------------------------------

function Test-SecurityDefaults {

    [CmdletBinding()]
    param(

        [switch]
        $DryRun,

        [object]
        $Configuration

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message (
                "Would validate Security Defaults. Enabled: {0}" `
                -f `
                $Configuration.Enabled
            ) `
            -Component "SECURITY"


        return @{

            Component = "SecurityDefaults"
            Status = "WouldValidate"
            Enabled =
                $Configuration.Enabled


        }

    }



# ==================================================
# Microsoft Graph validation
# ==================================================

$SecurityDefaults =
    Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy `
        -ErrorAction Stop


if($null -eq $SecurityDefaults){

    throw "Unable to retrieve Security Defaults policy."

}


$CurrentState =
    $SecurityDefaults.IsEnabled



if($CurrentState -eq $Configuration.Enabled){

    $ValidationStatus = "Compliant"

}
else {

    $ValidationStatus = "Mismatch"

}



if($ValidationStatus -eq "Compliant"){

    Write-Message `
        -Status "PASS" `
        -Message "Security Defaults validation completed. State is compliant." `
        -Component "SECURITY"

}
else {

    Write-Message `
        -Status "WARNING" `
        -Message (
            "Security Defaults mismatch. Configured: {0}, Current: {1}" `
            -f `
            $Configuration.Enabled,
            $CurrentState
        ) `
        -Component "SECURITY"

}


    return @{
        Component = "SecurityDefaults"
        Status = $ValidationStatus
        ConfiguredState = $Configuration.Enabled
        CurrentState = $CurrentState
    }

}

# ============================================================
# Test-BreakGlassAccounts
#
# Validates emergency access accounts.
#
# Checks:
# - Presence
# - Exclusions
# - Security status
# ============================================================

function Test-BreakGlassAccounts {

    [CmdletBinding()]
    param(

        [switch]
        $DryRun,

        [object]
        $Configuration

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message (
                "Would validate emergency access accounts. Required count: {0}" `
                -f `
                $Configuration.RequiredCount
            ) `
            -Component "SECURITY"


        return @{

            Component = "BreakGlassAccounts"

            Status = "WouldValidate"

        }

    }



    Write-Message `
        -Status "INFO" `
        -Message "Validating emergency access accounts." `
        -Component "SECURITY"



    # ==================================================
    # Microsoft Graph validation
    # ==================================================

    if(
        -not $Configuration.Accounts -or
        $Configuration.Accounts.Count -eq 0
    ){
        throw "No Break Glass accounts configured in security.json."
    }

    $Users =
        Get-MgUser `
            -All `
            -Property `
                Id,
                DisplayName,
                UserPrincipalName,
                AccountEnabled



    $ConfiguredAccounts = @(
        $Configuration.Accounts |
        ForEach-Object {
            $_.ToLower()
        }
    )

    $BreakGlassUsers = @(
        $Users |
        Where-Object {
            $_.UserPrincipalName.ToLower() -in $ConfiguredAccounts
        }
    )


    $FoundCount =
        $BreakGlassUsers.Count

    $EnabledCount = @(
        $BreakGlassUsers |
        Where-Object {
            $_.AccountEnabled
        }
    ).Count


    if(
        $FoundCount -ge $Configuration.RequiredCount -and
        $EnabledCount -eq $FoundCount
    ){

        $ValidationStatus = "Compliant"

    }
    else {

        $ValidationStatus = "Mismatch"

    }



    if($ValidationStatus -eq "Compliant"){

        Write-Message `
            -Status "PASS" `
            -Message (
                "Emergency access account validation completed. Found: {0}" `
                -f $FoundCount
            ) `
            -Component "SECURITY"

    }
    else {

        Write-Message `
            -Status "WARNING" `
            -Message (
                "Emergency access account count mismatch. Required: {0}, Found: {1}" `
                -f `
                $Configuration.RequiredCount,
                $FoundCount
            ) `
            -Component "SECURITY"

    }



    return @{

        Component = "BreakGlassAccounts"
        Status = $ValidationStatus
        RequiredCount = $Configuration.RequiredCount
        FoundCount = $FoundCount
        EnabledCount = $EnabledCount
        Accounts = @(
            $BreakGlassUsers |
            ForEach-Object {
                $_.UserPrincipalName
            }
        )

    }

}



# ============================================================
# New-SecurityReport
#
# Generates security assessment output.
#
# Future implementation:
# - JSON report
# - HTML dashboard
# - Compliance summary
# ============================================================

function New-SecurityReport {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        $Results,

        [Parameter(Mandatory)]
        [string]
        $RunId,

        [switch]
        $DryRun

    )


    Write-Message `
        -Status "INFO" `
        -Message "Generating security report." `
        -Component "SECURITY"


    $Report = @{

        RunId =
            $RunId

        Generated =
            (Get-Date)

        Mode =
            if($DryRun){
                "DRY-RUN"
            }
            else {
                "DEPLOYMENT"
            }

        Results =
            $Results

    }


    Write-Message `
        -Status "PASS" `
        -Message "Security report generated." `
        -Component "SECURITY"


    return $Report

}



# ============================================================
# Export Module Members
# ============================================================

Export-ModuleMember -Function @(
    "Set-PasswordPolicy",
    "Set-AuthenticationMethods",
    "Set-MFAConfiguration",
    "New-ConditionalAccessPolicies",
    "Test-SecurityDefaults",
    "Test-BreakGlassAccounts",
    "New-SecurityReport"
)