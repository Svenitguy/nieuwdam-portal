#Requires -Version 5.1

<#
.SYNOPSIS
    Saves the current provisioned Microsoft Entra ID state.

.DESCRIPTION
    Reads the objects that currently exist in Microsoft Entra ID and
    saves them to a timestamped provision-state JSON file. 
    This state file is later used by the deprovisioning script
    to safely remove only provisioned objects.

.NOTES

    Project :
        Entra ID Provisioning Framework

    Script :
        05 - save-provision-state

    Version :
        3.0.0

#>

[CmdletBinding()]
param(

    [string]
    $DeploymentLogFile,

    [string]
    $RunId,

    [Parameter()]
    [switch]
    $UseExistingGraphConnection

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

$StatePath =
    Join-Path `
        $RootPath `
        "state"


if(!(Test-Path $StatePath)) {

    New-Item `
        -Path $StatePath `
        -ItemType Directory |
        Out-Null

}


$Timestamp =
    Get-Date -Format "yyyy-MM-dd_HH-mm-ss"


$StateFile =
    Join-Path `
        $StatePath `
        "provision-state-$Timestamp.json"

# ==================================================
# Import modules
# ==================================================

$RequiredModules = @(

    "$ModulePath\Logging\Logging.psm1"

    "$ModulePath\Graph\Graph.psm1"

    "$ModulePath\Helpers\Helpers.psm1"

    "$ModulePath\Configuration\Configuration.psm1"

)

foreach($Module in $RequiredModules){

    if(!(Test-Path $Module)){

        throw "Required PowerShell module file not found: $Module"

    }

    Import-Module `
        $Module

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

Initialize-Logging `
    -LogFolder $LogPath `
    -LogName "save-provision-state" `
    -DeploymentLogFile $DeploymentLogFile

Write-Logging `
    -Message "Save Provision State started. RunId: $RunId" `
    -Level INFO `
    -Component SYSTEM

try {

    # ==================================================
    # Connect Graph
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

    Write-Host ""
    Write-Host "Connected to Microsoft Graph."
    Write-Host ""

    # ==================================================
    # Load current Entra ID state
    # ==================================================

    Write-Host "Loading current Entra ID state..."

    $DirectoryCache =
        Initialize-GraphCache

    # ==================================================
    # Build lookup indexes
    # ==================================================

    $UserLookup = @{}

    foreach($User in $DirectoryCache.Users){

        if(
            $User.PSObject.Properties.Name -contains "UserPrincipalName"
        ){

            if(
                ![string]::IsNullOrWhiteSpace($User.UserPrincipalName)
            ){

                $UserLookup[$User.UserPrincipalName] = $User

            }

        }

    }

    $GroupLookup = @{}


    foreach($Group in $DirectoryCache.Groups){

        if(
            $Group.PSObject.Properties.Name -contains "DisplayName"
        ){

            if(
                ![string]::IsNullOrWhiteSpace($Group.DisplayName)
            ){

                $GroupLookup[$Group.DisplayName] = $Group

            }

        }

    }

    $ConfiguredUsers =
        Get-UserConfiguration `
            -ConfigFolder $ConfigPath


    $ConfiguredGroups =
        Get-GroupConfiguration `
            -ConfigFolder $ConfigPath

    Write-Logging `
        -Message (
            "Configuration loaded. Users: {0}, Groups: {1}" -f `
            @($ConfiguredUsers).Count,
            @($ConfiguredGroups).Count
        ) `
        -Level INFO `
        -Component SYSTEM

    $UserIndex = 0
    $TotalUsers = @($ConfiguredUsers).Count


    $Users =
    @(
        foreach($ConfigUser in $ConfiguredUsers) {


            $UserIndex++


            Write-Progress `
                -Activity "Loading users" `
                -Status "$UserIndex / $TotalUsers - $($ConfigUser.UserName)" `
                -PercentComplete (($UserIndex / $TotalUsers) * 100)


            if(
                $ConfigUser.PSObject.Properties.Name -contains "UserName"
            ){

                if(
                    $UserLookup.ContainsKey($ConfigUser.UserName)
                ){

                    $UserLookup[$ConfigUser.UserName]

                }

            }

        }
    )

    Write-Progress `
        -Activity "Loading users" `
        -Completed

    if(
    @($Users).Count -ne @($ConfiguredUsers).Count
    ){

        Write-Logging `
            -Message (
                "User count mismatch. Configured: {0}, Found: {1}" -f `
                @($ConfiguredUsers).Count,
                @($Users).Count
            ) `
            -Level WARN `
            -Component VALIDATION

    }

    $GroupIndex = 0
    $TotalGroups = @($ConfiguredGroups).Count


    $Groups =
    @(
        foreach($ConfigGroup in $ConfiguredGroups){

            $GroupIndex++


            Write-Progress `
                -Activity "Loading groups" `
                -Status "$GroupIndex / $TotalGroups - $($ConfigGroup.DisplayName)" `
                -PercentComplete (($GroupIndex / $TotalGroups) * 100)


            if(
                $GroupLookup.ContainsKey($ConfigGroup.DisplayName)
            ){

                $GroupLookup[$ConfigGroup.DisplayName]

            }

        }
    )


    Write-Progress `
        -Activity "Loading groups" `
        -Completed

    if(
    @($Groups).Count -ne @($ConfiguredGroups).Count
    ){

        Write-Logging `
            -Message (
                "Group count mismatch. Configured: {0}, Found: {1}" -f `
                @($ConfiguredGroups).Count,
                @($Groups).Count
            ) `
            -Level WARN `
            -Component VALIDATION

    }

    Write-Logging `
        -Message (
            "Managed objects loaded. Users: {0}, Groups: {1}" -f `
            @($Users).Count,
            @($Groups).Count
        ) `
        -Level INFO `
        -Component SYSTEM

    $Memberships =
        [System.Collections.ArrayList]::new()

    $GroupNumber = 0
    $TotalGroups = @($Groups).Count

    foreach($Group in $Groups) {

        $GroupNumber++

        Write-Progress `
            -Activity "Reading group memberships" `
            -Status "$GroupNumber / $TotalGroups - $($Group.DisplayName)" `
            -PercentComplete (($GroupNumber / $TotalGroups) * 100)

        Write-Logging `
            -Message (
                "Reading memberships {0}/{1}: {2}" -f `
                $GroupNumber,
                $TotalGroups,
                $Group.DisplayName
            ) `
            -Level INFO `
            -Component GRAPH

        if(!$Group.Id){

            continue

        }

        $Members =
            Get-MgGroupMember `
                -GroupId $Group.Id `
                -All `
                -Property Id

        Write-Logging `
            -Message (
                "Members found for {0}: {1}" -f `
                $Group.DisplayName,
                @($Members).Count
            ) `
            -Level INFO `
            -Component GRAPH

        foreach($Member in $Members) {


            [void]$Memberships.Add(

                [PSCustomObject]@{

                    GroupId =
                        $Group.Id

                    GroupName =
                        $Group.DisplayName

                    MemberId =
                        $Member.Id

                    MemberType =
                        $Member.AdditionalProperties.'@odata.type'


                }

            )

        }

    }

    Write-Progress `
        -Activity "Reading group memberships" `
        -Completed

$ProvisionState =
[PSCustomObject]@{


    RunId =
        $RunId


    TenantId =
        (Get-MgContext).TenantId


    FrameworkVersion =
        "3.0.0"


    ScriptVersion =
        "3.0.0"


    DeploymentStatus =
        "VALIDATED"


    Environment =
        (Get-MgContext).Environment


    Created =
        (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")


    Counts =
    [PSCustomObject]@{

        Users =
            @($Users).Count

        Groups =
            @($Groups).Count

        Memberships =
            $Memberships.Count

    }


    Users =
        @(
            $Users |
            Select-Object `
                Id,
                UserPrincipalName,
                DisplayName
        )


    Groups =
        @(
            $Groups |
            Select-Object `
                Id,
                DisplayName
        )


    Memberships =
        @(
            $Memberships
        )

}

    if(Test-Path $StateFile){

        throw "State file already exists: $StateFile"

    }

    $ProvisionState |
    ConvertTo-Json `
        -Depth 10 |
    Set-Content `
        -Path $StateFile `
        -Encoding UTF8

    Write-Logging `
        -Message (
            "Provision state saved successfully. Users: {0}, Groups: {1}, Memberships: {2}" -f `
            @($Users).Count,
            @($Groups).Count,
            $Memberships.Count
        ) `
        -Level PASS `
        -Component SYSTEM


    Write-RunCompleted `
        -StartTime $ScriptStartTime `
        -RunId $RunId `
        -Processed (
            @($Users).Count +
            @($Groups).Count +
            $Memberships.Count
        )

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host " Provision state saved successfully" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host $StateFile -ForegroundColor Cyan
    Write-Host ""

    Write-Logging `
        -Message "Provision state file path: $StateFile" `
        -Level INFO `
        -Component SYSTEM

    return [PSCustomObject]@{

        RunId = $RunId

        StateFile = $StateFile

        Users = @($Users).Count

        Groups = @($Groups).Count

        Memberships = $Memberships.Count

    }

}

catch {

    Write-Logging `
        -Message $_.Exception.Message `
        -Level ERROR `
        -Component SYSTEM

    throw

}