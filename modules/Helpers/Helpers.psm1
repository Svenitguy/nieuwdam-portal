# ==================================================
# Enterprise Entra ID Helper Module
#
# Purpose:
# Provides reusable helper functions for
# provisioning summaries and result counting.
#
# Functions:
# - Get-ResultCount
# - Write-ProvisioningSummary
#
# Version:
# 1.0.0
# ==================================================

# ==================================================
# Get-ResultCount
#
# Returns the number of results matching
# the specified action.
# ==================================================

function Get-ResultCount {

    param(

        [Parameter(Mandatory)]
        [array]$Results,

        [Parameter(Mandatory)]
        [string]$Action

    )

    return @(
        $Results |
        Where-Object {
            $_.Action -eq $Action
        }
    ).Count

}


# ==================================================
# Write-ProvisioningSummary
#
# Displays a formatted provisioning summary
# in the console.
# ==================================================

function Write-ProvisioningSummary {

    param(

        [Parameter(Mandatory)]
        [string]
        $Title,


        [Parameter(Mandatory)]
        [hashtable]
        $Summary

    )


    Write-Host ""

    Write-Host `
        "==============================================" `
        -ForegroundColor Cyan


    Write-Host `
        " $Title" `
        -ForegroundColor Cyan


    Write-Host `
        "==============================================" `
        -ForegroundColor Cyan



    foreach ($Item in @(
        "Created",
        "Skipped",
        "Would Create",
        "Failed"
    )) {

        $Value = 0

        if ($Summary.ContainsKey($Item)) {

            $Value = $Summary[$Item]

        }

        Write-Host (
            "{0,-14}: {1}" -f
            $Item,
            $Value
        )

    }
}

# ==================================================
# Export Functions
# ==================================================

Export-ModuleMember -Function @(
    "Get-ResultCount",
    "Write-ProvisioningSummary"
)