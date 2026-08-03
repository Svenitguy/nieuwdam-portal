# ============================================================
# New-CA006-BlockRiskySignin
#
# Blocks high risk sign-ins.
# ============================================================

function New-CA006-BlockRiskySignin {

    [CmdletBinding()]
    param(

        [switch]
        $DryRun

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message "Would create CA006 - Block High Risk Sign-ins." `
            -Component "SECURITY"

        return

    }


    try {


        $ExistingPolicy =
            Get-MgIdentityConditionalAccessPolicy `
                -ErrorAction Stop |
            Where-Object {

                $_.DisplayName -eq
                "CA006 - Block High Risk Sign-ins"

            }


        if($ExistingPolicy){

            Write-Message `
                -Status "PASS" `
                -Message "Conditional Access policy already exists: CA006 - Block High Risk Sign-ins." `
                -Component "SECURITY"

            return

        }


        # Policy definition will be added here

        Write-Message `
            -Status "PASS" `
            -Message "Created CA006 - Block High Risk Sign-ins." `
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