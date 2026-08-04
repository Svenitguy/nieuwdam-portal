#Requires -Version 5.1

<#
.SYNOPSIS
    Adds Microsoft Entra ID users to security groups.

.DESCRIPTION
    Loads group membership configuration and provisions
    Microsoft Entra ID group memberships.

    Features:
    - Idempotent membership assignment
    - DryRun support
    - Existing object detection
    - Graph cache usage
    - Detailed logging
    - Provisioning summary reporting

.PARAMETER DryRun
Runs membership assignment in simulation mode.
No group memberships will be changed.

.PARAMETER ShowDetails
Displays detailed membership results.

.EXAMPLE
    .\03-provision-group-memberships.ps1

    Assigns users to configured security groups.

.EXAMPLE
    .\03-provision-group-memberships.ps1 -DryRun

    Simulates membership assignment without making changes.

.NOTES

    Project :
        Entra ID Provisioning Framework

    Script :
        03 - provision-group-memberships

    Version :
        3.0.0

#>


[CmdletBinding()]

param(
    
    [Parameter()]
    [switch]
    $DryRun,


    [Parameter()]
    [switch]
    $ShowDetails,

    [string]$DeploymentLogFile,

    [Parameter()]
    [switch]
    $PassThru,

    [string]$RunId,

    [Parameter()]
    [switch]
    $UseExistingGraphConnection,

    [switch]
    $UseExistingGraphCache,

    [switch]
    $SkipConfirmation

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
        "Modules"


$LogPath =
    Join-Path `
        $RootPath `
        "Logs"



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
    -LogName "memberships" `
    -DeploymentLogFile $DeploymentLogFile



Write-Logging `
    -Message "Membership provisioning started. RunId: $RunId" `
    -Level "INFO" `
    -Component "SYSTEM"


# ==================================================
# Connect Microsoft Graph
# ==================================================

if($UseExistingGraphConnection){

    Write-Message `
        -Status PASS `
        -Message "Using existing Microsoft Graph connection." `
        -Component GRAPH

}
else {

    Connect-EntraGraph `
        -AuthenticationMode Interactive

}

# ==================================================
# Confirm live deployment
# ==================================================

if (-not $DryRun -and -not $SkipConfirmation) {

    Confirm-LiveDeployment `
        -Operations @(
            "Configure Microsoft Entra ID group memberships"
        )

}

# ==================================================
# Confirm live deployment
# ==================================================

if (-not $DryRun -and -not $SkipConfirmation) {

    Confirm-LiveDeployment `
        -Operation "Modify Microsoft Entra ID group memberships"

}

# ==================================================
# Load configuration
# ==================================================

Write-Host ""

Write-Status `
    -Status "INFO" `
    -Message "Loading group membership configuration..."

$MembershipConfig =
Get-MembershipConfiguration `
    -ConfigFolder $ConfigPath

# ==================================================
# Load existing Entra ID objects
# ==================================================

<#Write-Host ""

Write-Status `
    -Status "INFO" `
    -Message "Loading existing Entra ID objects..."

$GraphCache =
    Initialize-GraphCache

$GraphUsers =
    @(
        $GraphCache.Users
    )

$GraphGroups =
    @(
        $GraphCache.Groups
    )#>

# ==================================================
# Load existing Entra ID objects
# ==================================================

Write-Host ""

Write-Status `
    -Status "INFO" `
    -Message "Loading existing Entra ID objects..."


$DirectoryCache =
    Initialize-GraphCache


$GraphUsers =
    @(
        $DirectoryCache.Users
    )


$GraphGroups =
    @(
        $DirectoryCache.Groups
    )

# ==================================================
# DryRun information
# ==================================================

if($DryRun) {

    Write-Status `
        -Status "WARNING" `
        -Message "Running in DRY RUN mode. No changes will be applied."

}


# ==================================================
# Provision memberships
# ==================================================

Write-Host ""

Write-Host `
    "Starting group membership provisioning..." `
    -ForegroundColor Cyan



$Results =
    @(

        Add-EntraGroupMembers `
            -MembershipConfig $MembershipConfig `
            -GraphUsers $GraphUsers `
            -GraphGroups $GraphGroups `
            -DryRun:$DryRun

    )



# ==================================================
# Summary
# ==================================================

$AddedCount =
    Get-ResultCount `
        -Results $Results `
        -Action "Added"

$WouldAddCount =
    Get-ResultCount `
        -Results $Results `
        -Action "WouldAdd"

$SkippedCount =
    Get-ResultCount `
        -Results $Results `
        -Action "Skipped"

$FailedCount =
    Get-ResultCount `
        -Results $Results `
        -Action "Failed"

Write-ProvisioningSummary `
    -Title "Membership Provisioning Summary" `
    -Summary @{
        Added = $AddedCount
        "Would Create" = $WouldAddCount
        Skipped = $SkippedCount
        Failed = $FailedCount
    }

# ==================================================
# Output details
# ==================================================

if($ShowDetails) {


    $Results |
        Format-Table Timestamp,Type,Name,Action,Message

}



# ==================================================
# Logging
# ==================================================

Write-Logging `
    -Message (
        "Group membership provisioning completed. Added: {0}, WouldAdd: {1}, Skipped: {2}, Failed: {3}" `
        -f `
        $AddedCount,
        $WouldAddCount,
        $SkippedCount,
        $FailedCount
    ) `
    -Level "PASS" `
    -Component "SYSTEM"

$ProvisioningResult = [PSCustomObject]@{

    RunId = $RunId

    Summary = [PSCustomObject]@{

        Added    = $AddedCount
        WouldAdd = $WouldAddCount
        Skipped  = $SkippedCount
        Failed   = $FailedCount

    }

    Results = @($Results)

}


Write-RunCompleted `
    -StartTime $ScriptStartTime `
    -RunId $RunId `
    -Processed $MembershipConfig.Count

if ($PassThru) {

    return $ProvisioningResult

}

}
catch {

    Write-Host ""

    Write-Host "==============================================" `
        -ForegroundColor Red

    Write-Host " MEMBERSHIP PROVISIONING FAILED" `
        -ForegroundColor Red

    Write-Host "==============================================" `
        -ForegroundColor Red

    Write-Host ""

    Write-Logging `
        -Message $_.Exception.Message `
        -Level ERROR `
        -Component "SYSTEM"

    Write-Host $_.Exception.Message `
        -ForegroundColor Red

    exit 1

}