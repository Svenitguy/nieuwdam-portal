# ============================================================
# New-CA003-RequireMFAUsers
#
# Requires MFA for all users.
#
# Excludes configured break-glass accounts.
# ============================================================

function New-CA003-RequireMFAUsers {

    [CmdletBinding()]
    param(

        [switch]
        $DryRun,

        [object]
        $BreakGlassConfiguration

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message "Would create CA003 - Require MFA Users excluding configured break-glass accounts." `
            -Component "SECURITY"

        return

    }


    try {

        $ExistingPolicy =
            Get-MgIdentityConditionalAccessPolicy `
                -ErrorAction Stop |
            Where-Object {

                $_.DisplayName -eq
                "CA003 - Require MFA Users"

            }


        if($ExistingPolicy){

            Write-Message `
                -Status "PASS" `
                -Message "Conditional Access policy already exists: CA003 - Require MFA Users." `
                -Component "SECURITY"

            return

        }


        # --------------------------------------------------------
        # Break-glass exclusions
        # --------------------------------------------------------

        if(
            $null -eq $BreakGlassConfiguration.ObjectIds -or
            $BreakGlassConfiguration.ObjectIds.Count -eq 0
        ){

            throw `
                "No break-glass account object IDs are available. CA003 will not be created."

        }

        $BreakGlassAccounts = @(
            $BreakGlassConfiguration.ObjectIds
        )


        Write-Message `
            -Status "INFO" `
            -Message (
                "Configuring CA003 with {0} break-glass account exclusions." `
                -f `
                $BreakGlassAccounts.Count
            ) `
            -Component "SECURITY"


        $PolicyBody = @{

            displayName =
                "CA003 - Require MFA Users"


            state =
                "enabled"


            conditions = @{

                users = @{

                    includeUsers = @(
                        "All"
                    )

                    excludeUsers =
                        $BreakGlassAccounts

                }

            }


            grantControls = @{

                operator =
                    "OR"

                builtInControls = @(
                    "mfa"
                )

            }

        }


        New-MgIdentityConditionalAccessPolicy `
            -BodyParameter $PolicyBody `
            -ErrorAction Stop


        Write-Message `
            -Status "PASS" `
            -Message "Created CA003 - Require MFA Users." `
            -Component "SECURITY"


    }
    catch {

        Write-Message `
            -Status "ERROR" `
            -Message $_.Exception.Message `
            -Component "SECURITY"

        throw

    }

}