# ==================================================
# Enterprise Entra ID Graph Module
#
# Purpose:
# Provides Microsoft Graph connectivity,
# authentication handling and directory caching.
#
# Functions:
# - Connect-Graph
# - Initialize-GraphCache
# - Get-CurrentTenant
#
# Version:
# 1.0.0
# ==================================================

# ==================================================
# Connect-Graph
#
# Connects to Microsoft Graph using the selected
# authentication method and validates permissions.
# ==================================================

function Connect-EntraGraph {


    param(

        [ValidateSet(
            "Interactive",
            "DeviceCode",
            "Certificate"
        )]

        [string]
        $AuthenticationMode = "Interactive",


        [string]
        $TenantId,


        [string]
        $ClientId,


        [string]
        $CertificateThumbprint

    )



    Write-Host ""

    Write-Message `
        -Status "INFO" `
        -Message "Checking Microsoft Graph connection..." `
        -Component "GRAPH"


    # ==================================================
    # Required modules
    # ==================================================

    $RequiredModules = @(

        "Microsoft.Graph.Authentication"

        "Microsoft.Graph.Users"

        "Microsoft.Graph.Groups"

        "Microsoft.Graph.Identity.SignIns"

    )



    foreach ($Module in $RequiredModules) {


        if (
            -not (
                Get-Module `
                    -ListAvailable `
                    -Name $Module
            )
        ) {

            throw "Required module '$Module' is not installed."

        }


        Import-Module `
            $Module `
            -ErrorAction Stop

    }



    # ==================================================
    # Required permissions
    # ==================================================

    $RequiredScopes = @(

        "User.ReadWrite.All"

        "Group.ReadWrite.All"

        "Policy.ReadWrite.AuthenticationMethod"

        "Policy.ReadWrite.ConditionalAccess"

        "Policy.Read.All"

        "Directory.ReadWrite.All"

        "RoleManagement.Read.Directory"

    )



    try {


        $Context =
        Get-MgContext



        if ($null -ne $Context) {


            Write-Message `
                -Status "PASS" `
                -Message "Existing Microsoft Graph connection found. Reusing current session." `
                -Component "GRAPH"

        }

        else {


            Write-Message `
                -Status "INFO" `
                -Message "No existing Microsoft Graph connection found." `
                -Component "GRAPH"



            switch ($AuthenticationMode) {


                "Interactive" {


                    Write-Message `
                        -Status "INFO" `
                        -Message "Using interactive authentication..." `
                        -Component "GRAPH"



                    Connect-MgGraph `
                        -Scopes $RequiredScopes `
                        -NoWelcome


                }



                "DeviceCode" {


                    Write-Message `
                        -Status "INFO" `
                        -Message "Using device code authentication..." `
                        -Component "GRAPH"



                    Connect-MgGraph `
                        -Scopes $RequiredScopes `
                        -UseDeviceAuthentication `
                        -NoWelcome


                }



                "Certificate" {


                    if (
                        [string]::IsNullOrWhiteSpace($TenantId)
                    ) {

                        throw `
                            "TenantId is required for certificate authentication."

                    }


                    if (
                        [string]::IsNullOrWhiteSpace($ClientId)
                    ) {

                        throw `
                            "ClientId is required for certificate authentication."

                    }


                    if (
                        [string]::IsNullOrWhiteSpace($CertificateThumbprint)
                    ) {

                        throw `
                            "CertificateThumbprint is required."

                    }



                    Write-Message `
                        -Status "INFO" `
                        -Message "Using certificate authentication..." `
                        -Component "GRAPH"


                    Connect-MgGraph `
                        -TenantId $TenantId `
                        -ClientId $ClientId `
                        -CertificateThumbprint $CertificateThumbprint `
                        -NoWelcome



                }


            }


        }



        $Context =
        Get-MgContext



        if ($null -eq $Context) {

            throw "Microsoft Graph connection failed."

        }



        Write-Host ""

        Write-Message `
            -Status "PASS" `
            -Message "Microsoft Graph connection and permissions validated." `
            -Component "GRAPH"


        Write-Host `
            "Tenant ID   : $($Context.TenantId)"


        Write-Host `
            "Account     : $($Context.Account)"


        Write-Host `
            "Environment : $($Context.Environment)"



        foreach ($Scope in $RequiredScopes) {


            if (
                $Context.Scopes `
                    -notcontains $Scope
            ) {

                throw `
                    "Missing Microsoft Graph permission: $Scope"

            }


        }


    # ==================================================
    # Tenant context
    # ==================================================

    $TenantContext =
    Get-CurrentTenant


    Write-Message `
        -Status "PASS" `
        -Message (
            "Tenant context available. TenantId: {0}" `
            -f `
            $TenantContext.TenantId
        ) `
        -Component "GRAPH"



    $script:GraphContext =
    $Context


    }
    catch {


        Write-Message `
            -Status "ERROR" `
            -Message $_.Exception.Message `
            -Component "GRAPH"



        throw


    }



}



# ==================================================
# Initialize-GraphCache
#
# Loads users and groups from Microsoft Graph
# into memory for reuse during provisioning.
# ==================================================

function Initialize-GraphCache {

    param(

        [switch]$Silent,

        [switch]$Refresh

    )


    $GraphUsers = @(
        Get-MgUser `
            -All `
            -Property `
            Id,
            DisplayName,
            UserPrincipalName
    )


    $GraphGroups = @(
        Get-MgGroup `
            -All `
            -Property `
            Id,
            DisplayName
    )


    if ($Refresh) {

        $Message =
            "Graph cache refreshed. Users: $($GraphUsers.Count), Groups: $($GraphGroups.Count)"

        $Level = "INFO"

    }
    else {

        $Message =
            "Graph cache loaded. Users: $($GraphUsers.Count), Groups: $($GraphGroups.Count)"

        $Level = "PASS"

    }


    if ($Refresh -and $Silent) {

        return @{

            Users  = $GraphUsers
            Groups = $GraphGroups

        }

    }


    if (-not $Silent) {

        Write-Host ""

        if ($Refresh) {

            Write-Message `
                -Status "INFO" `
                -Message $Message `
                -Component "GRAPH"

        }
        else {

            Write-Message `
                -Status "PASS" `
                -Message $Message `
                -Component "GRAPH"

        }

    }





    return @{

        Users  = $GraphUsers

        Groups = $GraphGroups

    }

}

# ==================================================
# Get-CurrentTenant
# ==================================================

function Get-CurrentTenant {

    $Context = Get-MgContext


    if($null -eq $Context){

        throw "No Microsoft Graph connection available."

    }


    return @{

        TenantId = $Context.TenantId

        Account = $Context.Account

        Environment = $Context.Environment

    }

}


# ==================================================
# Export
# ==================================================

Export-ModuleMember -Function @(
    "Connect-EntraGraph",
    "Initialize-GraphCache",
    "Get-CurrentTenant"
)