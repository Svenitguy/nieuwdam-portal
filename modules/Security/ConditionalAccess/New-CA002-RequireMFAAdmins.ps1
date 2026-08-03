# ============================================================
# New-CA002-RequireMFAAdmins
#
# Requires MFA for administrative roles.
# ============================================================

function New-CA002-RequireMFAAdmins {

    [CmdletBinding()]
    param(

        [switch]
        $DryRun

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message "Would create CA002 - Require MFA Administrators." `
            -Component "SECURITY"

        return

    }



    try {


        $ExistingPolicy =
            Get-MgIdentityConditionalAccessPolicy `
                -ErrorAction Stop |
            Where-Object {

                $_.DisplayName -eq 
                "CA002 - Require MFA Administrators"

            }



        if($ExistingPolicy){

            Write-Message `
                -Status "PASS" `
                -Message "Conditional Access policy already exists: CA002 - Require MFA Administrators." `
                -Component "SECURITY"

            return

        }



        $PolicyBody = @{

            displayName =
                "CA002 - Require MFA Administrators"


            state =
                "enabled"


            conditions = @{

                users = @{

                    includeRoles = @(

                        "62e90394-69f5-4237-9190-012177145e10"

                    )

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
            -Message "Created CA002 - Require MFA Administrators." `
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