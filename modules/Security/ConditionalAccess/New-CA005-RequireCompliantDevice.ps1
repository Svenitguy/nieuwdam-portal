# ============================================================
# New-CA005-RequireCompliantDevice
#
# Requires compliant device.
# ============================================================

function New-CA005-RequireCompliantDevice {

    [CmdletBinding()]
    param(
        [switch]
        $DryRun
    )


    if($DryRun){

        Write-Message `
            -Status "DRYRUN" `
            -Message "Would create CA005 - Require Compliant Device." `
            -Component "SECURITY"

        return
    }


    Write-Message `
        -Status "INFO" `
        -Message "Creating CA005 - Require Compliant Device." `
        -Component "SECURITY"

}