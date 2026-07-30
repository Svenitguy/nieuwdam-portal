#Requires -Version 5.1

<#
.SYNOPSIS
    Performs controlled deprovisioning of Microsoft Entra ID resources.

.DESCRIPTION
    This script removes Microsoft Entra ID objects created by the
    Nieuwdam Identity Provisioning Framework.

    The deprovisioning workflow follows a controlled lifecycle:
    1. Load provisioning state
    2. Validate managed objects
    3. Remove memberships
    4. Remove groups
    5. Remove users
    6. Generate execution summary

    Features:
    - Dry-run execution mode
    - Protected account exclusion
    - Idempotent cleanup
    - Microsoft Graph integration
    - Execution tracking
    - Detailed logging

.PARAMETER DryRun
    Simulates cleanup without removing objects.

.PARAMETER PassThru
    Returns cleanup summary object.

.NOTES

    Project :
        Entra ID Provisioning Framework

    Script :
        06 - deprovision-environment

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
    $ConfirmDelete,

    [string]
    $DeploymentLogFile,


    [Parameter()]
    [switch]
    $PassThru,


    [string]
    $RunId,

    [Parameter()]
    [string]
    $StateFile

)

$ProtectedUsers = @(
    "admin@nieuwdam.onmicrosoft.com",
    "sven.velleman_svenitguy.be#EXT#@nieuwdam.onmicrosoft.com"
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
        $Module

}

# ==================================================
# Initialize Logging
# ==================================================

Initialize-Logging `
    -LogFolder $LogPath `
    -LogName "deprovision" `
    -DeploymentLogFile $DeploymentLogFile

# ==================================================
# Determine state file
# ==================================================

if(
    [string]::IsNullOrWhiteSpace($StateFile)
){

    $StateFolder =
        Join-Path `
            $RootPath `
            "state"

    $StateFile =
        Get-ChildItem `
            -Path $StateFolder `
            -Filter "provision-state-*.json" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 |
        Select-Object -ExpandProperty FullName

    if($null -eq $StateFile){

        throw "No state file found in '$StateFolder'."

    }

}

if(!(Test-Path $StateFile)){

    throw "State file not found: $StateFile"

}


# ==================================================
# Initialize Run
# ==================================================

if([string]::IsNullOrWhiteSpace($RunId)){

    $RunId =
        [guid]::NewGuid().ToString()

}


$ScriptStartTime =
    Get-Date



# ==================================================
# Logging
# ==================================================

Write-Host ""
Write-Host "Using state file:"
Write-Host $StateFile
Write-Host ""

Write-Logging `
    -Message "Using state file: $StateFile" `
    -Level INFO `
    -Component SYSTEM

Write-Logging `
    -Message "Deprovisioning started. RunId: $RunId, DryRun: $($DryRun.IsPresent)" `
    -Level INFO `
    -Component SYSTEM

$ProvisionState =
    Get-Content `
        -Path $StateFile `
        -Raw |
    ConvertFrom-Json

if($null -eq $ProvisionState){

    throw "Invalid state file: File could not be loaded."

}


# ==================================================
# Validate state file
# ==================================================

$RequiredStateProperties = @(
    "Users",
    "Groups",
    "Memberships"
)


foreach($Property in $RequiredStateProperties){

    if(
        $null -eq $ProvisionState.$Property
    ){

        throw "Invalid state file: Required property '$Property' missing."

    }

}

Write-Logging `
    -Message (
        "Provision state loaded. Managed Users: {0}, Managed Groups: {1}, Managed Memberships: {2}" -f `
        $ProvisionState.Users.Count,
        $ProvisionState.Groups.Count,
        $ProvisionState.Memberships.Count
    ) `
    -Level PASS `
    -Component SYSTEM

try {

if(
    !$DryRun -and
    !$ConfirmDelete
){

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Yellow
    Write-Host " DELETE MODE NOT ENABLED" -ForegroundColor Yellow
    Write-Host "==============================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "No objects were removed."
    Write-Host ""
    Write-Host "To perform the cleanup, run the script with:"
    Write-Host ""
    Write-Host " -ConfirmDelete"
    Write-Host ""

    return

}


# ==================================================
# Connect Graph
# ==================================================

Connect-EntraGraph



# ==================================================
# Load configuration
# ==================================================

$CleanupUsers =
    $ProvisionState.Users


$CleanupGroups =
    $ProvisionState.Groups


$CleanupMemberships =
    $ProvisionState.Memberships

Write-Logging `
    -Message "Cleanup targets loaded. Users: $($CleanupUsers.Count), Groups: $($CleanupGroups.Count), Memberships: $($CleanupMemberships.Count)." `
    -Level PASS `
    -Component DEPROVISION


# ==================================================
# Graph Cache
# ==================================================

$GraphCache =
    Initialize-GraphCache

$UserLookup =
    @{}

foreach($User in $GraphCache.Users){

    $UserLookup[$User.UserPrincipalName] =
        $User

}


$GroupLookup =
    @{}

foreach($Group in $GraphCache.Groups){

    $GroupLookup[$Group.DisplayName] =
        $Group

}

Write-Logging `
    -Message (
        "Current Entra ID inventory loaded. Existing Users: {0}, Existing Groups: {1}" -f `
        $GraphCache.Users.Count,
        $GraphCache.Groups.Count
    ) `
    -Level PASS `
    -Component GRAPH

if($DryRun){

    Write-Logging `
        -Message "Running in DRY-RUN mode. No objects will be removed." `
        -Level WARNING `
        -Component SYSTEM

}


Write-Host ""
Write-Host "=============================================="
Write-Host " Nieuwdam Municipality Identity Cleanup"
Write-Host " Microsoft Entra ID Deprovision Framework"
Write-Host "=============================================="
Write-Host ""

Write-Host "Run ID:"
Write-Host $RunId

Write-Host ""

Write-Host "Mode:"
if($DryRun){

    Write-Host "DRY RUN - No objects removed"

}
else{

    Write-Host "DELETE MODE - Objects removed"

}

Write-Host ""

Write-Host "Environment cleanup plan"
Write-Host "------------------------"

Write-Host "Users       : $($CleanupUsers.Count)"
Write-Host "Groups      : $($CleanupGroups.Count)"
Write-Host "Memberships : $($CleanupMemberships.Count)"

Write-Host ""

# ==================================================
# Cleanup memberships
# ==================================================

Write-Logging `
    -Message "Starting membership cleanup. Total memberships: $($CleanupMemberships.Count)" `
    -Level INFO `
    -Component DEPROVISION



$MembershipRemoved = 0
$MembershipSkipped = 0
$MembershipPlanned = 0
$MembershipFailed  = 0


$MembershipIndex = 0

$TotalMemberships =
    $CleanupMemberships.Count

Write-Host ""
Write-Host "Starting membership cleanup..."
Write-Host "Total memberships to process: $TotalMemberships"
Write-Host ""

foreach($Membership in $CleanupMemberships){


    $MembershipIndex++


    Write-Progress `
        -Activity "Removing Group Memberships" `
        -Status "$MembershipIndex / $TotalMemberships : $($Membership.GroupName)" `
        -PercentComplete (($MembershipIndex / $TotalMemberships) * 100)



    Write-Message `
        -Status INFO `
        -Message (
            "[$MembershipIndex/$TotalMemberships] Processing membership: {0} -> {1}" `
            -f `
            $Membership.MemberId,
            $Membership.GroupName
        ) `
        -Component DEPROVISION



    if($DryRun){

        $ExistingGroup =
            $GroupLookup[$Membership.GroupName]

        if($null -eq $ExistingGroup){

            Write-Message `
                -Status SKIPPED `
                -Message (
                    "Membership already removed: {0} -> {1}" `
                    -f `
                    $Membership.MemberId,
                    $Membership.GroupName
                ) `
                -Component DEPROVISION

            $MembershipSkipped++

        }
        else{

            Write-Message `
                -Status DRYRUN `
                -Message (
                    "Would remove membership: {0} -> {1}" `
                    -f `
                    $Membership.MemberId,
                    $Membership.GroupName
                ) `
                -Component DEPROVISION

            $MembershipPlanned++

        }

        continue

    }


    try {

        $ExistingGroup =
            $GroupLookup[$Membership.GroupName]


        if($null -eq $ExistingGroup){

            Write-Message `
                -Status SKIPPED `
                -Message "Group already removed: $($Membership.GroupName)" `
                -Component DEPROVISION

            $MembershipSkipped++

            continue

        }


        try {

            $CurrentMembers =
                Get-MgGroupMember `
                    -GroupId $ExistingGroup.Id `
                    -All

        }
        catch {

            if(
                $_.Exception.Message -match "ResourceNotFound"
            ){

                Write-Message `
                    -Status SKIPPED `
                    -Message (
                        "Group no longer exists: {0}" `
                        -f `
                        $Membership.GroupName
                    ) `
                    -Component DEPROVISION


            $MembershipSkipped++

            continue

            }


            Write-Message `
                -Status ERROR `
                -Message (
                    "Failed reading membership: {0} -> {1}. Error: {2}" `
                    -f `
                    $Membership.MemberId,
                    $Membership.GroupName,
                    $_.Exception.Message
                ) `
                -Component DEPROVISION


            $MembershipFailed++

            continue

        }


        if(
            $CurrentMembers.Id -notcontains $Membership.MemberId
        ){

            Write-Message `
                -Status SKIPPED `
                -Message (
                    "Membership already absent: {0} -> {1}" `
                    -f `
                    $Membership.MemberId,
                    $Membership.GroupName
                ) `
                -Component DEPROVISION


            $MembershipSkipped++

            continue

        }

        Remove-MgGroupMemberByRef `
            -GroupId $ExistingGroup.Id `
            -DirectoryObjectId $Membership.MemberId `
            -Confirm:$false



        Write-Message `
            -Status PASS `
            -Message (
                "Removed membership: {0} -> {1}" `
                -f `
                $Membership.MemberId,
                $Membership.GroupName
            ) `
            -Component DEPROVISION



        $MembershipRemoved++


    }

    catch {


        Write-Message `
            -Status ERROR `
            -Message (
                "Failed removing membership: {0} -> {1}. Error: {2}" `
                -f `
                $Membership.MemberId,
                $Membership.GroupName,
                $_.Exception.Message
            ) `
            -Component DEPROVISION


        $MembershipFailed++


    }


}

Write-Progress `
    -Activity "Removing Group Memberships" `
    -Completed

# ==================================================
# Cleanup groups
# ==================================================

$GroupsRemoved = 0
$GroupsPlanned = 0
$GroupsSkipped = 0
$GroupsFailed  = 0

$GroupIndex = 0
$TotalGroups = $CleanupGroups.Count

Write-Host ""
Write-Host "Membership cleanup completed."
Write-Host ""
Write-Host "Starting group cleanup..."
Write-Host "Total groups to process: $TotalGroups"
Write-Host ""

foreach($Group in $CleanupGroups){

    $GroupIndex++

    Write-Progress `
        -Activity "Removing Groups" `
        -Status "$GroupIndex / $TotalGroups : $Group" `
        -PercentComplete (($GroupIndex / $TotalGroups) * 100)

    Write-Message `
        -Status INFO `
        -Message "[$GroupIndex/$TotalGroups] Processing group: $($Group.DisplayName)" `
        -Component DEPROVISION

    $ExistingGroup =
        $GroupLookup[$Group.DisplayName]

    if($DryRun){

        if($null -eq $ExistingGroup){

            Write-Message `
                -Status SKIPPED `
                -Message "Group already removed: $($Group.DisplayName)" `
                -Component DEPROVISION

            $GroupsSkipped++

        }
        else{

            Write-Message `
                -Status DRYRUN `
                -Message "Would remove group: $($Group.DisplayName)" `
                -Component DEPROVISION

            $GroupsPlanned++

        }

    }

    else {

        if($null -eq $ExistingGroup){

            Write-Message `
                -Status SKIPPED `
                -Message "Group already removed: $($Group.DisplayName)" `
                -Component DEPROVISION

            $GroupsSkipped++

            continue

        }


        try {


            Remove-MgGroup `
                -GroupId $ExistingGroup.Id `
                -Confirm:$false


            Write-Message `
                -Status PASS `
                -Message "Removed group: $($Group.DisplayName)" `
                -Component DEPROVISION


            $GroupsRemoved++


        }

        catch {


            Write-Message `
                -Status ERROR `
                -Message "Failed removing group: $($Group.DisplayName). Error: $($_.Exception.Message)" `
                -Component DEPROVISION


            $GroupsFailed++


        }

    }

}

Write-Progress `
    -Activity "Removing Groups" `
    -Completed

# ==================================================
# Cleanup users
# ==================================================

$UsersRemoved = 0
$UsersPlanned = 0
$UsersSkipped = 0
$UsersFailed  = 0

$UserIndex = 0
$TotalUsers = $CleanupUsers.Count

Write-Host ""
Write-Host "Group cleanup completed."
Write-Host ""
Write-Host "Starting user cleanup..."
Write-Host "Total users to process: $TotalUsers"
Write-Host ""

foreach($UserConfig in $CleanupUsers){

    $UserIndex++

    Write-Progress `
        -Activity "Removing Users" `
        -Status "$UserIndex / $TotalUsers : $($UserConfig.UserPrincipalName)" `
        -PercentComplete (($UserIndex / $TotalUsers) * 100)

    Write-Message `
        -Status INFO `
        -Message "[$UserIndex/$TotalUsers] Processing user: $($UserConfig.UserPrincipalName)" `
        -Component DEPROVISION

    $ExistingUser =
        $UserLookup[$UserConfig.UserPrincipalName]

    if($null -eq $ExistingUser){

        Write-Message `
            -Status SKIPPED `
            -Message "User already removed: $($UserConfig.UserPrincipalName)" `
            -Component DEPROVISION

        $UsersSkipped++

        continue

    }


    if($ProtectedUsers -contains $ExistingUser.UserPrincipalName){

        Write-Message `
            -Status SKIPPED `
            -Message "Protected user skipped: $($ExistingUser.UserPrincipalName)" `
            -Component SECURITY

        $UsersSkipped++

        continue

    }


    if($DryRun){

        Write-Message `
            -Status DRYRUN `
            -Message "Would remove user: $($ExistingUser.UserPrincipalName)" `
            -Component DEPROVISION


        $UsersPlanned++

    }

    else {

        try {


            Remove-MgUser `
                -UserId $ExistingUser.Id `
                -Confirm:$false


            Write-Message `
                -Status PASS `
                -Message "Removed user: $($ExistingUser.UserPrincipalName)" `
                -Component DEPROVISION


            $UsersRemoved++


        }

        catch {


            Write-Message `
                -Status ERROR `
                -Message "Failed removing user: $($ExistingUser.UserPrincipalName). Error: $($_.Exception.Message)" `
                -Component DEPROVISION


            $UsersFailed++


        }

    }


}

Write-Progress `
    -Activity "Removing Users" `
    -Completed

Write-Host ""
Write-Host "User cleanup completed."
Write-Host ""

# ==================================================
# Execution timing
# ==================================================

$ScriptEndTime =
    Get-Date

$ExecutionDuration =
    New-TimeSpan `
        -Start $ScriptStartTime `
        -End $ScriptEndTime

Write-Host ""
Write-Host "Mode"
Write-Host "----"

if($DryRun){

    Write-Host "DRY RUN - No objects removed"

}
else{

    Write-Host "DELETE MODE - Objects removed"

}

# ==================================================
# Summary
# ==================================================

$CleanupResult = [PSCustomObject]@{


    RunId = $RunId


    MembershipsRemoved = $MembershipRemoved

    GroupsRemoved = $GroupsRemoved

    UsersRemoved = $UsersRemoved


    MembershipsPlanned = $MembershipPlanned

    GroupsPlanned = $GroupsPlanned

    UsersPlanned = $UsersPlanned


    MembershipsSkipped = $MembershipSkipped

    GroupsSkipped = $GroupsSkipped

    UsersSkipped = $UsersSkipped


    MembershipsFailed = $MembershipFailed

    GroupsFailed = $GroupsFailed

    UsersFailed = $UsersFailed

}

Write-Host ""

Write-Host "=============================================="
Write-Host " Deprovision Summary"
Write-Host "=============================================="

Write-Host ""
Write-Host "Memberships"
Write-Host "------------"
Write-Host "Removed : $MembershipRemoved"
Write-Host "Planned : $MembershipPlanned"
Write-Host "Skipped : $MembershipSkipped"
Write-Host "Failed  : $MembershipFailed"

Write-Host ""
Write-Host "Groups"
Write-Host "------"
Write-Host "Removed : $GroupsRemoved"
Write-Host "Planned : $GroupsPlanned"
Write-Host "Skipped : $GroupsSkipped"
Write-Host "Failed  : $GroupsFailed"

Write-Host ""
Write-Host "Users"
Write-Host "-----"
Write-Host "Removed : $UsersRemoved"
Write-Host "Planned : $UsersPlanned"
Write-Host "Skipped : $UsersSkipped"
Write-Host "Failed  : $UsersFailed"

Write-Host ""

Write-Host ""
Write-Host "Execution"
Write-Host "---------"
Write-Host "Started : $ScriptStartTime"
Write-Host "Finished: $ScriptEndTime"
Write-Host ("Duration: {0:hh}h:{0:mm}m:{0:ss}s.{0:fff}ms" -f $ExecutionDuration)
Write-Host ""

Write-Logging `
    -Message (
        "Cleanup completed. Removed Users: {0}, Removed Groups: {1}, Removed Memberships: {2}, Skipped Users: {3}, Skipped Groups: {4}, Skipped Memberships: {5}, Failed: {6}, DryRun: {7}" `
        -f `
        $UsersRemoved,
        $GroupsRemoved,
        $MembershipRemoved,
        $UsersSkipped,
        $GroupsSkipped,
        $MembershipSkipped,
        ($UsersFailed + $GroupsFailed + $MembershipFailed),
        $DryRun.IsPresent
    ) `
    -Level PASS `
    -Component SYSTEM



Write-RunCompleted `
    -StartTime $ScriptStartTime `
    -RunId $RunId `
    -Processed (
        $CleanupUsers.Count +
        $CleanupGroups.Count +
        $TotalMemberships
    )


if($PassThru){

    return $CleanupResult

}


}


catch {


    Write-Logging `
    -Message (
        "Fatal error during deprovisioning. Error: {0}" -f `
        $_.Exception.Message
    ) `
    -Level ERROR `
    -Component SYSTEM


    throw

}