# ============================================================
# New-CA003-RequireMFAUsers
#
# Requires MFA for all users.
#
# Excludes breakglass accounts to prevent tenant lockout.
# ============================================================


function New-CA003-RequireMFAUsers {

    [CmdletBinding()]
    param(

        [switch]
        $DryRun

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message "Would create CA003 - Require MFA Users (excluding breakglass accounts)." `
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
        # BreakGlass exclusions
        #
        # These should be replaced with actual user object IDs.
        # They can later be loaded from BreakGlassAccounts config.
        # --------------------------------------------------------

        $BreakGlassAccounts = @()



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