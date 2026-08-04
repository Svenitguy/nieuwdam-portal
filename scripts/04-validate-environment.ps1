#Requires -Version 5.1

<#
.SYNOPSIS
    Validates a Microsoft Entra ID environment.

.DESCRIPTION
    Validates users, groups and group memberships
    against the configured Microsoft Entra ID environment.

    Generates CSV and HTML validation reports.

.EXAMPLE
    .\04-validate-environment.ps1

    Validates the Microsoft Entra ID environment
    and generates validation reports.

.NOTES

    Project :
        Entra ID Provisioning Framework

    Script :
        04 - validate-environment

    Version :
        3.0.0

#>


[CmdletBinding()]

param(

    [Parameter()]
    [switch]
    $DryRun,

    [string]$DeploymentLogFile,

    [string]$RunId,

    [Parameter()]
    [switch]
    $PassThru,

    [Parameter()]
    [switch]
    $UseExistingGraphConnection,

    [switch]
    $UseExistingGraphCache

)

# ==================================================
# PowerShell settings
# ==================================================

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"



# ==================================================
# Paths
# ==================================================

$RootFolder =
    Split-Path `
        -Path $PSScriptRoot `
        -Parent


$ModuleRoot =
    Join-Path `
        $RootFolder `
        "modules"


$ConfigFolder =
    Join-Path `
        $RootFolder `
        "config"


$LogFolder =
    Join-Path `
        $RootFolder `
        "logs"

$ReportFolder =
    Join-Path `
        $RootFolder `
        "reports"


if (!(Test-Path $ReportFolder)) {

    New-Item `
        -Path $ReportFolder `
        -ItemType Directory |
        Out-Null

}


# ==================================================
# Import modules
# ==================================================

$RequiredModules = @(

    "$ModuleRoot\Logging\Logging.psm1"

    "$ModuleRoot\Configuration\Configuration.psm1"

    "$ModuleRoot\Graph\Graph.psm1"

    "$ModuleRoot\Validation\Validation.psm1"

    "$ModuleRoot\Reporting\Reporting.psm1"

)

foreach($Module in $RequiredModules){

    if(!(Test-Path $Module)){

        throw `
            "Required PowerShell module file not found: $Module"

    }

    Import-Module `
        $Module

}

# ==================================================
# Initialize Run Tracking
# ==================================================

if ([string]::IsNullOrWhiteSpace($RunId)) {

    $RunId = [guid]::NewGuid().ToString()

}

$ScriptStartTime = Get-Date



# ==================================================
# Initialize Logging
# ==================================================

Initialize-Logging `
    -LogFolder $LogFolder `
    -LogName "validation" `
    -DeploymentLogFile $DeploymentLogFile



Write-Logging `
    -Message "Validation started. RunId: $RunId" `
    -Level "INFO" `
    -Component "SYSTEM"


# ==================================================
# Load Configuration
# ==================================================

$Config = [PSCustomObject]@{

    Users =
        Get-UserConfiguration `
            -ConfigFolder $ConfigFolder

    Groups =
        Get-GroupConfiguration `
            -ConfigFolder $ConfigFolder

    Memberships =
        Get-MembershipConfiguration `
            -ConfigFolder $ConfigFolder

    Tenant =
        Get-TenantConfiguration `
            -ConfigFolder $ConfigFolder

}



$TotalMemberships =
    (
        $Config.Memberships |
        ForEach-Object {
            $_.Groups.Count
        } |
        Measure-Object -Sum
    ).Sum


Write-Logging `
    -Message "Configuration loaded. Users: $($Config.Users.Count), Groups: $($Config.Groups.Count), Membership assignments: $TotalMemberships." `
    -Level PASS `
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
# Initialize Graph Cache
# ==================================================

$GraphCache =
    Initialize-GraphCache


Write-Logging `
    -Message "Graph cache initialized successfully. Users: $($GraphCache.Users.Count), Groups: $($GraphCache.Groups.Count)." `
    -Level PASS `
    -Component "SYSTEM"

Write-Logging `
    -Message "==============================================" `
    -Level INFO `
    -Component "SYSTEM"

Write-Logging `
    -Message "STEP 1/3 - Validating users" `
    -Level INFO `
    -Component "SYSTEM"

Write-Logging `
    -Message "==============================================" `
    -Level INFO `
    -Component "SYSTEM"


# ==================================================
# Run Validation
# ==================================================

$ValidationResults = @()


$UserResults =
    Test-Users `
        -ConfigUsers $Config.Users `
        -GraphUsers $GraphCache.Users


$ValidationResults += $UserResults


$UserPassed =
    @(
        $UserResults |
        Where-Object {
            $_.Status -eq "PASS"
        }
    ).Count


$UserFailed =
    @(
        $UserResults |
        Where-Object {
            $_.Status -eq "FAIL"
        }
    ).Count


Write-Logging `
    -Message "User validation completed. Checked: $($UserResults.Count), Passed: $UserPassed, Failed: $UserFailed." `
    -Level PASS `
    -Component "SYSTEM"

Write-Logging `
    -Message "==============================================" `
    -Level INFO `
    -Component "SYSTEM"

Write-Logging `
    -Message "STEP 2/3 - Validating groups" `
    -Level INFO `
    -Component "SYSTEM"

Write-Logging `
    -Message "==============================================" `
    -Level INFO `
    -Component "SYSTEM"   

$GroupResults =
    Test-Groups `
        -ConfigGroups $Config.Groups `
        -GraphGroups $GraphCache.Groups


$ValidationResults += $GroupResults


$GroupPassed =
    @(
        $GroupResults |
        Where-Object {
            $_.Status -eq "PASS"
        }
    ).Count


$GroupFailed =
    @(
        $GroupResults |
        Where-Object {
            $_.Status -eq "FAIL"
        }
    ).Count


Write-Logging `
    -Message "Group validation completed. Checked: $($GroupResults.Count), Passed: $GroupPassed, Failed: $GroupFailed." `
    -Level PASS `
    -Component "SYSTEM"

Write-Logging `
    -Message "==============================================" `
    -Level INFO `
    -Component "SYSTEM"

Write-Logging `
    -Message "STEP 3/3 - Validating group memberships" `
    -Level INFO `
    -Component "SYSTEM"

Write-Logging `
    -Message "==============================================" `
    -Level INFO `
    -Component "SYSTEM"

$MembershipResults =
    Test-Memberships `
        -ConfigMemberships $Config.Memberships `
        -GraphUsers $GraphCache.Users `
        -GraphGroups $GraphCache.Groups


$ValidationResults += $MembershipResults


$MembershipPassed =
    @(
        $MembershipResults |
        Where-Object {
            $_.Status -eq "PASS"
        }
    ).Count


$MembershipFailed =
    @(
        $MembershipResults |
        Where-Object {
            $_.Status -eq "FAIL"
        }
    ).Count


Write-Logging `
    -Message "Membership validation completed. Checked: $($MembershipResults.Count), Passed: $MembershipPassed, Failed: $MembershipFailed." `
    -Level PASS `
    -Component "SYSTEM"

foreach ($Result in $ValidationResults) {

    $Result | Add-Member `
        -MemberType NoteProperty `
        -Name RunId `
        -Value $RunId `
        -Force

}
    

# ==================================================
# Validation Output
# ==================================================

Write-Host ""

Write-Host "Validation Results" `
    -ForegroundColor Cyan

if (!$PassThru) {

    $ValidationResults |
        Format-Table `
            -AutoSize

}


# ==================================================
# Validation Summary
# ==================================================

$Total =
    $ValidationResults.Count


$Passed =
    @(
        $ValidationResults |
        Where-Object {
            $_.Status -eq "PASS"
        }
    ).Count


$Failed =
    @(
        $ValidationResults |
        Where-Object {
            $_.Status -eq "FAIL"
        }
    ).Count



Write-Host ""

Write-Host "==============================================" `
    -ForegroundColor Cyan

Write-Host " Validation Summary" `
    -ForegroundColor Cyan

Write-Host "==============================================" `
    -ForegroundColor Cyan


Write-Host "Total checks : $Total"

Write-Host "Passed       : $Passed" `
    -ForegroundColor Green

Write-Host "Failed       : $Failed" `
    -ForegroundColor Red

Write-Logging `
    -Message "==============================================" `
    -Level INFO `
    -Component "SYSTEM"

Write-Logging `
    -Message "Validation Summary" `
    -Level INFO `
    -Component "SYSTEM"

Write-Logging `
    -Message "==============================================" `
    -Level INFO `
    -Component "SYSTEM"
 
Write-Logging `
    -Message "Validation summary. Total checks: $Total, Passed: $Passed, Failed: $Failed." `
    -Level PASS `
    -Component "SYSTEM"


# ==================================================
# Reports
# ==================================================

$Report =
    New-ValidationReport `
        -Results $ValidationResults `
        -OutputFolder $ReportFolder `
        -RunId $RunId `
        -TenantName $Config.Tenant.TenantName

Write-Logging `
    -Message "CSV report generated. RunId: $RunId File: $($Report.Csv)" `
    -Level PASS `
    -Component "SYSTEM"

Write-Logging `
    -Message "HTML report generated. RunId: $RunId File: $($Report.Html)" `
    -Level PASS `
    -Component "SYSTEM"

# ==================================================
# Validation Duration
# ==================================================

$EndTime = Get-Date

$Duration =
    New-TimeSpan `
        -Start $ScriptStartTime `
        -End $EndTime

Write-Logging `
    -Message "Validation duration: $([math]::Round($Duration.TotalSeconds,2)) seconds. RunId: $RunId" `
    -Level INFO `
    -Component "SYSTEM"

$ValidationResult = [PSCustomObject]@{

    TotalChecks = $Total
    Passed = $Passed
    Failed = $Failed

    RunId = $RunId

    ReportCsv  = $Report.Csv
    ReportHtml = $Report.Html

}

# ==================================================
# Exit Code
# ==================================================

<#if ($Failed -gt 0) {

    # Log every failed validation in detail

    $FailedItems =
        $ValidationResults |
        Where-Object {
            $_.Status -eq "FAIL"
        }


    foreach ($Failure in $FailedItems) {

        Write-Logging `
            -Message "$($Failure.Type) failed: $($Failure.Name) - $($Failure.Message)" `
            -Level ERROR `
            -Component "SYSTEM"

    }


    Write-Logging `
        -Message "Validation failed with $Failed errors." `
        -Level ERROR `
        -Component "SYSTEM"


    Write-RunCompleted `
        -StartTime $ScriptStartTime `
        -RunId $RunId `
        -Processed $ValidationResults.Count


    return $ValidationResult

}


else {

    Write-Logging `
        -Message "Validation completed successfully." `
        -Level PASS `
        -Component "SYSTEM"

}


Write-RunCompleted `
    -StartTime $ScriptStartTime `
    -RunId $RunId `
    -Processed $ValidationResults.Count


if ($PassThru) {

    Write-Output $ValidationResult

}#>

if ($Failed -gt 0) {


    $FailedItems =
        $ValidationResults |
        Where-Object {
            $_.Status -eq "FAIL"
        }


    foreach ($Failure in $FailedItems) {

        Write-Logging `
            -Message "$($Failure.Type) failed: $($Failure.Name) - $($Failure.Message)" `
            -Level ERROR `
            -Component "SYSTEM"

    }


    Write-Logging `
        -Message "Validation failed with $Failed errors." `
        -Level ERROR `
        -Component "SYSTEM"


    Write-RunCompleted `
        -StartTime $ScriptStartTime `
        -RunId $RunId `
        -Processed $ValidationResults.Count


}
else {


    Write-Logging `
        -Message "Validation completed successfully." `
        -Level PASS `
        -Component "SYSTEM"


}


Write-RunCompleted `
    -StartTime $ScriptStartTime `
    -RunId $RunId `
    -Processed $ValidationResults.Count


if ($PassThru) {

    return $ValidationResult

}