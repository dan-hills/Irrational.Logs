function UpdateLogRotation( $path, $rotationLogCount, $logSizeMB ){

    <#
    .SYNOPSIS
        This function will update an existing rotation log file if it exceeds set thresholds
    #>

    forEach( $outputPath in $path.path ){

        if( (Test-Path $outputpath) ){

            if( (Get-Item $outputpath).length / 1MB -gt $logsizeMB ){

                if( Test-Path "$outputpath.$($rotationlogcount - 1)" ){

                    Write-Verbose "Removing oldest log file $outputpath.$($rotationlogcount - 1)"
                    Remove-Item -Path "$outputpath.$($rotationlogcount - 1)" -Force
                }

                for( $i = 1; $i -le $rotationlogcount; $i += 1 ){

                    if( Test-Path "$outputpath.$($rotationlogcount - $i)" ){
                        
                        Write-Verbose "Rotating $outputpath.$($rotationlogcount - $i) to $outputpath.$($rotationlogcount - $i + 1)"
                        Rename-Item -Path "$outputpath.$($rotationlogcount - $i)" -NewName "$outputpath.$($rotationlogcount - $i + 1)" -Force
                    }
                    else{

                        Write-Verbose "No file found called $outputpath.$($rotationlogcount - $i) to rotate"
                    }
                }

                Write-Verbose "Rotating $outputpath to $outputpath.0"
                Rename-Item -Path $outputpath -NewName "$outputpath.0" -Force
            }
        }
    }
}