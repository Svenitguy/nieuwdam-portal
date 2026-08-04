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
# Confirm-LiveDeployment
#
# Requires explicit confirmation before modifying
# Microsoft Entra ID tenant.
# ==================================================

function Confirm-LiveDeployment {

    param(

        [Parameter(Mandatory)]
        [string[]]
        $Operations

    )


    $Tenant = Get-CurrentTenant


    Write-Host ""

    Write-Host "================================================" `
        -ForegroundColor Yellow

    Write-Host " LIVE DEPLOYMENT WARNING" `
        -ForegroundColor Yellow

    Write-Host "================================================" `
        -ForegroundColor Yellow

    Write-Host ""


    Write-Host "Tenant ID : $($Tenant.TenantId)"

    if($Tenant.Account){

        Write-Host "Account   : $($Tenant.Account)"

    }


    Write-Host ""

    Write-Host "The following operations will be performed:"

    Write-Host ""


    foreach($Operation in $Operations){

        Write-Host " - $Operation"

    }


    Write-Host ""

    Write-Host "This operation will modify your Microsoft Entra ID tenant."

    Write-Host ""

    Write-Host "This operation cannot be automatically rolled back."

    Write-Host ""


    $Confirmation =
        Read-Host "Type DEPLOY to continue"


    if($Confirmation -ne "DEPLOY"){

        throw "Deployment cancelled by user."

    }


    Write-Host ""

    Write-Host "Deployment confirmed." `
        -ForegroundColor Green

}

# ==================================================
# Export Functions
# ==================================================

Export-ModuleMember -Function @(
    "Get-ResultCount",
    "Write-ProvisioningSummary",
    "Confirm-LiveDeployment"
)