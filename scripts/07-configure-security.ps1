#Requires -Version 5.1

<#
.SYNOPSIS
    Configures Microsoft Entra ID security baseline.

.DESCRIPTION
    Executes enterprise security hardening tasks.

    Steps:

    1. Configure password policies
    2. Configure authentication methods
    3. Configure MFA
    4. Create Conditional Access policies
    5. Validate Security Defaults
    6. Validate Break-glass accounts
    7. Generate security report


.PARAMETER DryRun

    Runs security configuration simulation.
    No tenant changes will be applied.


.EXAMPLE

    .\07-configure-security.ps1


.EXAMPLE

    .\07-configure-security.ps1 -DryRun


.NOTES

    Project:
        Enterprise Entra ID Provisioning Framework

    Script:
        Security Configuration

    Version:
        1.0.0

#>


# ==================================================
# Parameters
# ==================================================

[CmdletBinding()]

param(

    [switch]
    $DryRun,

    [string]
    $DeploymentLogFile,

    [string]
    $RunId,

    [Parameter()]
    [switch]
    $UseExistingGraphConnection,

    [switch]
    $CreateMissingBreakGlass


)


# ==================================================
# PowerShell Configuration
# ==================================================

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"


# ==================================================
# Variables
# ==================================================

$ScriptRoot = $PSScriptRoot


$ModuleRoot =
Join-Path `
    (Split-Path $ScriptRoot -Parent) `
    "modules"

$ConfigFolder =
    Join-Path `
        (Split-Path $ScriptRoot -Parent) `
        "config"

$SecurityModule =
Join-Path `
    $ModuleRoot `
    "Security\Security.psm1"

$ScriptVersion = "1.0.0"

if(!$RunId){

    $RunId = [guid]::NewGuid().ToString()

}

$StartTime = Get-Date

# ==================================================
# Import Modules
# ==================================================

$RequiredModules = @(

    "$ModuleRoot\Logging\Logging.psm1"

    "$ModuleRoot\Helpers\Helpers.psm1"

    "$ModuleRoot\Configuration\Configuration.psm1"

    "$ModuleRoot\Graph\Graph.psm1"

    "$SecurityModule"

)



foreach($Module in $RequiredModules){


    if(!(Test-Path $Module)){


        throw `
            "Required module missing: $Module"


    }


    Import-Module `
        $Module `
        -Force

}


try {

    # ==================================================
    # Initialize Logging
    # ==================================================

    $LogFolder =
    Join-Path `
        $ScriptRoot `
        "..\logs"


    Initialize-Logging `
        -LogFolder $LogFolder `
        -LogName "security" `
        -DeploymentLogFile $DeploymentLogFile


    # ==================================================
    # Connect Microsoft Graph
    # ==================================================

    if($UseExistingGraphConnection){

        Write-Message `
            -Status PASS `
            -Message "Using existing Microsoft Graph connection." `
            -Component GRAPH

        Write-Host ""

    }
    else{

        Connect-EntraGraph `
            -AuthenticationMode Interactive

    }


    # --------------------------------------------------
    # Load Security Configuration
    # --------------------------------------------------

    Write-Message `
        -Status "INFO" `
        -Message "Loading security configuration..." `
        -Component "SECURITY"


    $SecurityConfiguration =
        Get-SecurityConfiguration `
            -ConfigFolder $ConfigFolder

    $CAPolicyCount = @(
        $SecurityConfiguration.ConditionalAccess.Policies
    ).Count


    Write-Message `
        -Status "PASS" `
        -Message (
            "Security configuration loaded. Conditional Access policies: {0}" -f
            $CAPolicyCount
        ) `
        -Component "SECURITY"

    if($DryRun){

        Write-Message `
            -Status "WARNING" `
            -Message "Running in DRY RUN mode. No changes will be applied." `
            -Component "SECURITY"

    }



    Write-Host ""

    Write-Host "Starting security configuration..."

    Write-Host ""


    $SecurityResults = @()

    # --------------------------------------------------
    # Password Policy
    # --------------------------------------------------

    Write-Host ""

    Write-Host "[1/7] Password Policy"

    Write-Host (
        "       {0}" -f
        $(if($DryRun){"WOULD CONFIGURE"}else{"CONFIGURE"})
    )

    $SecurityResults +=
        Set-PasswordPolicy `
            -Configuration $SecurityConfiguration.PasswordPolicy `
            -DryRun:$DryRun

    # --------------------------------------------------
    # Authentication Methods
    # --------------------------------------------------

    Write-Host ""

    Write-Host "[2/7] Authentication Methods"

    Write-Host (
        "       {0}" -f
        $(if($DryRun){"WOULD CONFIGURE"}else{"CONFIGURE"})
    )

    $SecurityResults +=
        Set-AuthenticationMethods `
            -Configuration $SecurityConfiguration.AuthenticationMethods `
            -DryRun:$DryRun



    # --------------------------------------------------
    # MFA
    # --------------------------------------------------

    Write-Host ""

    Write-Host "[3/7] MFA Configuration"

    Write-Host (
        "       {0}" -f
        $(if($DryRun){"WOULD CONFIGURE"}else{"CONFIGURE"})
    )

    $SecurityResults +=
        Set-MFAConfiguration `
            -DryRun:$DryRun `
            -Configuration $SecurityConfiguration.MFA

    # --------------------------------------------------
    # Break Glass Accounts
    # --------------------------------------------------

    Write-Host ""

    Write-Host "[4/7] Break Glass Accounts"

    Write-Host (
        "       {0}" -f
        $(if($DryRun){"WOULD VALIDATE"}else{"VALIDATE"})
    )

    $BreakGlassResult =
        New-BreakGlassAccounts `
            -Configuration $SecurityConfiguration.BreakGlassAccounts `
            -DryRun:$DryRun `
            -CreateMissing:$CreateMissingBreakGlass

    $SecurityResults +=
        [PSCustomObject]@{

            Component = "BreakGlassAccounts"

            Status =
                $BreakGlassResult.Status

            RequiredCount =
                $BreakGlassResult.RequiredCount

            FoundCount =
                $BreakGlassResult.FoundCount

            MissingCount =
                $BreakGlassResult.MissingCount

            ObjectIds =
                $BreakGlassResult.ObjectIds

        }

    # --------------------------------------------------
    # Conditional Access
    # --------------------------------------------------

    Write-Host ""

    Write-Host "[5/7] Conditional Access Policies"

    Write-Host (
        "       {0}" -f
        $(if($DryRun){"WOULD CREATE"}else{"CREATE"})
    )

    $SecurityResults +=
        New-ConditionalAccessPolicies `
            -DryRun:$DryRun `
            -Configuration $SecurityConfiguration.ConditionalAccess `
            -BreakGlassConfiguration $BreakGlassResult

    # --------------------------------------------------
    # Security Defaults
    # --------------------------------------------------

    Write-Host ""

    Write-Host "[6/7] Security Defaults"

    Write-Host (
        "       {0}" -f
        $(if($DryRun){"WOULD VALIDATE"}else{"VALIDATE"})
    )

    $SecurityResults +=
        Test-SecurityDefaults `
            -DryRun:$DryRun `
            -Configuration $SecurityConfiguration.SecurityDefaults



    # --------------------------------------------------
    # Break Glass Accounts
    # --------------------------------------------------

    <#Write-Host ""

    Write-Host "[7/7] Break Glass Accounts"

    Write-Host (
        "       {0}" -f
        $(if($DryRun){"WOULD VALIDATE"}else{"VALIDATE"})
    )

    $SecurityResults +=
        Test-BreakGlassAccounts `
            -DryRun:$DryRun `
            -Configuration $SecurityConfiguration.BreakGlassAccounts#>


# --------------------------------------------------
# Build Results from Security Module Output
# --------------------------------------------------

$Results = @{}

foreach($Item in $SecurityResults){

    if($null -ne $Item -and $Item.Component){

        $Results[$Item.Component] = $Item

    }

}


    # --------------------------------------------------
    # Security Report
    # --------------------------------------------------

    $Report =
        New-SecurityReport `
            -Results $Results `
            -RunId $RunId `
            -DryRun:$DryRun

    # --------------------------------------------------
    # Security Summary
    # --------------------------------------------------

    $Summary = @{

        PasswordPolicy =
            if($DryRun){"WouldConfigure"}else{"Configured"}

        Authentication =
            if($DryRun){"WouldConfigure"}else{"Configured"}

        MFA =
            if($DryRun){"WouldConfigure"}else{"Configured"}

        ConditionalAccess =
            if($DryRun){"WouldCreate"}else{"Configured"}

        SecurityDefaults =
            if($DryRun){"WouldValidate"}else{"Validated"}

        BreakGlassAccounts =
            if($DryRun){"WouldValidate"}else{"Validated"}

    }

    $SecurityDisplayOrder = @(
        "PasswordPolicy",
        "Authentication",
        "MFA",
        "ConditionalAccess",
        "SecurityDefaults",
        "BreakGlassAccounts"
    )


    Write-Host ""

    Write-Host `
        "==============================================" `
        -ForegroundColor Cyan

    Write-Host `
        " Security Configuration Summary" `
        -ForegroundColor Cyan

    Write-Host `
        "==============================================" `
        -ForegroundColor Cyan


    foreach($Item in $SecurityDisplayOrder){

        if($Summary.ContainsKey($Item)){

            Write-Host (
                "{0,-20}: {1}" -f
                $Item,
                $Summary[$Item]
        )

        }

    }





    Write-Message `
        -Status "PASS" `
        -Message "Security configuration completed successfully." `
        -Component "SECURITY"


    return @{

        Report =
            $Report

        RunId =
            $RunId

        Results =
            $Results

        DryRun =
            $DryRun

    }


}


catch {


    Write-Message `
        -Status "ERROR" `
        -Message $_.Exception.Message `
        -Component "SECURITY"


    throw

}