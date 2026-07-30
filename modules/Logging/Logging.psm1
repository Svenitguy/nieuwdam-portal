# ==================================================
# Enterprise Logging Module
#
# Purpose:
# Provides centralized logging, status output,
# and run completion tracking.
#
# Functions:
# - Initialize-Logging
# - Write-Logging
# - Write-Status
# - Get-StatusColor
# - Write-Message
# - Write-RunCompleted
#
# Version:
# 1.0.0
# ==================================================

$script:LogFile = $null
$script:DeploymentLogFile = $null
$script:CurrentLogFile = $null

function Get-CurrentLogFile {

    return $script:LogFile

}

function Get-DeploymentLogFile {

    return $script:DeploymentLogFile

}


# ==================================================
# Initialize-Logging
# ==================================================

function Initialize-Logging {

param(

    [Parameter(Mandatory)]
    [string]
    $LogFolder,

    [Parameter()]
    [string]
    $LogName = "provisioning",

    [Parameter()]
    [string]
    $DeploymentLogFile

)


if (!(Test-Path $LogFolder)) {

    New-Item `
        -Path $LogFolder `
        -ItemType Directory `
        -Force |
        Out-Null

}


$LogFileName =
"{0}-{1}.log" -f `
    $LogName,
    (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")


$script:LogFile =
Join-Path `
    $LogFolder `
    $LogFileName


if($DeploymentLogFile){

    $script:DeploymentLogFile = $DeploymentLogFile

}
elseif($LogName -eq "deployment"){

    $script:DeploymentLogFile = $script:LogFile

}


New-Item `
    -Path $script:LogFile `
    -ItemType File `
    -Force |
    Out-Null


Write-Logging `
    -Message "Logging initialized." `
    -Level INFO `
    -Component "LOGGING"

}


# ==================================================
# Write-Logging
# ==================================================

function Write-Logging {


    param(

        [Parameter(Mandatory)]

        [string]
        $Message,


        [ValidateSet(

            "INFO",

            "PASS",

            "FAIL",

            "WARNING",

            "SKIPPED",

            "ERROR",

            "DRYRUN"

        )]

        [string]
        $Level = "INFO",


        [ValidateSet(

            "SYSTEM",
            "CONFIGURATION",
            "GRAPH",
            "HELPERS",
            "LOGGING",
            "PROVISIONING",
            "DEPROVISION",
            "REPORTING",
            "VALIDATION",
            "SECURITY",
            "AUDIT"

        )]

        [string]
        $Component = "SYSTEM"

    )



    if (
        $null -eq $script:LogFile
    ) {

        throw `
            "Logging has not been initialized."

    }

    # Ensure log file exists

    if (-not (Test-Path $script:LogFile)) {

        New-Item `
            -Path $script:LogFile `
            -ItemType File `
            -Force `
            | Out-Null

    }

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"


    $Entry =
    "$Timestamp [$Level] [$Component] $Message"

    $MaxAttempts = 3



    for (
        $Attempt = 1;
        $Attempt -le $MaxAttempts;
        $Attempt++
    ) {


        try {

            Add-Content -Path $script:LogFile `
                -Value $Entry `
                -Encoding UTF8 `
                -ErrorAction Stop


            return

        }

        catch {


            if (
                $Attempt -eq $MaxAttempts
            ) {


                Write-Warning `
                    "Unable to write log file after $MaxAttempts attempts: $($script:LogFile)"


            }

            else {


                Start-Sleep `
                    -Seconds ($Attempt * 2)


            }


        }


    }

}


# ==================================================
# Write-DeploymentLog
#
# Writes only to deployment log
# Prevents deployment messages appearing
# in module specific logs.
# ==================================================

function Write-DeploymentLog {

    param(

        [Parameter(Mandatory)]
        [string]
        $Message,

        [ValidateSet(
            "INFO",
            "PASS",
            "FAIL",
            "WARNING",
            "SKIPPED",
            "ERROR",
            "DRYRUN"
        )]
        [string]
        $Level = "INFO",

        [ValidateSet(
            "SYSTEM",
            "CONFIGURATION",
            "GRAPH",
            "HELPERS",
            "LOGGING",
            "PROVISIONING",
            "DEPROVISION",
            "REPORTING",
            "VALIDATION",
            "SECURITY",
            "AUDIT"
        )]
        [string]
        $Component = "SYSTEM"

    )


    if(-not $script:DeploymentLogFile){

        throw "Deployment log file not initialized."

    }


    $OriginalLogFile = $script:LogFile


    try {

        $script:LogFile = $script:DeploymentLogFile


        Write-Logging `
            -Message $Message `
            -Level $Level `
            -Component $Component

    }

    finally {

        $script:LogFile = $OriginalLogFile

    }

}

# ==================================================
# Write-Status
# ==================================================

function Write-Status {

    param(

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message

    )

    $Color =
        Get-StatusColor `
            -Status $Status

    Write-Host (
        "[{0}] {1}" -f $Status.ToUpper(), $Message
    ) `
    -ForegroundColor $Color

}

# ==================================================
# Get-StatusColor
# ==================================================

function Get-StatusColor {

    param(
        [string]$Status
    )


    switch ($Status.ToUpper()) {

        "PASS" {
            return "Green"
        }

        "FAIL" {
            return "Red"
        }

        "WARNING" {
            return "DarkYellow"
        }

        "INFO" {
            return "Cyan"
        }

        "SKIPPED" {
            return "Yellow"
        }

        "ERROR" {
            return "DarkRed"
        }

        "DRYRUN" {
            return "Magenta"
        }

        default {
            return "White"
        }

    }

}

# ==================================================
# Write-Message
# ==================================================

function Write-Message {

    param(

        [Parameter(Mandatory)]
        [ValidateSet(
            "INFO",
            "PASS",
            "FAIL",
            "WARNING",
            "SKIPPED",
            "ERROR",
            "DRYRUN"
        )]
        [string]
        $Status,


        [Parameter(Mandatory)]
        [string]
        $Message,


        [string]
        $Component = "SYSTEM"

    )


    Write-Status `
        -Status $Status `
        -Message $Message


    Write-Logging `
        -Level $Status `
        -Message $Message `
        -Component $Component

}


# ==================================================
# Write-RunCompleted
#
# Writes final execution status including:
# - RunId
# - Processed count
# - Total duration
# ==================================================

function Write-RunCompleted {

    param(

        [Parameter(Mandatory)]
        [datetime]
        $StartTime,

        [Parameter(Mandatory)]
        [string]
        $RunId,

        [Parameter(Mandatory)]
        [int]
        $Processed

    )


    $Duration =
        (Get-Date) - $StartTime


    $DurationFormatted =
        "{0:00}h:{1:00}m:{2:00}s.{3:000}ms" -f `
            $Duration.Hours,
            $Duration.Minutes,
            $Duration.Seconds,
            $Duration.Milliseconds


    Write-Logging `
        -Message (
            "Run completed. RunId: {0}. Processed: {1}. Duration: {2}" `
            -f `
            $RunId,
            $Processed,
            $DurationFormatted
        ) `
        -Level "PASS" `
        -Component "SYSTEM"

}

# ==================================================
# Export
# ==================================================

Export-ModuleMember `
-Function @(
    "Initialize-Logging",
    "Write-Logging",
    "Write-Status",
    "Write-Message",
    "Write-RunCompleted",
    "Get-CurrentLogFile",
    "Get-DeploymentLogFile",
    "Set-DeploymentLogMirroring",
    "Write-DeploymentLog"
)