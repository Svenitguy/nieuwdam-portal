# ==================================================
# Validation Module
# ==================================================

function New-ValidationResult {

    param(

        [string]$Type,

        [string]$Name,

        [string]$Status,

        [string]$Check,

        [string]$Expected,

        [string]$Actual,

        [string]$Message

    )

    [PSCustomObject]@{

        Timestamp = Get-Date

        Type      = $Type

        Name      = $Name

        Check     = $Check

        Status    = $Status

        Expected  = $Expected

        Actual    = $Actual

        Message   = $Message

    }

}

# ==================================================
# Validate Users
# ==================================================

function Test-Users {

    param(

        [Parameter(Mandatory)]
        [array]$ConfigUsers,

        [Parameter(Mandatory)]
        [array]$GraphUsers

    )

    $Results = [System.Collections.ArrayList]::new()

    # ==================================================
    # Create fast lookup table
    # ==================================================

    $UserLookup = [System.Collections.Hashtable]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($GraphUser in $GraphUsers) {

        $UserLookup[$GraphUser.UserPrincipalName] = $GraphUser

    }

    $TotalUsers = $ConfigUsers.Count
    $CurrentUser = 0

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host " Validating Users"
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "Total users to check: $TotalUsers"
    Write-Host ""

    foreach ($User in $ConfigUsers) {

        $CurrentUser++

        Write-Progress `
            -Activity "Validating Users" `
            -Status "$CurrentUser / $TotalUsers : $($User.UserName)" `
            -PercentComplete (($CurrentUser / $TotalUsers) * 100)

        $ExistingUser = $UserLookup[$User.UserName]

        if ($ExistingUser) {

            [void]$Results.Add(
                (New-ValidationResult `
                    -Type "User" `
                    -Name $User.UserName `
                    -Status "PASS" `
                    -Check "User existence" `
                    -Expected "Present" `
                    -Actual "Present" `
                    -Message "User exists")
            )

        }
        else {

            [void]$Results.Add(
                (New-ValidationResult `
                    -Type "User" `
                    -Name $User.UserName `
                    -Status "FAIL" `
                    -Check "User existence" `
                    -Expected "Present" `
                    -Actual "Missing" `
                    -Message "User missing")
            )

        }

    }

    Write-Progress `
        -Activity "Validating Users" `
        -Completed

    Write-Host ""
    Write-Host "User validation completed." -ForegroundColor Green

    return @($Results)

}
# ==================================================
# Validate Groups
# ==================================================

function Test-Groups {

    param(

        [Parameter(Mandatory)]
        [array]$ConfigGroups,

        [Parameter(Mandatory)]
        [array]$GraphGroups

    )


    $Results = [System.Collections.ArrayList]::new()


    # ==================================================
    # Create fast lookup table
    # ==================================================

    $GroupLookup = [System.Collections.Hashtable]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )


    foreach ($GraphGroup in $GraphGroups) {

        $GroupLookup[$GraphGroup.DisplayName] = $GraphGroup

    }


    $TotalGroups = $ConfigGroups.Count
    $CurrentGroup = 0


    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host " Validating Groups"
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "Total groups to check: $TotalGroups"
    Write-Host ""


    foreach ($Group in $ConfigGroups) {


        $CurrentGroup++


        Write-Progress `
            -Activity "Validating Groups" `
            -Status "$CurrentGroup / $TotalGroups : $($Group.DisplayName)" `
            -PercentComplete (($CurrentGroup / $TotalGroups) * 100)



        $ExistingGroup =
            $GroupLookup[$Group.DisplayName]



        if ($ExistingGroup) {


            [void]$Results.Add(
                (New-ValidationResult `
                    -Type "Group" `
                    -Name $Group.DisplayName `
                    -Status "PASS" `
                    -Check "Group existence" `
                    -Expected "Present" `
                    -Actual "Present" `
                    -Message "Group exists")
            )


        }
        else {


            [void]$Results.Add(
                (New-ValidationResult `
                    -Type "Group" `
                    -Name $Group.DisplayName `
                    -Status "FAIL" `
                    -Check "Group existence" `
                    -Expected "Present" `
                    -Actual "Missing" `
                    -Message "Group missing")
            )


        }


    }


    Write-Progress `
        -Activity "Validating Groups" `
        -Completed


    Write-Host ""
    Write-Host "Group validation completed." -ForegroundColor Green


    return @($Results)


}
# ==================================================
# Validate Memberships
# ==================================================

function Test-Memberships {

    param(

        [Parameter(Mandatory)]
        [array]$ConfigMemberships,

        [Parameter(Mandatory)]
        [array]$GraphUsers,

        [Parameter(Mandatory)]
        [array]$GraphGroups

    )


    $Results = [System.Collections.ArrayList]::new()



    # ==================================================
    # Create User Lookup
    # ==================================================

    $UserLookup = [System.Collections.Hashtable]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )


    foreach ($User in $GraphUsers) {

        $UserLookup[$User.UserPrincipalName] = $User

    }



    # ==================================================
    # Create Group Lookup
    # ==================================================

    $GroupLookup = [System.Collections.Hashtable]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )


    foreach ($Group in $GraphGroups) {

        $GroupLookup[$Group.DisplayName] = $Group

    }



    # ==================================================
    # Load membership cache
    # ==================================================

    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host " Loading Group Membership Cache"
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host ""


    $GroupMemberCache = [System.Collections.Hashtable]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )


    $TotalGroups = $GraphGroups.Count
    $CurrentGroup = 0


    foreach ($Group in $GraphGroups) {


        $CurrentGroup++


        Write-Progress `
            -Activity "Loading Group Members" `
            -Status "$CurrentGroup / $TotalGroups : $($Group.DisplayName)" `
            -PercentComplete (($CurrentGroup / $TotalGroups) * 100)



        try {

            $Members =
                Get-MgGroupMember `
                    -GroupId $Group.Id `
                    -All



            $GroupMemberCache[$Group.DisplayName] =
                @($Members.Id)


        }
        catch {


            $GroupMemberCache[$Group.DisplayName] =
                @()


        }


    }


    Write-Progress `
        -Activity "Loading Group Members" `
        -Completed


    Write-Host ""
    Write-Host "Membership cache loaded." -ForegroundColor Green
    Write-Host ""



    # ==================================================
    # Validate memberships
    # ==================================================

    $TotalMemberships = 0


    foreach ($Entry in $ConfigMemberships) {

        $TotalMemberships += $Entry.Groups.Count

    }


    $CurrentMembership = 0


    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host " Validating Memberships"
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "Total memberships to check: $TotalMemberships"
    Write-Host ""



    foreach ($Entry in $ConfigMemberships) {


        $User =
            $UserLookup[$Entry.UserName]



        foreach ($GroupName in $Entry.Groups) {


            $CurrentMembership++


            Write-Progress `
                -Activity "Validating Memberships" `
                -Status "$CurrentMembership / $TotalMemberships : $($Entry.UserName) -> $GroupName" `
                -PercentComplete (($CurrentMembership / $TotalMemberships) * 100)



            $MembershipName =
                "$($Entry.UserName) -> $GroupName"



            # ==================================================
            # Check user exists
            # ==================================================

            if (-not $User) {


                [void]$Results.Add(
                    (New-ValidationResult `
                        -Type "Membership" `
                        -Name $MembershipName `
                        -Status "FAIL" `
                        -Check "Membership assignment" `
                        -Expected "Assigned" `
                        -Actual "User missing" `
                        -Message "User does not exist")
                )


                continue

            }



            # ==================================================
            # Check group exists
            # ==================================================

            $Group =
                $GroupLookup[$GroupName]



            if (-not $Group) {


                [void]$Results.Add(
                    (New-ValidationResult `
                        -Type "Membership" `
                        -Name $MembershipName `
                        -Status "FAIL" `
                        -Check "Membership assignment" `
                        -Expected "Assigned" `
                        -Actual "Group missing" `
                        -Message "Group does not exist")
                )


                continue

            }



            # ==================================================
            # Check membership
            # ==================================================

            $Members =
                $GroupMemberCache[$GroupName]



            if ($Members -contains $User.Id) {


                [void]$Results.Add(
                    (New-ValidationResult `
                        -Type "Membership" `
                        -Name $MembershipName `
                        -Status "PASS" `
                        -Check "Membership assignment" `
                        -Expected "Assigned" `
                        -Actual "Assigned" `
                        -Message "Membership exists")
                )


            }
            else {


                [void]$Results.Add(
                    (New-ValidationResult `
                        -Type "Membership" `
                        -Name $MembershipName `
                        -Status "FAIL" `
                        -Check "Membership assignment" `
                        -Expected "Assigned" `
                        -Actual "Missing" `
                        -Message "Membership missing")
                )


            }


        }


    }


    Write-Progress `
        -Activity "Validating Memberships" `
        -Completed



    Write-Host ""
    Write-Host "Membership validation completed." -ForegroundColor Green


    return @($Results)

}

# ==================================================
# Export Validation Functions
# ==================================================

Export-ModuleMember `
    -Function @(
        "Test-Users",
        "Test-Groups",
        "Test-Memberships"
    )