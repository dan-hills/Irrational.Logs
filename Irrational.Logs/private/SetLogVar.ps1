function SetLogVar( $output ){
    <#
    .SYNOPSIS
        This function deals with saving a new log variable to the global scope
    #>
    
    try{

        $var = Get-Variable $logVariable -Scope global -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException]{
    
        Write-Verbose "Creating new output variable called '$logVariable'"
        [Collections.ArrayList]$tempVar = @()
    }
    catch [System.Management.Automation.ArgumentTransformationMetadataException] {

        Write-Warning "Unable to add a new value to '$logVariable'. Please clear the variable and try again."
    }
    catch{

        Write-Warning "Unable to save log entry to '$logvariable'. Clear the variable and try again."
        continue
    }
    
    if( $var ){ [Collections.ArrayList]$tempVar = $var.value }
    $tempVar.Add( $output ) | Out-Null

    try{

        Set-Variable -Name $logvariable -Value $tempVar -Scope global -Force
    }
    catch{

        Write-Warning "Unable to save log entry to '$logvariable'. An unknown error has occurred:`n$($_)"
    }
}