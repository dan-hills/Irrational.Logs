#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
$Classes = @( Get-ChildItem -Path $PSScriptRoot\Classes\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach($import in @($Public + $Private + $Classes))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Import the module prefix
#$moduleFile = $myInvocation.myCommand | ConvertTo-Json -Depth 6
#$moduleAttributes = Import-PowerShellDataFile $moduleFile
#Write-information ("Default Command Prefix: " + $moduleFile ) -InformationAction 'continue'

# Export the Public modules
Export-ModuleMember -Function $Public.Basename

# Configure Alias Commands for Export
New-Alias -Name New-Log -Value Write-Log
Export-ModuleMember -Alias New-Log

New-Alias -Name 'log' -Value Write-Log
Export-ModuleMember -Alias log