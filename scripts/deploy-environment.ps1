#Requires -Version 5.1

<#
.SYNOPSIS
Deploys a complete Microsoft Entra ID environment.

.DESCRIPTION
Main deployment orchestrator for the Entra ID Provisioning Framework.

Executes deployment steps:

1. Provision users
2. Provision groups
3. Configure group memberships
4. Validate environment
5. Save provision state
6. Configure security baseline

Supports DryRun mode to simulate changes
without modifying the tenant.

.PARAMETER DryRun
Runs the deployment in simulation mode.
No users, groups or memberships will be created.

.EXAMPLE
.\deploy-environment.ps1

Runs a complete deployment.

.EXAMPLE
.\deploy-environment.ps1 -DryRun

Simulates deployment without modifying the tenant.

.NOTES
Project :
    Entra ID Provisioning Framework

Script :
    Deploy Environment

Version :
    Loaded from config/platform.config.psd1
#>

# ==================================================
# Parameters
# ==================================================

[CmdletBinding()]
param(

    [Parameter()]
    [switch]
    $DryRun

)

# ==================================================
# PowerShell Configuration
# ==================================================

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"

# ==================================================
# Paths
# ==================================================

$ScriptRoot =
    $PSScriptRoot

$ModuleRoot =
    Join-Path `
        (Split-Path $ScriptRoot -Parent) `
        "modules"

$ConfigFolder =
    Join-Path `
        $ScriptRoot `
        "..\config"

$LogFolder =
    Join-Path `
        $ScriptRoot `
        "..\logs"

# ==================================================
# Import modules
# ==================================================

$RequiredModules = @(

    "$ModuleRoot\Logging\Logging.psm1"

    "$ModuleRoot\Helpers\Helpers.psm1"

    "$ModuleRoot\Configuration\Configuration.psm1"

    "$ModuleRoot\Graph\Graph.psm1"

    "$ModuleRoot\Provisioning\Provisioning.psm1"

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

$RunId =
    [guid]::NewGuid().ToString()

$DeploymentStart =
    Get-Date

$ScriptStartTime =
    Get-Date

# ==================================================
# Deployment Step Header
# ==================================================

function Write-DeploymentStepHeader {

    param(

        [Parameter(Mandatory)]
        [int]$Step,

        [Parameter(Mandatory)]
        [int]$Total,

        [Parameter(Mandatory)]
        [string]$Title

    )

    Write-Host ""

    Write-Host "================================================" `
        -ForegroundColor Cyan

    Write-Host "STEP $Step/$Total - $Title" `
        -ForegroundColor Cyan

    Write-Host "================================================" `
        -ForegroundColor Cyan

}

# ==================================================
# Main Execution
# ==================================================

try {

    # ==================================================
    # Initialize Logging
    # ==================================================

    Initialize-Logging `
        -LogFolder $LogFolder `
        -LogName "deployment"

    $DeploymentLogFile =
        Get-CurrentLogFile

    Write-DeploymentLog `
        -Message "Deployment started. RunId: $RunId" `
        -Level INFO `
        -Component "SYSTEM"

    # ==================================================
    # Load Platform Configuration
    # ==================================================

    $PlatformConfig =
        Get-PlatformConfig `
            -ConfigFolder $ConfigFolder

    $FrameworkName =
        $PlatformConfig.FrameworkName

    $FrameworkVersion =
        $PlatformConfig.FrameworkVersion

    # ==================================================
    # Validate Platform Configuration
    # ==================================================

    if([string]::IsNullOrWhiteSpace($FrameworkName)){

        throw "FrameworkName is missing from platform.config.psd1"

    }

    if([string]::IsNullOrWhiteSpace($FrameworkVersion)){

        throw "FrameworkVersion is missing from platform.config.psd1"

    }

    # ==================================================
    # Deployment Header
    # ==================================================

    Write-Host ""

    Write-Host "==============================================" `
        -ForegroundColor Cyan

    Write-Host " $FrameworkName" `
        -ForegroundColor Cyan

    Write-Host "==============================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-Host "Version : $FrameworkVersion"

    Write-Host "Mode    : $(if($DryRun){'DRY-RUN'}else{'DEPLOYMENT'})"

    Write-Host "Started : $(Get-Date -Format 'dd/MM/yyyy HH\:mm\:ss')"

    Write-Host ""

    Write-DeploymentLog `
        -Message (
            "Framework: {0}. Version: {1}. Mode: {2}" `
            -f `
            $FrameworkName,
            $FrameworkVersion,
            $(if($DryRun){"DRY-RUN"}else{"DEPLOYMENT"})
        ) `
        -Level INFO `
        -Component "SYSTEM"

    # ==================================================
    # Deployment workflow
    # ==================================================

    $DeploymentSteps = @(
        "Provisioning users"
        "Provisioning groups"
        "Configuring group memberships"
        "Validating environment"
        "Saving provision state"
        "Configuring security baseline"
    )

    $TotalSteps =
        $DeploymentSteps.Count

    $CurrentStep = 1

    # ==================================================
    # Required Scripts
    # ==================================================

    Write-DeploymentLog `
        -Message "Checking required scripts..." `
        -Level INFO `
        -Component "SYSTEM"

    $RequiredScripts = @(

        "01-provision-users.ps1"
        "02-provision-groups.ps1"
        "03-provision-group-memberships.ps1"
        "04-validate-environment.ps1"
        "05-save-provision-state.ps1"
        "07-configure-security.ps1"

    )

    foreach($Script in $RequiredScripts) {

        $ScriptPath =
            Join-Path `
                $ScriptRoot `
                $Script

        if(!(Test-Path $ScriptPath)) {

            throw `
                "Required script missing: $Script"

        }

    }

    Write-DeploymentLog `
        -Message "All required scripts found." `
        -Level PASS `
        -Component "SYSTEM"

    # ==================================================
    # Deployment Steps
    # ==================================================

    Write-Host ""

    Write-Status `
        -Status "INFO" `
        -Message "Starting deployment workflow..."

    # ==================================================
    # Connect Microsoft Graph
    # ==================================================

    Write-Host ""

    Write-Host "Connecting to Microsoft Graph" `
        -ForegroundColor Cyan

    Write-DeploymentLog `
        -Message "Connecting to Microsoft Graph." `
        -Level INFO `
        -Component "SYSTEM"

    Connect-EntraGraph

    Write-DeploymentLog `
        -Message "Microsoft Graph connection established." `
        -Level PASS `
        -Component "SYSTEM"

    # ==================================================
    # Confirm live deployment
    # ==================================================

    if (-not $DryRun) {

        Confirm-LiveDeployment `
            -Operation @(
                "Create Microsoft Entra ID users"
                "Create Microsoft Entra ID groups"
                "Configure Microsoft Entra ID group memberships"
                "Validate Microsoft Entra ID environment"
                "Save provisioning state"
                "Configure Microsoft Entra ID security baseline"
            )

    }


# ==================================================
# Step - Provision Users
# ==================================================

Write-DeploymentStepHeader `
    -Step $CurrentStep `
    -Total $TotalSteps `
    -Title $DeploymentSteps[$CurrentStep - 1]

Write-DeploymentLog `
    -Message "STEP $CurrentStep/$TotalSteps - User provisioning started." `
    -Level INFO `
    -Component "SYSTEM"

if($DryRun) {

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Running user provisioning in DRY-RUN mode." `
        -Level INFO `
        -Component "SYSTEM"

    $UserResult =
    & "$ScriptRoot\01-provision-users.ps1" `
        -DryRun `
        -DeploymentLogFile $DeploymentLogFile `
        -RunId $RunId `
        -PassThru `
        -UseExistingGraphConnection `
        -SkipConfirmation

}
else {

    $UserResult =
    & "$ScriptRoot\01-provision-users.ps1" `
        -DeploymentLogFile $DeploymentLogFile `
        -RunId $RunId `
        -PassThru `
        -UseExistingGraphConnection `
        -SkipConfirmation

}

Write-DeploymentLog `
    -Message (
        "User provisioning summary. UsersBefore: {0}, Created: {1}, WouldCreate: {2}, Skipped: {3}, Failed: {4}, UsersAfter: {5}" `
        -f `
        $UserResult.Summary.UsersBefore,
        $UserResult.Summary.Created,
        $UserResult.Summary.WouldCreate,
        $UserResult.Summary.Skipped,
        $UserResult.Summary.Failed,
        $UserResult.Summary.UsersAfter
    ) `
    -Level INFO `
    -Component "SYSTEM"

Write-DeploymentLog `
    -Message "STEP $CurrentStep/$TotalSteps - User provisioning completed." `
    -Level PASS `
    -Component "SYSTEM"

Write-Host ""
Write-Host "[PASS] STEP $CurrentStep/$TotalSteps - User provisioning completed." `
    -ForegroundColor Green

$CurrentStep++

# ==================================================
# Step - Provision Groups
# ==================================================

Write-DeploymentStepHeader `
    -Step $CurrentStep `
    -Total $TotalSteps `
    -Title $DeploymentSteps[$CurrentStep - 1]

Write-DeploymentLog `
    -Message "STEP $CurrentStep/$TotalSteps - Provisioning groups started." `
    -Level INFO `
    -Component "SYSTEM"

if($DryRun) {

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Running group provisioning in DRY-RUN mode." `
        -Level INFO `
        -Component "SYSTEM"

    $GroupResult =
    & "$ScriptRoot\02-provision-groups.ps1" `
        -DryRun `
        -DeploymentLogFile $DeploymentLogFile `
        -RunId $RunId `
        -PassThru `
        -UseExistingGraphConnection `
        -SkipConfirmation

}
else {

    $GroupResult =
    & "$ScriptRoot\02-provision-groups.ps1" `
        -DeploymentLogFile $DeploymentLogFile `
        -RunId $RunId `
        -PassThru `
        -UseExistingGraphConnection `
        -SkipConfirmation

}

Write-DeploymentLog `
    -Message (
        "Group provisioning summary. GroupsBefore: {0}, Created: {1}, WouldCreate: {2}, Skipped: {3}, Failed: {4}, GroupsAfter: {5}" `
        -f `
        $GroupResult.Summary.GroupsBefore,
        $GroupResult.Summary.Created,
        $GroupResult.Summary.WouldCreate,
        $GroupResult.Summary.Skipped,
        $GroupResult.Summary.Failed,
        $GroupResult.Summary.GroupsAfter
    ) `
    -Level INFO `
    -Component "SYSTEM"

Write-DeploymentLog `
    -Message "STEP $CurrentStep/$TotalSteps - Group provisioning completed." `
    -Level PASS `
    -Component "SYSTEM"

Write-Host ""
Write-Host "[PASS] STEP $CurrentStep/$TotalSteps - Group provisioning completed." `
    -ForegroundColor Green

$CurrentStep++

# ==================================================
# Step - Configure Memberships
# ==================================================

Write-DeploymentStepHeader `
    -Step $CurrentStep `
    -Total $TotalSteps `
    -Title $DeploymentSteps[$CurrentStep - 1]

Write-DeploymentLog `
    -Message "STEP $CurrentStep/$TotalSteps - Group membership configuration started." `
    -Level INFO `
    -Component "SYSTEM"

if($DryRun) {

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Running membership configuration in DRY-RUN mode." `
        -Level INFO `
        -Component "SYSTEM"

    $MembershipResult =
    & "$ScriptRoot\03-provision-group-memberships.ps1" `
        -DryRun `
        -DeploymentLogFile $DeploymentLogFile `
        -RunId $RunId `
        -PassThru `
        -UseExistingGraphConnection `
        -SkipConfirmation

}
else {

    $MembershipResult =
    & "$ScriptRoot\03-provision-group-memberships.ps1" `
        -DeploymentLogFile $DeploymentLogFile `
        -RunId $RunId `
        -PassThru `
        -UseExistingGraphConnection `
        -SkipConfirmation

}

Write-DeploymentLog `
    -Message (
        "Membership provisioning summary. Added: {0}, WouldAdd: {1}, Skipped: {2}, Failed: {3}" `
        -f `
        $MembershipResult.Summary.Added,
        $MembershipResult.Summary.WouldAdd,
        $MembershipResult.Summary.Skipped,
        $MembershipResult.Summary.Failed
    ) `
    -Level INFO `
    -Component "SYSTEM"

Write-DeploymentLog `
    -Message "STEP $CurrentStep/$TotalSteps - Group membership configuration completed." `
    -Level PASS `
    -Component "SYSTEM"

Write-Host ""
Write-Host "[PASS] STEP $CurrentStep/$TotalSteps - Group membership configuration completed." `
    -ForegroundColor Green

$CurrentStep++

# ==================================================
# Step - Validation
# ==================================================

Write-DeploymentStepHeader `
    -Step $CurrentStep `
    -Total $TotalSteps `
    -Title $DeploymentSteps[$CurrentStep - 1]

Write-DeploymentLog `
    -Message "STEP $CurrentStep/$TotalSteps - Validation started." `
    -Level INFO `
    -Component "SYSTEM"

if($DryRun) {

    Write-Host ""
    Write-Host "DRY-RUN MODE - Validation skipped" `
        -ForegroundColor Yellow

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Validation skipped because deployment is running in DRY-RUN mode." `
        -Level INFO `
        -Component "SYSTEM"

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Validation simulation completed." `
        -Level PASS `
        -Component "SYSTEM"

    Write-Host ""
    Write-Host "[PASS] STEP $CurrentStep/$TotalSteps - Validation skipped in DRY-RUN mode." `
        -ForegroundColor Green
}
else {

    $ValidationResult =
        & "$ScriptRoot\04-validate-environment.ps1" `
            -DeploymentLogFile $DeploymentLogFile `
            -RunId $RunId `
            -PassThru `
            -UseExistingGraphConnection

    if($ValidationResult.Failed -gt 0){

        throw "Deployment stopped. Validation failed with $($ValidationResult.Failed) errors."

    }

    Write-DeploymentLog `
        -Message (
            "Validation summary: TotalChecks: {0}, Passed: {1}, Failed: {2}" `
            -f `
            $ValidationResult.TotalChecks,
            $ValidationResult.Passed,
            $ValidationResult.Failed
        ) `
        -Level INFO `
        -Component "SYSTEM"

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Validation completed." `
        -Level PASS `
        -Component "SYSTEM"

    Write-Host ""
    Write-Host "[PASS] STEP $CurrentStep/$TotalSteps - Validation completed." `
        -ForegroundColor Green
}

$CurrentStep++

# ==================================================
# Step - Save Provision State
# ==================================================

Write-DeploymentStepHeader `
    -Step $CurrentStep `
    -Total $TotalSteps `
    -Title $DeploymentSteps[$CurrentStep - 1]

Write-DeploymentLog `
    -Message "STEP $CurrentStep/$TotalSteps - Save provision state started." `
    -Level INFO `
    -Component "SYSTEM"

if($DryRun) {

    Write-Host ""

    Write-Host "DRY-RUN MODE - Provision state not saved" `
        -ForegroundColor Yellow

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Save provision state skipped because deployment is running in DRY-RUN mode." `
        -Level INFO `
        -Component "SYSTEM"

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Save provision state simulation completed." `
        -Level PASS `
        -Component "SYSTEM"

    Write-Host ""
    Write-Host "[PASS] STEP $CurrentStep/$TotalSteps - Provision state skipped in DRY-RUN mode." `
        -ForegroundColor Green

}
else {

    $StateResult =
        & "$ScriptRoot\05-save-provision-state.ps1" `
            -DeploymentLogFile $DeploymentLogFile `
            -RunId $RunId

    Write-DeploymentLog `
        -Message (
            "Provision state saved. File: {0}. Users: {1}, Groups: {2}, Memberships: {3}" `
            -f `
            $StateResult.StateFile,
            $StateResult.Users,
            $StateResult.Groups,
            $StateResult.Memberships
        ) `
        -Level PASS `
        -Component "SYSTEM"

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Save provision state completed." `
        -Level PASS `
        -Component "SYSTEM"

    Write-Host ""
    Write-Host "[PASS] STEP $CurrentStep/$TotalSteps - Provision state saved." `
        -ForegroundColor Green

}

$CurrentStep++

# ==================================================
# Step - Configure Security Baseline
# ==================================================

Write-DeploymentStepHeader `
    -Step $CurrentStep `
    -Total $TotalSteps `
    -Title $DeploymentSteps[$CurrentStep - 1]

Write-DeploymentLog `
    -Message "STEP $CurrentStep/$TotalSteps - Security configuration started." `
    -Level INFO `
    -Component "SYSTEM"

if($DryRun){

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Running security configuration in DRY-RUN mode." `
        -Level INFO `
        -Component "SYSTEM"

    $SecurityResult =
        & "$ScriptRoot\07-configure-security.ps1" `
            -DryRun `
            -DeploymentLogFile $DeploymentLogFile `
            -RunId $RunId `
            -UseExistingGraphConnection

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Security configuration simulation completed." `
        -Level PASS `
        -Component "SECURITY"

    Write-Host ""
    Write-Host "[PASS] STEP $CurrentStep/$TotalSteps - Security configuration simulation completed." `
        -ForegroundColor Green

}
else {

    $SecurityResult =
        & "$ScriptRoot\07-configure-security.ps1" `
            -DeploymentLogFile $DeploymentLogFile `
            -RunId $RunId `
            -UseExistingGraphConnection

    Write-DeploymentLog `
        -Message "STEP $CurrentStep/$TotalSteps - Security configuration completed." `
        -Level PASS `
        -Component "SECURITY"

    Write-Host ""
    Write-Host "[PASS] STEP $CurrentStep/$TotalSteps - Security configuration completed." `
        -ForegroundColor Green

}

$CurrentStep++

# ==================================================
# Deployment Completed
# ==================================================

$DeploymentEnd = Get-Date

$Duration =
$DeploymentEnd - $DeploymentStart

$FormattedDuration =
"{0:00}h:{1:00}m:{2:00}s.{3:000}ms" -f `
    $Duration.Hours, `
    $Duration.Minutes, `
    $Duration.Seconds, `
    $Duration.Milliseconds

Write-Host ""

Write-Host "==============================================" `
-ForegroundColor Green

Write-Host " Deployment completed successfully" `
-ForegroundColor Green

Write-DeploymentLog `
    -Message "Deployment completed successfully." `
    -Level PASS `
    -Component "SYSTEM"

Write-DeploymentLog `
    -Message (
        "Deployment finished. RunId: {0}. Duration: {1}" `
        -f `
        $RunId,
        $FormattedDuration
    ) `
    -Level PASS `
    -Component "SYSTEM"

Write-DeploymentLog `
    -Message ("End time: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) `
    -Level INFO `
    -Component "SYSTEM"

Write-DeploymentLog `
    -Message ("Duration: {0}" -f $FormattedDuration) `
    -Level INFO `
    -Component "SYSTEM"

Write-Host " Duration : $FormattedDuration" `
    -ForegroundColor Green

Write-Host "==============================================" `
-ForegroundColor Green

}

catch {

    Write-Host ""

    Write-Host "==============================================" `
        -ForegroundColor Red

    Write-Host " DEPLOYMENT FAILED" `
        -ForegroundColor Red

    Write-Host "==============================================" `
        -ForegroundColor Red

    Write-Host ""

    Write-Host $_.Exception.Message `
        -ForegroundColor Red

    if(Get-Command Write-DeploymentLog -ErrorAction SilentlyContinue){

        try {

            Write-DeploymentLog `
                -Message $_.Exception.Message `
                -Level ERROR `
                -Component "SYSTEM"

        }
        catch {

            Write-Host "Unable to write deployment error to log." `
                -ForegroundColor Yellow

        }

    }

    exit 1

}