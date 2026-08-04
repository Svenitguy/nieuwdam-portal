#Requires -Version 5.1

<#
.SYNOPSIS
Deploys a complete Microsoft Entra ID environment.

.DESCRIPTION
    Main deployment orchestrator for the Entra ID Provisioning Framework.

    Executes provisioning steps:

    1. Connect Microsoft Graph
    2. Provision users
    3. Provision groups
    4. Configure group memberships
    5. Validate environment


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

    Simulates deployment without making changes.


.NOTES

    Project :
        Entra ID Provisioning Framework

    Script :
        Deploy Environment

    Version :
        3.0.0
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
# Variables
# ==================================================

$DeploymentStart = Get-Date

$ScriptVersion = "3.0.0"

$ScriptRoot = $PSScriptRoot

$ModuleRoot =
Join-Path `
    (Split-Path $ScriptRoot -Parent) `
    "modules"

$LogFolder = Join-Path `
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

$RunId = [guid]::NewGuid().ToString()

$ScriptStartTime = Get-Date

try {

# ==================================================
# Initialize Logging
# ==================================================

Initialize-Logging `
    -LogFolder $LogFolder `
    -LogName "deployment"

$DeploymentLogFile = Get-CurrentLogFile

Write-DeploymentLog `
    -Message "Deployment started. RunId: $RunId" `
    -Level INFO `
    -Component "SYSTEM"

# ==================================================
# Deployment Header
# ==================================================

Write-Host ""

Write-Host "==============================================" `
-ForegroundColor Cyan

Write-Host " Entra ID Provisioning Framework" `
-ForegroundColor Cyan

Write-Host "==============================================" `
-ForegroundColor Cyan

Write-Host ""

Write-Host "Version : $ScriptVersion"

Write-Host "Mode    : $(if($DryRun){'DRY-RUN'}else{'DEPLOYMENT'})"

Write-Host "Started : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"

Write-Host ""

# ==================================================
# Required Scripts
# ==================================================

Write-DeploymentLog `
    -Message "Checking required scripts..." `
    -Level INFO `
    -Component "SYSTEM"

$RequiredScripts = @(

    "01-provision-users.ps1",
    "02-provision-groups.ps1",
    "03-provision-group-memberships.ps1",
    "04-validate-environment.ps1",
    "05-save-provision-state.ps1"

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
    -Level INFO

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
        )

}

# ==================================================
# Step 1/4 - Provision Users
# ==================================================

Write-Host ""

Write-Host "STEP 1/4 - Provisioning users" `
-ForegroundColor Cyan

Write-DeploymentLog `
    -Message "STEP 1/4 - Provisioning users started." `
    -Level INFO `
    -Component "SYSTEM"

if($DryRun) {

    Write-DeploymentLog `
        -Message "STEP 1/4 - Running user provisioning in DRY-RUN mode." `
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
    -Message "STEP 1/4 - User provisioning completed." `
    -Level PASS `
    -Component "SYSTEM"

# ==================================================
# Step 2/4 - Provision Groups
# ==================================================

Write-Host ""

Write-Host "STEP 2/4 - Provisioning groups" `
-ForegroundColor Cyan

Write-DeploymentLog `
    -Message "STEP 2/4 - Provisioning groups started." `
    -Level INFO `
    -Component "SYSTEM"

if($DryRun) {

    Write-DeploymentLog `
        -Message "STEP 2/4 - Running group provisioning in DRY-RUN mode." `
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
    -Message "STEP 2/4 - Group provisioning completed." `
    -Level PASS `
    -Component "SYSTEM"

# ==================================================
# Step 3/4 - Configure Memberships
# ==================================================

Write-Host ""

Write-Host "STEP 3/4 - Configuring group memberships" `
-ForegroundColor Cyan

Write-DeploymentLog `
    -Message "STEP 3/4 - Group membership configuration started." `
    -Level INFO `
    -Component "SYSTEM"

if($DryRun) {

    Write-DeploymentLog `
        -Message "STEP 3/4 - Running membership configuration in DRY-RUN mode." `
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
    -Message "STEP 3/4 - Group membership configuration completed." `
    -Level PASS `
    -Component "SYSTEM"

# ==================================================
# Step 4/4 - Validation
# ==================================================

Write-Host ""

Write-Host "STEP 4/4 - Validating environment" `
-ForegroundColor Cyan

Write-DeploymentLog `
    -Message "STEP 4/4 - Validation started." `
    -Level INFO `
    -Component "SYSTEM"

<#$ValidationResult =
& "$ScriptRoot\04-validate-environment.ps1" `
    -DeploymentLogFile $DeploymentLogFile `
    -RunId $RunId `
    -PassThru#>

<#$ValidationResult =
& "$ScriptRoot\04-validate-environment.ps1" `
    -DeploymentLogFile $DeploymentLogFile `
    -RunId $RunId `
    -PassThru


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
    -Message "STEP 4/4 - Validation completed." `
    -Level PASS `
    -Component "SYSTEM"#>

if($DryRun) {


    Write-Host ""

    Write-Host "DRY-RUN MODE - Validation skipped" `
        -ForegroundColor Yellow


    Write-DeploymentLog `
        -Message "STEP 4/4 - Validation skipped because deployment is running in DRY-RUN mode." `
        -Level INFO `
        -Component "SYSTEM"


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
        -Message "STEP 4/4 - Validation completed." `
        -Level PASS `
        -Component "SYSTEM"


}

# ==================================================
# Step 5/5 - Save Provision State
# ==================================================

<#Write-Host ""

Write-Host "STEP 5/5 - Saving provision state" `
-ForegroundColor Cyan


Write-DeploymentLog `
    -Message "STEP 5/5 - Save provision state started." `
    -Level INFO `
    -Component "SYSTEM"


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
    -Message "STEP 5/5 - Save provision state completed." `
    -Level PASS `
    -Component "SYSTEM"#>

# ==================================================
# Step 5/5 - Save Provision State
# ==================================================

Write-Host ""

Write-Host "Step 5/5 - Save Provision State (Skipped during DryRun)" `
-ForegroundColor Cyan


if($DryRun) {

    Write-Host ""
    
    Write-Host "DRY-RUN MODE - Provision state not saved" `
        -ForegroundColor Yellow


    Write-DeploymentLog `
        -Message "STEP 5/5 - Save provision state skipped because deployment is running in DRY-RUN mode." `
        -Level INFO `
        -Component "SYSTEM"


}
else {


    Write-DeploymentLog `
        -Message "STEP 5/5 - Save provision state started." `
        -Level INFO `
        -Component "SYSTEM"



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
        -Message "STEP 5/5 - Save provision state completed." `
        -Level PASS `
        -Component "SYSTEM"

}

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

    Write-DeploymentLog `
        -Message $_.Exception.Message `
        -Level ERROR `
        -Component "SYSTEM"

    Write-Host $_.Exception.Message `
        -ForegroundColor Red

    exit 1

}