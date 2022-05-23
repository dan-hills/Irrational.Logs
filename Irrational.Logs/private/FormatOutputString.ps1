function FormatOutputString($log){
    <#
    .SYNOPSIS
        This function is used to format the output that is sent to the host/console
    #>

    # This is a complete unnecessary bit to center align text within the log boxes
    $outSev = $log.severity.toUpper().padright(6)
    $outTitle = $log.title.padleft(10-[int]((10-$log.title.length)/2)).padright(10).substring(0,10)

    # This is where we generate the output string which is sent to the primary host
    if( [String]::IsNullOrEmpty( $log.group )){

        "[{0}][{1}][{2}][{3}]" -f $log.time,$outSev,$outTitle,$log.message
    }
    else{

        $groupSet = if( ($log.group|Measure-Object).count -gt 1 ){ $log.group | forEach-Object{ "{$_}" }}else{ $log.group }
        "[{0}][{1}][{2}][{3}][{4}]" -f $log.time,$outSev,$outTitle,($groupSet -join ''),$log.message
    }

}