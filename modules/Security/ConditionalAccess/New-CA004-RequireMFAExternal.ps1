function New-CA004-RequireMFAExternal {

    [CmdletBinding()]
    param(
        [switch]
        $DryRun
    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message "Would create CA004 - Require MFA External Users." `
            -Component "SECURITY"

        return

    }


    Write-Message `
        -Status "INFO" `
        -Message "Creating CA004 - Require MFA External Users." `
        -Component "SECURITY"


}