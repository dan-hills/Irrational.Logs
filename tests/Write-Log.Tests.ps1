<#
    .SYNOPSIS
        This script will perform pester tests against the Write-Log function
#>



Describe "Log output file settings" {

    Context "File Formatting" {

        It "Logs are output as <_>" -forEach @('log','csv') {

            Write-IrrationalLog 'Test' 

        }
    }
}
