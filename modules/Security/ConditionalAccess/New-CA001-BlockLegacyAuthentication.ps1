# ============================================================
# New-CA001-BlockLegacyAuthentication
# ============================================================

function New-CA001-BlockLegacyAuthentication {

    [CmdletBinding()]
    param(
        [switch]
        $DryRun
    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message "Would create CA001 - Block Legacy Authentication." `
            -Component "SECURITY"

        return

    }


    try {

        $ExistingPolicy =
            Get-MgIdentityConditionalAccessPolicy `
                -ErrorAction Stop |
            Where-Object {
                $_.DisplayName -eq "CA001 - Block Legacy Authentication"
            }


        if($ExistingPolicy){

            Write-Message `
                -Status "PASS" `
                -Message "Conditional Access policy already exists: CA001 - Block Legacy Authentication." `
                -Component "SECURITY"

            return

        }


        $PolicyBody = @{

            displayName = "CA001 - Block Legacy Authentication"

            state = "enabled"

            conditions = @{

                users = @{
                    includeUsers = @(
                        "All"
                    )
                }

                clientAppTypes = @(
                    "exchangeActiveSync",
                    "other"
                )

            }

            grantControls = @{

                operator = "OR"

                builtInControls = @(
                    "block"
                )

            }

        }


        New-MgIdentityConditionalAccessPolicy `
            -BodyParameter $PolicyBody `
            -ErrorAction Stop


        Write-Message `
            -Status "PASS" `
            -Message "Created CA001 - Block Legacy Authentication." `
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