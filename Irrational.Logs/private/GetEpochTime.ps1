function GetEpochTime($date) {
    
    <#
    .SYNOPSIS
        This is just a simple way of calculating the epochtime string for a specified datetime object
    #>
    
    $date = if( !$PSBoundParameters['date]'] ){ Get-Date }

    [System.Math]::Truncate(( Get-Date -Date ($date).ToUniversalTime() -UFormat %s ))
}