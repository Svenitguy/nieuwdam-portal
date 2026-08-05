#Requires -Version 5.1

<#
.SYNOPSIS
    Creates Microsoft Entra ID users from configuration.

.DESCRIPTION
    Loads user configuration and provisions users in Microsoft Entra ID.
    Uses modular framework components for Graph connection,
    configuration loading, logging and provisioning.

    Supports DryRun mode.

.PARAMETER DryRun
Runs the provisioning in simulation mode.
No users will be created or modified.

.PARAMETER ShowDetails
Displays detailed provisioning results.

.EXAMPLE
    .\01-provision-users.ps1

    Creates Microsoft Entra ID users from configuration.

.EXAMPLE
    .\01-provision-users.ps1 -DryRun

    Simulates user provisioning without making changes.

.NOTES

    Project :
        Entra ID Provisioning Framework

    Script :
        01 - provision-users

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

    [Parameter()]
    [switch]
    $SkipConfirmation,

    [Parameter()]
    [switch]
    $SaveState

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
        -LogName "users" `
        -DeploymentLogFile $DeploymentLogFile

    Write-Logging `
        -Message (
            "User provisioning started. RunId: {0}" `
            -f `
            $RunId
        ) `
        -Level INFO `
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
                "Create Microsoft Entra ID users"
            )

    }

    # ==================================================
    # Load configuration
    # ==================================================

    Write-Host ""

    Write-Status `
        -Status "INFO" `
        -Message "Loading user configuration..."

    $Users =
    Get-UserConfiguration `
        -ConfigFolder $ConfigPath

    $TenantConfiguration =
    Get-TenantConfiguration `
        -ConfigFolder $ConfigPath


    # ==================================================
    # Load existing Entra ID objects
    # ==================================================

    Write-Host ""

    if ($UseExistingGraphCache) {

        Write-Message `
            -Status PASS `
            -Message "Using existing Graph cache." `
            -Component GRAPH

        $DirectoryCache = Get-GraphCache

    }
    else {

        Write-Status `
            -Status INFO `
            -Message "Loading existing Entra ID users..."

        $DirectoryCache = Initialize-GraphCache

    }

    $GraphUsers =
    $DirectoryCache.Users

    $UsersBefore = $GraphUsers.Count


    # ==================================================
    # Provision users
    # ==================================================

    Write-Host ""

    if ($DryRun) {

        Write-Status `
            -Status "WARNING" `
            -Message "Running in DRY RUN mode. No changes will be applied."

    }

    $Results =
    @(New-EntraUsers `
            -ConfigUsers $Users `
            -GraphUsers $GraphUsers `
            -InitialPassword $TenantConfiguration.InitialPassword `
            -DryRun:$DryRun)


    # ==================================================
    # Reload Entra ID users after provisioning
    # ==================================================

    $DirectoryCacheAfter =
    Initialize-GraphCache -Silent -Refresh

    $UsersAfter =
    $DirectoryCacheAfter.Users.Count

    # ==================================================
    # Collect newly created users
    # ==================================================

    $ProvisionedUsers =
        $Results |
        Where-Object Action -eq "Created"

    $CreatedUsers =
        foreach($User in $ProvisionedUsers){

            $DirectoryCacheAfter.Users |
            Where-Object {
                $_.Id -eq $User.ObjectId
            }

        }

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
        -Title "User Provisioning Summary" `
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
        "User provisioning completed. UsersBefore: {0}, Created: {1}, WouldCreate: {2}, Skipped: {3}, Failed: {4}, UsersAfter: {5}" `
            -f `
            $UsersBefore,
            $CreatedCount,
            $WouldCreateCount,
            $SkippedCount,
            $FailedCount,
            $UsersAfter
        ) `
        -Level "PASS" `
        -Component "SYSTEM"

    $ProvisioningResult = [PSCustomObject]@{

        RunId = $RunId

        Summary = [PSCustomObject]@{

            UsersBefore = $UsersBefore
            UsersAfter  = $UsersAfter

            Created     = $CreatedCount
            WouldCreate = $WouldCreateCount
            Skipped     = $SkippedCount
            Failed      = $FailedCount

        }

        Results = @($Results)

    }


    Write-RunCompleted `
        -StartTime $ScriptStartTime `
        -RunId $RunId `
        -Processed $Users.Count


    # ==================================================
    # Save Provision State
    # ==================================================

    if($SaveState -and -not $DryRun){

        $CreatedUsers = @($CreatedUsers)

        $StateFile =
            New-ProvisionState `
                -Users $CreatedUsers `
                -Groups @() `
                -Memberships @() `
                -RunId $RunId `
                -StatePath (
                    Join-Path $RootPath "state"
                )

            Write-Status `
                -Status PASS `
                -Message "Provision state saved: $StateFile"

    }


    if ($PassThru) {

        return $ProvisioningResult

    }

}

catch {

    Write-Host ""

    Write-Host "==============================================" `
        -ForegroundColor Red

    Write-Host " USER PROVISIONING FAILED" `
        -ForegroundColor Red

    Write-Host "==============================================" `
        -ForegroundColor Red

    Write-Host ""

    Write-Host $_.Exception.Message `
        -ForegroundColor Red


    if ($RunId) {

        Write-Logging `
            -Message (
                "User provisioning failed. RunId: {0}. Error: {1}" `
                -f `
                $RunId,
                $_.Exception.Message
            ) `
            -Level ERROR `
            -Component "SYSTEM"

    }


    exit 1

}