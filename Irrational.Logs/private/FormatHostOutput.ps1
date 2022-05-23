function FormatHostOutput( $outMessage, $output ){

    <#
    .SYNOPSIS
        This function configures any environment settings for the output object which is sent to the host display
    #>
    
    # Backwards compatibility for < PS7 display modes
    if( $psVersionTable.psEdition -eq 'Desktop' ){

        [HostInformationMessage]@{
            ForeGroundColor = $output.settings.color
            Message = $outMessage
        }
    }
    # Settings for using ansi escape sequences
    else{

        $output.settings.ansiId + $outMessage + "`e[39m"
    }
}