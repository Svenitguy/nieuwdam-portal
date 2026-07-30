# ==================================================
# Enterprise Reporting Module
#
# Purpose:
# Generates validation reports in CSV, JSON and HTML.
#
# Functions:
# - New-ValidationReport
#
# Version:
# 1.0.0
# ==================================================

# ==================================================
# Validation Report Generation
# ==================================================

function New-ValidationReport {

    param(

        [Parameter(Mandatory)]
        $Results,


        [Parameter(Mandatory)]
        [string]
        $OutputFolder,


        [Parameter(Mandatory)]
        [string]
        $RunId,


        [Parameter()]
        [string]
        $TenantName = "Unknown"

    )


    try {


        Write-Logging `
            -Message "Starting validation report generation. RunId: $RunId" `
            -Level "INFO" `
            -Component "REPORTING"



        $Timestamp =
            Get-Date -Format "yyyy-MM-dd_HH-mm-ss"



        $CsvReport =
            Join-Path `
                $OutputFolder `
                "validation-$Timestamp.csv"



        $HtmlReport =
            Join-Path `
                $OutputFolder `
                "validation-$Timestamp.html"



        $JsonReport =
            Join-Path `
                $OutputFolder `
                "validation-$Timestamp.json"




        # ==================================================
        # Prepare report data
        # ==================================================

        $ReportResults =
            foreach ($Result in $Results) {


                [PSCustomObject]@{


                    RunId =
                        $RunId


                    Timestamp =
                        $Result.Timestamp


                    Type =
                        $Result.Type


                    Name =
                        $Result.Name


                    Status =
                        $Result.Status


                    Control =
                        $Result.Control


                    Expected =
                        $Result.Expected


                    Actual =
                        $Result.Actual


                    Message =
                        $Result.Message


                }


            }




        # ==================================================
        # CSV
        # ==================================================

        $ReportResults |
            Export-Csv `
                -Path $CsvReport `
                -NoTypeInformation `
                -Encoding UTF8




        # ==================================================
        # JSON
        # ==================================================

        $ReportObject =
            [PSCustomObject]@{


                RunId =
                    $RunId


                Generated =
                    Get-Date


                Tenant =
                    $TenantName


                Results =
                    $ReportResults


            }



        $ReportObject |
            ConvertTo-Json -Depth 10 |
            Out-File `
                -FilePath $JsonReport `
                -Encoding UTF8




        # ==================================================
        # HTML
        # ==================================================

        $TemplatePath =
            "$PSScriptRoot\Templates\validation-report.html"



        if (
            -not (
                Test-Path $TemplatePath
            )
        ) {

            throw "HTML template not found: $TemplatePath"

        }



        $HtmlContent =
            Get-Content `
                $TemplatePath `
                -Raw




        $HtmlContent =
            $HtmlContent.Replace(
                "{{JSON_FILE}}",
                (Split-Path $JsonReport -Leaf)
            )



        $HtmlContent =
            $HtmlContent.Replace(
                "{{RUN_ID}}",
                $RunId
            )



        $HtmlContent =
            $HtmlContent.Replace(
                "{{TENANT_NAME}}",
                $TenantName
            )



        $HtmlContent =
            $HtmlContent.Replace(
                "{{GENERATED}}",
                (Get-Date)
            )



        $HtmlContent |
            Out-File `
                -FilePath $HtmlReport `
                -Encoding UTF8




        # ==================================================
        # Copy assets
        # ==================================================

        Copy-Item `
            -Path "$PSScriptRoot\Templates\validation.css" `
            -Destination $OutputFolder `
            -Force



        Copy-Item `
            -Path "$PSScriptRoot\Templates\validation.js" `
            -Destination $OutputFolder `
            -Force




        Write-Logging `
            -Message "Validation report generated successfully. RunId: $RunId" `
            -Level "PASS" `
            -Component "REPORTING"



        return [PSCustomObject]@{


            Csv =
                $CsvReport


            Html =
                $HtmlReport


            Json =
                $JsonReport


        }


    }
    catch {


        Write-Logging `
            -Message "Validation report generation failed: $($_.Exception.Message)" `
            -Level "ERROR" `
            -Component "REPORTING"



        throw


    }


}



# ==================================================
# Export
# ==================================================

Export-ModuleMember `
    -Function @(

        "New-ValidationReport"

    )