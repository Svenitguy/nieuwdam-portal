# ==================================================
# Enterprise Entra ID Provisioning Module
#
# Purpose:
# Provides user, group and membership provisioning
# functions for Microsoft Entra ID.
#
# Functions:
# - New-EntraUsers
# - New-EntraGroups
# - Add-EntraGroupMembers
#
# Version:
# 1.0.0
# ==================================================

# ==================================================
# New-EntraUsers
# ==================================================

function New-EntraUsers {

    param(

        [Parameter(Mandatory)]
        [array]$ConfigUsers,

        [Parameter(Mandatory)]
        [array]$GraphUsers,

        [Parameter(Mandatory)]
        [string]$InitialPassword,

        [switch]$DryRun

    )

    $Results = [System.Collections.ArrayList]::new()

    if ($DryRun) {

        Write-Logging `
            -Message "User provisioning running in DryRun mode. No changes will be applied." `
            -Level "WARNING" `
            -Component "PROVISIONING"

}

    #===============================================
    # Create fast user lookup table
    #===============================================

    $UserLookup = [System.Collections.Hashtable]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($GraphUser in $GraphUsers) {

        $UserLookup[$GraphUser.UserPrincipalName] = $GraphUser

    }


    #===============================================
    # Required properties
    #===============================================

    $RequiredProperties = @(
        "DisplayName",
        "FirstName",
        "LastName",
        "UserName",
        "Department",
        "JobTitle",
        "EmployeeId",
        "OfficeLocation",
        "City",
        "Country",
        "AccountType"
    )

    $TotalUsers = $ConfigUsers.Count
    $CurrentUser = 0

    Write-Host ""
    Write-Host "Starting user provisioning..." -ForegroundColor Cyan
    Write-Host "Total users to process: $TotalUsers"
    Write-Host ""

    Write-Logging `
        -Message "Starting user provisioning. Total users: $TotalUsers" `
        -Level "INFO" `
        -Component "PROVISIONING"

    foreach ($User in $ConfigUsers) {

        $CurrentUser++

        Write-Progress `
            -Activity "Creating Entra Users" `
            -Status "$CurrentUser / $TotalUsers : $($User.UserName)" `
            -PercentComplete (($CurrentUser / $TotalUsers) * 100)

        Write-Host ""
        Write-Host "[$CurrentUser/$TotalUsers] $($User.UserName)" -ForegroundColor Cyan
        Write-Logging `
            -Message "[$CurrentUser/$TotalUsers] Processing user: $($User.UserName)" `
            -Level "INFO" `
            -Component "PROVISIONING"

        $MissingProperties = @()

        foreach ($Property in $RequiredProperties) {

            if ([string]::IsNullOrWhiteSpace($User.$Property)) {

                $MissingProperties += $Property

            }

        }

        # Toegevoegd 21-07-2026 16:16 Begin
        if ($MissingProperties.Count -gt 0) {


            Write-Host `
                "       FAILED - Missing required properties" `
                -ForegroundColor Red


            [void]$Results.Add(
                [PSCustomObject]@{

                    Timestamp = Get-Date

                    Type      = "User"

                    Name      =
                    if ($User.UserName) {
                        $User.UserName
                    }
                    else {
                        "Unknown"
                    }

                    Action    = "Failed"

                    Message   =
                    "Missing required properties: $($MissingProperties -join ', ')"

                }
            )

            Write-Logging `
                -Message "Validation failed for $($User.UserName): Missing $($MissingProperties -join ', ')" `
                -Level "ERROR" `
                -Component "PROVISIONING"

            continue

        }
        # Toegevoegd 21-07-2026 16:16 Einde

        $ExistingUser =
        $UserLookup[$User.UserName]

        if ($ExistingUser) {

            Write-Host "       SKIPPED - User already exists" -ForegroundColor Yellow

            Write-Logging `
                -Message "User already exists: $($User.UserName)" `
                -Level "SKIPPED" `
                -Component "PROVISIONING"

            [void]$Results.Add(
                [PSCustomObject]@{

                    Timestamp = Get-Date

                    Type      = "User"

                    Name      = $User.UserName

                    Action    = "Skipped"

                    Message   = "User already exists"

                }
            )

            continue

        }

        if ($DryRun) {

            Write-Host "       WOULD CREATE" -ForegroundColor Magenta

            Write-Logging `
                -Message "WOULD CREATE - User: $($User.UserName)" `
                -Level "DRYRUN" `
                -Component "PROVISIONING"

            [void]$Results.Add(
                [PSCustomObject]@{

                    Timestamp = Get-Date
                    Type      = "User"
                    Name      = $User.UserName
                    Action    = "WouldCreate"
                    Message   = "DryRun - User creation planned"

                }
            )

            continue

        }

        try {

            $null = New-MgUser `
                -AccountEnabled:$true `
                -DisplayName $User.DisplayName `
                -MailNickname ($User.UserName.Split("@")[0]) `
                -UserPrincipalName $User.UserName `
                -JobTitle $User.JobTitle `
                -Department $User.Department `
                -EmployeeId $User.EmployeeId `
                -OfficeLocation $User.OfficeLocation `
                -City $User.City `
                -Country $User.Country `
                -UserType $User.AccountType `
                -PasswordProfile @{
                Password                      = $InitialPassword
                ForceChangePasswordNextSignIn = $true
            } 

            Write-Host "       CREATED SUCCESSFULLY" -ForegroundColor Green

            Write-Logging `
                -Message "CREATED - User: $($User.UserName)" `
                -Level "PASS" `
                -Component "PROVISIONING"

            $NewUser = Get-MgUser `
                -UserId $User.UserName

            $UserLookup[$User.UserName] = $NewUser

            [void]$Results.Add(
                [PSCustomObject]@{

                    Timestamp         = Get-Date
                    Type              = "User"
                    Name              = $User.UserName
                    ObjectId          = $NewUser.Id
                    UserPrincipalName = $NewUser.UserPrincipalName
                    Action            = "Created"
                    Message           = "User created successfully"

                }
            )

        }
        catch {

            Write-Host "       FAILED - $($_.Exception.Message)" -ForegroundColor Red

            Write-Logging `
                -Message "FAILED - User: $($User.UserName) - $($_.Exception.Message)" `
                -Level "ERROR" `
                -Component "PROVISIONING"

            [void]$Results.Add(
                [PSCustomObject]@{

                    Timestamp = Get-Date
                    Type      = "User"
                    Name      = $User.UserName
                    Action    = "Failed"
                    Message   = $_.Exception.Message

                }
            )

        }

    }

    Write-Progress `
        -Activity "Creating Entra Users" `
        -Completed

    return @($Results)

}


# ==================================================
# New-EntraGroups
# ==================================================

function New-EntraGroups {

    param(

        [Parameter(Mandatory)]
        [object[]]$ConfigGroups,

        [Parameter()]
        [object[]]$GraphGroups = @(),

        [switch]$DryRun

    )

    $Results = [System.Collections.ArrayList]::new()

    if ($DryRun) {

        Write-Logging `
            -Message "Group provisioning running in DryRun mode. No changes will be applied." `
            -Level "WARNING" `
            -Component "PROVISIONING"

    }

    $GroupLookup = [System.Collections.Hashtable]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($GraphGroup in $GraphGroups) {

        $GroupLookup[$GraphGroup.DisplayName] = $GraphGroup

    }

    $TotalGroups = $ConfigGroups.Count
    $CurrentGroup = 0

    Write-Host ""
    Write-Host "Starting group provisioning..." -ForegroundColor Cyan
    Write-Host "Total groups to process: $TotalGroups"
    Write-Host ""

    Write-Logging `
        -Message "Starting group provisioning. Total groups: $TotalGroups" `
        -Level "INFO" `
        -Component "PROVISIONING"

    foreach ($Group in $ConfigGroups) {

        $CurrentGroup++

        Write-Progress `
            -Activity "Creating Entra Groups" `
            -Status "$CurrentGroup / $TotalGroups : $($Group.DisplayName)" `
            -PercentComplete (($CurrentGroup / $TotalGroups) * 100)

        Write-Host ""
        Write-Host "[$CurrentGroup/$TotalGroups] $($Group.DisplayName)" -ForegroundColor Cyan

        Write-Logging `
            -Message "[$CurrentGroup/$TotalGroups] Processing group: $($Group.DisplayName)" `
            -Level "INFO" `
            -Component "PROVISIONING"

    $ExistingGroup =

        $GroupLookup[$Group.DisplayName]

        if ($ExistingGroup) {

            Write-Host "       SKIPPED - Group already exists" -ForegroundColor Yellow

            Write-Logging `
                -Message "Group already exists: $($Group.DisplayName)" `
                -Level "SKIPPED" `
                -Component "PROVISIONING"

            [void]$Results.Add(
                [PSCustomObject]@{

                    Timestamp = Get-Date
                    Type      = "Group"
                    Name      = $Group.DisplayName
                    Action    = "Skipped"
                    Message   = "Group already exists"

                }
            )

            continue

        }

        if ($DryRun) {

            Write-Host "       WOULD CREATE" -ForegroundColor Magenta

            Write-Logging `
                -Message "WOULD CREATE - Group: $($Group.DisplayName)" `
                -Level "DRYRUN" `
                -Component "PROVISIONING"

            [void]$Results.Add(
                [PSCustomObject]@{

                    Timestamp = Get-Date
                    Type      = "Group"
                    Name      = $Group.DisplayName
                    Action    = "WouldCreate"
                    Message   = "DryRun - Group would be created"

                }
            )

            continue

        }

        try {


            $NewGroup =
            New-MgGroup `
                -DisplayName $Group.DisplayName `
                -Description $Group.Description `
                -MailEnabled:$Group.MailEnabled `
                -MailNickname $Group.MailNickname `
                -SecurityEnabled:$Group.SecurityEnabled `
                -GroupTypes @()

            Write-Host "       CREATED SUCCESSFULLY" -ForegroundColor Green

            Write-Logging `
                -Message "CREATED - Group: $($Group.DisplayName)" `
                -Level "PASS" `
                -Component "PROVISIONING"

            $NewGroup =
            Get-MgGroup `
                -Filter "displayName eq '$($Group.DisplayName)'"

            [void]$Results.Add(
                [PSCustomObject]@{

                    Timestamp       = Get-Date
                    Type            = "Group"
                    Name            = $Group.DisplayName
                    ObjectId        = $NewGroup.Id
                    DisplayName     = $NewGroup.DisplayName
                    MailNickname    = $NewGroup.MailNickname
                    Action          = "Created"
                    Message         = "Group created"

                }
            )

        }
        catch {

            Write-Host "       FAILED - $($_.Exception.Message)" -ForegroundColor Red

            Write-Logging `
                -Message "FAILED - Group: $($Group.DisplayName) - $($_.Exception.Message)" `
                -Level "ERROR" `
                -Component "PROVISIONING"

            [void]$Results.Add(
                [PSCustomObject]@{

                    Timestamp = Get-Date
                    Type      = "Group"
                    Name      = $Group.DisplayName
                    Action    = "Failed"
                    Message   = $_.Exception.Message

                }
            )

        }

    }

    Write-Progress `
        -Activity "Creating Entra Groups" `
        -Completed

    return @($Results)

}


# ==================================================
# Add-EntraGroupMembers
# ==================================================

function Add-EntraGroupMembers {

    param(

        [Parameter(Mandatory)]
        [array]$MembershipConfig,

        [Parameter()]
        [array]$GraphUsers = @(),

        [Parameter()]
        [array]$GraphGroups = @(),

        [switch]$DryRun

    )


    $Results =
        [System.Collections.ArrayList]::new()


    # ==================================================
    # Lookup tables
    # ==================================================

    $UserLookup =
        [System.Collections.Hashtable]::new(
            [System.StringComparer]::OrdinalIgnoreCase
        )


    foreach($GraphUser in $GraphUsers){

        $UserLookup[$GraphUser.UserPrincipalName] =
            $GraphUser

    }



    $GroupLookup =
        [System.Collections.Hashtable]::new(
            [System.StringComparer]::OrdinalIgnoreCase
        )


    foreach($GraphGroup in $GraphGroups){

        $GroupLookup[$GraphGroup.DisplayName] =
            $GraphGroup

    }



    # ==================================================
    # Cache existing group members
    # ==================================================

    $GroupMembersLookup = @{}

    $TotalGroups = $GraphGroups.Count
    $CurrentGroup = 0

    foreach ($GraphGroup in $GraphGroups) {

        $CurrentGroup++

        Write-Progress `
            -Activity "Loading existing group memberships" `
            -Status "$CurrentGroup / $TotalGroups : Reading members of $($GraphGroup.DisplayName)" `
            -PercentComplete (($CurrentGroup / $TotalGroups) * 100)

        $Members = Get-MgGroupMember `
            -GroupId $GraphGroup.Id `
            -All `
            -Property Id

        $GroupMembersLookup[$GraphGroup.Id] = @($Members.Id)

    }  

    Write-Progress `
        -Activity "Loading existing group memberships" `
        -Completed


    # ==================================================
    # Calculate total memberships
    # ==================================================

    $TotalEntries =
        (
            $MembershipConfig |
            ForEach-Object {

                $_.Groups.Count

            } |
            Measure-Object -Sum
        ).Sum



    $CurrentEntry = 0



    Write-Logging `
        -Message "Starting membership provisioning. Total memberships: $TotalEntries" `
        -Level "INFO" `
        -Component "PROVISIONING"



    # ==================================================
    # Process memberships
    # ==================================================

    foreach($Entry in $MembershipConfig){


        foreach($GroupName in $Entry.Groups){


            $CurrentEntry++


            $MembershipName =
                "$($Entry.UserName) -> $GroupName"



            Write-Progress `
                -Activity "Adding Group Memberships" `
                -Status "$CurrentEntry / $TotalEntries : $MembershipName" `
                -PercentComplete (($CurrentEntry / $TotalEntries) * 100)



            Write-Host ""

            Write-Host `
                "[$CurrentEntry/$TotalEntries] $MembershipName" `
                -ForegroundColor Cyan



            Write-Logging `
                -Message "[$CurrentEntry/$TotalEntries] Processing membership: $MembershipName" `
                -Level "INFO" `
                -Component "PROVISIONING"



            # ==================================================
            # Validate user
            # ==================================================

            <#$User =
                $UserLookup[$Entry.UserName]



            if(-not $User){


                Write-Host `
                    "       FAILED - User not found" `
                    -ForegroundColor Red



                Write-Logging `
                    -Message "FAILED - User not found: $($Entry.UserName)" `
                    -Level "ERROR" `
                    -Component "PROVISIONING"



                [void]$Results.Add(
                    [PSCustomObject]@{

                        Timestamp = Get-Date

                        Type = "Membership"

                        Name = $MembershipName

                        Action = "Failed"

                        Message = "User not found"

                    }
                )


                continue

            }



            # ==================================================
            # Validate group
            # ==================================================

            $Group =
                $GroupLookup[$GroupName]



            if(-not $Group){


                Write-Host `
                    "       FAILED - Group not found" `
                    -ForegroundColor Red



                Write-Logging `
                    -Message "FAILED - Group not found: $GroupName" `
                    -Level "ERROR" `
                    -Component "PROVISIONING"



                [void]$Results.Add(
                    [PSCustomObject]@{

                        Timestamp = Get-Date

                        Type = "Membership"

                        Name = $MembershipName

                        Action = "Failed"

                        Message = "Group not found"

                    }
                )


                continue

            }#>

            # ==================================================
            # Resolve objects
            # ==================================================

            $User =
                 $UserLookup[$Entry.UserName]


            $Group =
                $GroupLookup[$GroupName]



            # ==================================================
            # DryRun handling
            # ==================================================

            if($DryRun){


                Write-Host `
                    "       WOULD ADD" `
                    -ForegroundColor Magenta



                Write-Logging `
                    -Message "WOULD ADD MEMBER - $MembershipName" `
                    -Level "DRYRUN" `
                    -Component "PROVISIONING"



                [void]$Results.Add(
                    [PSCustomObject]@{

                        Timestamp = Get-Date

                        Type = "Membership"

                        Name = $MembershipName

                        Action = "WouldAdd"

                        Message = "DryRun - Membership would be created"

                    }
                )


                continue

            }



            # ==================================================
            # Validate objects (real run only)
            # ==================================================

            if(-not $User){


                Write-Host `
                    "       FAILED - User not found" `
                    -ForegroundColor Red


                [void]$Results.Add(
                    [PSCustomObject]@{

                        Timestamp = Get-Date

                        Type = "Membership"

                        Name = $MembershipName

                        Action = "Failed"

                        Message = "User not found"

                    }
                )


                continue

            }



            if(-not $Group){


                Write-Host `
                    "       FAILED - Group not found" `
                    -ForegroundColor Red


                [void]$Results.Add(
                    [PSCustomObject]@{

                        Timestamp = Get-Date

                        Type = "Membership"

                        Name = $MembershipName

                        Action = "Failed"

                        Message = "Group not found"

                    }
                )


                continue

            }



            # ==================================================
            # Already member
            # ==================================================

            if(
                $GroupMembersLookup[$Group.Id] -contains $User.Id
            ){


                Write-Host `
                    "       SKIPPED - Already member" `
                    -ForegroundColor Yellow



                Write-Logging `
                    -Message "Membership already exists: $MembershipName (already member)" `
                    -Level "SKIPPED" `
                    -Component "PROVISIONING"



                [void]$Results.Add(
                    [PSCustomObject]@{

                        Timestamp = Get-Date

                        Type = "Membership"

                        Name = $MembershipName

                        Action = "Skipped"

                        Message = "Already member"

                    }
                )


                continue

            }



            # ==================================================
            # DryRun
            # ==================================================

            <#if($DryRun){


                Write-Host `
                    "       WOULD ADD" `
                    -ForegroundColor Magenta



                Write-Logging `
                    -Message "WOULD ADD MEMBER - $MembershipName" `
                    -Level "DRYRUN" `
                    -Component "PROVISIONING"



                [void]$Results.Add(
                    [PSCustomObject]@{

                        Timestamp = Get-Date

                        Type = "Membership"

                        Name = $MembershipName

                        Action = "WouldAdd"

                        Message = "DryRun - Membership would be created"

                    }
                )


                continue

            }#>



            # ==================================================
            # Add membership
            # ==================================================

            try{


                $null =
                    New-MgGroupMemberByRef `
                        -GroupId $Group.Id `
                        -BodyParameter @{
                            
                            "@odata.id" =
                            "https://graph.microsoft.com/v1.0/directoryObjects/$($User.Id)"

                        }



                Write-Host `
                    "       ADDED" `
                    -ForegroundColor Green



                Write-Logging `
                    -Message "ADDED MEMBER - $MembershipName" `
                    -Level "PASS" `
                    -Component "PROVISIONING"



                $GroupMembersLookup[$Group.Id] +=
                    $User.Id



                [void]$Results.Add(
                    [PSCustomObject]@{

                        Timestamp         = Get-Date
                        Type              = "Membership"
                        Name              = $MembershipName
                        UserId            = $User.Id
                        UserPrincipalName = $User.UserPrincipalName
                        GroupId           = $Group.Id
                        GroupName         = $Group.DisplayName
                        Action            = "Added"
                        Message           = "Member added successfully"

                    }
                )


            }
            catch{


                Write-Host `
                    "       FAILED" `
                    -ForegroundColor Red



                Write-Logging `
                    -Message "FAILED ADD MEMBER - $MembershipName - $($_.Exception.Message)" `
                    -Level "ERROR" `
                    -Component "PROVISIONING"



                [void]$Results.Add(
                    [PSCustomObject]@{

                        Timestamp = Get-Date

                        Type = "Membership"

                        Name = $MembershipName

                        Action = "Failed"

                        Message = $_.Exception.Message

                    }
                )


            }


        }


    }



    Write-Progress `
        -Activity "Adding Group Memberships" `
        -Completed



    return @($Results)

}

function Get-ProvisionState {

    param(
        [string]$StateFile
    )


    if(!(Test-Path $StateFile)){

        throw "Provision state file not found: $StateFile"

    }


    return Get-Content `
        -Path $StateFile `
        -Raw |
        ConvertFrom-Json

}

# ==================================================
# Export
# ==================================================

Export-ModuleMember -Function @(
    "New-EntraUsers",
    "New-EntraGroups",
    "Add-EntraGroupMembers",
    "Get-ProvisionState"
)