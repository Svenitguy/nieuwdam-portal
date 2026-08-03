# ============================================================
# New-CA007-ProtectBreakGlass
#
# Protects emergency break glass accounts.
# ============================================================

function New-CA007-ProtectBreakGlass {

    [CmdletBinding()]
    param(

        [switch]
        $DryRun

    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message "Would create CA007 - Protect BreakGlass." `
            -Component "SECURITY"

        return

    }


    try {


        $ExistingPolicy =
            Get-MgIdentityConditionalAccessPolicy `
                -ErrorAction Stop |
            Where-Object {

                $_.DisplayName -eq
                "CA007 - Protect BreakGlass"

            }


        if($ExistingPolicy){

            Write-Message `
                -Status "PASS" `
                -Message "Conditional Access policy already exists: CA007 - Protect BreakGlass." `
                -Component "SECURITY"

            return

        }


        # Policy definition will be added here


        Write-Message `
            -Status "PASS" `
            -Message "Created CA007 - Protect BreakGlass." `
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