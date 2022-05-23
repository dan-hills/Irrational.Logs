$ModuleManifestName = 'Irrational.Logs'
$ModuleManifestPath = "$PSScriptRoot\..\$ModuleManifestName"
$TestModule = Test-ModuleManifest -Path $modulemanifestpath
$exportedcommands = $testmodule.exportedcommands.keys
$commandlist = @( @( Get-ChildItem $psscriptroot\..\public\*.ps1 ) + @( Get-ChildItem $psscriptroot\..\private\*.ps1 ) )

Describe 'Module Manifest Tests' {
    Context 'Validates Manifest File Contents' {
        It 'Manifest Version Matches Last Release Notes Entry' {
            $testmodule.privatedata.psdata.releasenotes[-1].split(' ')[0] -eq $testmodule.version | Should Be $true
        }

        It 'Passes Test-ModuleManifest' {
            $testmodule | Should Not BeNullOrEmpty
            $? | Should Be $true
        }

        It 'Public Command Files Should Exist in "public" folder' {
            ForEach($command in $exportedcommands){
                "$psscriptroot\..\public\$command.ps1" | Should Exist
            }
        }
    }
}

Describe 'Module Content Tests' {
    ForEach($command in $commandlist){
        
        #$content = Get-Content -LiteralPath "$($command.fullname)"

        Context "Validates that $($command.name) is using an accepted verb-noun Powershell format" {
            It "$($command.name) uses verb-noun naming standards" {
                "$($command.name.replace('.ps1',''))" | Should Belike "*-*"
            }

            It "$($command.name) uses an approved verb type" {
                "$($command.name.split('-')[0])" | Should BeIn (Get-Verb).verb
            }
        }

        Context "Validates Contents for $($command.name)" {
            It "$($command.name) is valid Powershell Code" {
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
                $errors.count | Should Be 0
            }

            It "$($command.name) contains required help sections (.SYNOPSIS, .DESCRIPTION, .NOTES)" {
                "$($command.fullname)" | Should -FileContentMatch '.SYNOPSIS'
                "$($command.fullname)" | Should -FileContentMatch '.DESCRIPTION'
                "$($command.fullname)" | Should -FileContentMatch '.NOTES'
            }

            It "$($command.name) is declared as an Advanced Function" {
                "$($command.fullname)" | Should -FileContentMatch 'function'
                "$($command.fullname)" | Should -FileContentMatch '\[cmdletbinding\(.*\)\]'
                "$($command.fullname)" | Should -FileContentMatch 'param'
            }
        }

        Context "Validates that the function $($command.name) has a .Tests.ps1 file" {
            It "$($command.name.replace('.ps1','')).Tests.ps1 should exist" {
                "$($command.name.replace('.ps1','')).Tests.ps1" | Should Exist
            }
        }
    }
}

