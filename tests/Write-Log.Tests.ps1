<#
    .SYNOPSIS
        This script will perform pester tests against the Write-Log function
#>



Describe "Log output file settings" {

    Context "File Formatting" -forEach @('log','csv'){

        BeforeAll {
            
            $log = Write-IrrationalLog 'Test' -PassThru -OutputType $_
        }

        It "Log of type '<_>' is successfully created" {

            $log.path | Should -Exist
        }

        It "Logs can be read back into powershell" {

            $log.
        }
    }
}
