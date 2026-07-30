#Requires -Version 5.1

<#
.SYNOPSIS
    Creates Microsoft Entra ID groups from configuration.

.DESCRIPTION
    Loads group configuration and provisions groups in Microsoft Entra ID.
    Uses modular framework components for Graph connection,
    logging and provisioning.

    Supports DryRun mode and detailed reporting.

.PARAMETER DryRun
Runs the provisioning in simulation mode.
No groups will be created or modified.

.PARAMETER ShowDetails
Displays detailed provisioning results.

.EXAMPLE
    .\02-provision-groups.ps1

    Creates Microsoft Entra ID groups from configuration.

.EXAMPLE
    .\02-provision-groups.ps1 -DryRun

    Simulates group provisioning without making changes.

.NOTES

    Project :
        Entra ID Provisioning Framework

    Script :
        02 - provision-groups

    Version :
        3.0.0

#>


[CmdletBinding()]

param(

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$ShowDetails,

    [string]$DeploymentLogFile,

    [Parameter()]
    [switch]
    $PassThru,

    [string]$RunId

)



# ==================================================
# PowerShell settings
# ==================================================

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"



# ==================================================
# Paths
# ==================================================

$RootPath =
Split-Path `
    $PSScriptRoot `
    -Parent

$ConfigPath =
Join-Path `
    $RootPath `
    "config"

$ModulePath =
Join-Path `
    $RootPath `
    "modules"


$LogPath =
Join-Path `
    $RootPath `
    "logs"



# ==================================================
# Import modules
# ==================================================

$RequiredModules = @(

    "$ModulePath\Logging\Logging.psm1"

    "$ModulePath\Helpers\Helpers.psm1"

    "$ModulePath\Configuration\Configuration.psm1"

    "$ModulePath\Graph\Graph.psm1"

    "$ModulePath\Provisioning\Provisioning.psm1"


)

foreach($Module in $RequiredModules){


    if(!(Test-Path $Module)){


        throw `
            "Required PowerShell module file not found: $Module"


    }


    Import-Module `
        $Module `
        -Force


}


# ==================================================
# Initialize Run Tracking
# ==================================================

if ([string]::IsNullOrWhiteSpace($RunId)) {

    $RunId = [guid]::NewGuid().ToString()

}

$ScriptStartTime = Get-Date

try {


# ==================================================
# Initialize logging
# ==================================================

Initialize-Logging `
    -LogFolder $LogPath `
    -LogName "groups" `
    -DeploymentLogFile $DeploymentLogFile



Write-Logging `
    -Message "Group provisioning started. RunId: $RunId" `
    -Level "INFO" `
    -Component "SYSTEM"


# ==================================================
# Connect Microsoft Graph
# ==================================================

Connect-EntraGraph `
    -AuthenticationMode Interactive

# ==================================================
# Load configuration
# ==================================================

Write-Host ""

Write-Status `
    -Status "INFO" `
    -Message "Loading group configuration..."


$Groups =
Get-GroupConfiguration `
    -ConfigFolder $ConfigPath


$TenantConfiguration =
Get-TenantConfiguration `
    -ConfigFolder $ConfigPath

# ==================================================
# Load existing Entra ID objects
# ==================================================

Write-Host ""

Write-Status `
    -Status "INFO" `
    -Message "Loading existing Entra ID groups..." `
    

$DirectoryCache =
Initialize-GraphCache

$GraphGroups =
$DirectoryCache.Groups

$GroupsBefore = $GraphGroups.Count

# ==================================================
# DryRun information
# ==================================================

if ($DryRun) {

    Write-Status `
        -Status "WARNING" `
        -Message "Running in DRY RUN mode. No changes will be applied."

}


# ==================================================
# Provision groups
# ==================================================

$Results =
@(

    New-EntraGroups `
        -ConfigGroups $Groups `
        -GraphGroups $GraphGroups `
        -DryRun:$DryRun

)

# ==================================================
# Reload Entra ID groups after provisioning
# ==================================================

$DirectoryCacheAfter =
Initialize-GraphCache -Silent -Refresh

$GroupsAfter =
$DirectoryCacheAfter.Groups.Count

# ==================================================
# Summary
# ==================================================

$CreatedCount =
Get-ResultCount `
    -Results $Results `
    -Action "Created"

$WouldCreateCount =
Get-ResultCount `
    -Results $Results `
    -Action "WouldCreate"

$SkippedCount =
Get-ResultCount `
    -Results $Results `
    -Action "Skipped"

$FailedCount =
Get-ResultCount `
    -Results $Results `
    -Action "Failed"

Write-ProvisioningSummary `
    -Title "Group Provisioning Summary" `
    -Summary @{
        Created = $CreatedCount
        "Would Create" = $WouldCreateCount
        Skipped = $SkippedCount
        Failed = $FailedCount
    }

# ==================================================
# Output results
# ==================================================

if ($ShowDetails) {

    $Results |
    Format-Table Timestamp, Type, Name, Action

}



# ==================================================
# Logging
# ==================================================

Write-Logging `
    -Message (
    "Group provisioning completed. GroupsBefore: {0}, Created: {1}, WouldCreate: {2}, Skipped: {3}, Failed: {4}, GroupsAfter: {5}" `
        -f `
        $GroupsBefore,
        $CreatedCount,
        $WouldCreateCount,
        $SkippedCount,
        $FailedCount,
        $GroupsAfter
) `
    -Level "PASS" `
    -Component "SYSTEM"

$ProvisioningResult = [PSCustomObject]@{

    RunId = $RunId

    Summary = [PSCustomObject]@{

        GroupsBefore = $GroupsBefore
        GroupsAfter  = $GroupsAfter

        Created      = $CreatedCount
        WouldCreate  = $WouldCreateCount
        Skipped      = $SkippedCount
        Failed       = $FailedCount

    }

    Results = @($Results)

}

Write-RunCompleted `
    -StartTime $ScriptStartTime `
    -RunId $RunId `
    -Processed $Groups.Count

if ($PassThru) {

    return $ProvisioningResult

}


}
catch {

    Write-Host ""

    Write-Host "==============================================" `
        -ForegroundColor Red

    Write-Host " GROUP PROVISIONING FAILED" `
        -ForegroundColor Red

    Write-Host "==============================================" `
        -ForegroundColor Red

    Write-Host ""

    Write-Host $_.Exception.Message `
        -ForegroundColor Red


    if ($RunId) {

        Write-Logging `
            -Message (
                "Group provisioning failed. RunId: {0}. Error: {1}" `
                -f `
                $RunId,
                $_.Exception.Message
            ) `
            -Level ERROR `
            -Component "SYSTEM"

    }


    exit 1

}