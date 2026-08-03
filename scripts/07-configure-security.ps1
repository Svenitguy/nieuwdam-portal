#Requires -Version 5.1

<#
.SYNOPSIS
    Configures Microsoft Entra ID security baseline.

.DESCRIPTION
    Executes enterprise security hardening tasks.

    Steps:

    1. Load Security module
    2. Configure password policies
    3. Configure authentication methods
    4. Configure MFA
    5. Create Conditional Access policies
    6. Validate Security Defaults
    7. Validate Break-glass accounts
    8. Generate security report


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
    $RunId

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

# ==================================================
# Initialize Logging
# ==================================================

$LogFolder =
Join-Path `
    $ScriptRoot `
    "..\logs"


Initialize-Logging `
    -LogFolder $LogFolder `
    -LogName "security"


# ==================================================
# Security Execution
# ==================================================

try {


    Write-Message `
        -Status "INFO" `
        -Message "Starting security configuration." `
        -Component "SECURITY"



    if($DryRun){


        Write-Message `
            -Status "DRYRUN" `
            -Message "Security configuration running in simulation mode." `
            -Component "SECURITY"


    }


    $SecurityResults = @()

   
    if(!$DryRun){

        Connect-EntraGraph

    }

    # --------------------------------------------------
    # Load Security Configuration
    # --------------------------------------------------

    $SecurityConfiguration =
        Get-SecurityConfiguration `
            -ConfigFolder $ConfigFolder


    # --------------------------------------------------
    # Password Policy
    # --------------------------------------------------

    $SecurityResults +=
        Set-PasswordPolicy `
            -Configuration $SecurityConfiguration.PasswordPolicy `
            -DryRun:$DryRun



    # --------------------------------------------------
    # Authentication Methods
    # --------------------------------------------------

    $SecurityResults +=
        Set-AuthenticationMethods `
            -Configuration $SecurityConfiguration.AuthenticationMethods `
            -DryRun:$DryRun



    # --------------------------------------------------
    # MFA
    # --------------------------------------------------

    $SecurityResults +=
        Set-MFAConfiguration `
            -DryRun:$DryRun `
            -Configuration $SecurityConfiguration.MFA



    # --------------------------------------------------
    # Conditional Access
    # --------------------------------------------------

    $SecurityResults +=
        New-ConditionalAccessPolicies `
            -DryRun:$DryRun `
            -Configuration $SecurityConfiguration.ConditionalAccess


    # --------------------------------------------------
    # Security Defaults
    # --------------------------------------------------

    $SecurityResults +=
        Test-SecurityDefaults `
            -DryRun:$DryRun `
            -Configuration $SecurityConfiguration.SecurityDefaults



    # --------------------------------------------------
    # Break Glass Accounts
    # --------------------------------------------------

    $SecurityResults +=
        Test-BreakGlassAccounts `
            -DryRun:$DryRun `
            -Configuration $SecurityConfiguration.BreakGlassAccounts

# --------------------------------------------------
# Build Results from Security Module Output
# --------------------------------------------------

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