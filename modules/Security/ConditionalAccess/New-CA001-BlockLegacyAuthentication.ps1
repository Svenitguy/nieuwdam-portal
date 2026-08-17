# ============================================================
# New-CA001-BlockLegacyAuthentication
# ============================================================

function New-CA001-BlockLegacyAuthentication {

    [CmdletBinding()]
    param(
        [switch]
        $DryRun
    )


    # ==================================================
    # Dry Run
    # ==================================================

    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message "Would create CA001 - Block Legacy Authentication." `
            -Component "SECURITY"


        return @{

            Component = "ConditionalAccess"

            Policy = "CA001 - Block Legacy Authentication"

            Status = "WouldConfigure"

        }

    }


    # ==================================================
    # Check existing policy
    # ==================================================

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


            return @{

                Component = "ConditionalAccess"

                Policy = "CA001 - Block Legacy Authentication"

                Status = "AlreadyExists"

                PolicyId = $ExistingPolicy.Id

            }

        }


        # ==================================================
        # Create policy
        # ==================================================

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


        $CreatedPolicy =
            New-MgIdentityConditionalAccessPolicy `
                -BodyParameter $PolicyBody `
                -ErrorAction Stop


        Write-Message `
            -Status "PASS" `
            -Message "Created CA001 - Block Legacy Authentication." `
            -Component "SECURITY"


        return @{

            Component = "ConditionalAccess"

            Policy = "CA001 - Block Legacy Authentication"

            Status = "Configured"

            PolicyId = $CreatedPolicy.Id

        }


    }
    catch {

        Write-Message `
            -Status "ERROR" `
            -Message $_.Exception.Message `
            -Component "SECURITY"


        throw

    }

}