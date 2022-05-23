function OutputLogFile( $OutputType, $OutputFilePath, $hostMessage, $Output ){
    
    <#
    .SYNOPSIS
        This function will configure the output log file and will adjust output setting depending on user selection
    #>
    
    Switch( $outputType ){

        'txt' {

            forEach( $outputPath in $outputFilePath.path ){ 
                
                try{
                    
                    $hostMessage | Out-File -FilePath $outputPath -Append -ErrorAction 'stop'
                    $output.path += $outputPath
                }
                catch{

                    Write-Warning "Failed to save to '$outputPath': $_"
                }
            }
        }

        'csv' {
            
            forEach( $outputPath in $outputFilePath.path ){ 

                try{
                    $output | Select-Object Time,Instance,Severity,Title,Group,Message,Source,@{n = 'Attachment';e = { $_.attachment | ConvertTo-Json}} | 
                        Export-Csv -NoTypeInformation -Path $outputpath -Append -ErrorAction 'stop'
                    $output.path += $outputPath
                }
                catch{

                    Write-Warning "Failed to save to '$outputPath': $_"
                }
            }
        }

        # TODO: Implement json file creation/manipulation

        'log' {

            $type = Switch -regex( [Int][SeverityMap]::($severity.toUpper()) ){

                { $_ -lt 4 } { 3 } # Higher than warning
                { $_ -eq 4 } { 2 } # Warning
                default      { 1 } # All other severity
            }

            # We need to use a specialized text formatting for SCCMTrace log files
            $strTime = "$($output.date.toString('HH:mm:ss')).$($output.date.millisecond)+0000"
            $strMsg = if( [String]::IsNullOrEmpty($output.group) ){

                "$($output.severity.toUpper())::$($output.message)"
            }
            else{
                "$($output.severity.toUpper())::[$($output.group -join ':' )]::$($output.message)"
                
            }
            
            if( $attachment ){
                
                $strAttach = "`n" + ( $output.attachment | ConvertTo-Json -ErrorAction SilentlyContinue )
                
                $strMsg += $strAttach

                if( $strMsg.length -gt 8000 ){ $strMsg = $strMsg.substring(0,8000) }
            }
            $line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="{5}" file="{6}">'
            $outLine = $line -f $strMsg,$strTime,$($output.date.tostring('MM-dd-yyyy')),$output.title,$type,$pid,$output.file
            forEach( $outputPath in $outputFilePath.path ){ 

                try{
                    
                    $outLine | Out-File -FilePath $outputPath -Append -Encoding Utf8 -ErrorAction 'stop'
                    $output.path += $outputPath
                }
                catch{

                    Write-Warning "Failed to save to '$outputPath.path': $_"
                    $setPath = @{
                        Path = $env:TEMP
                        ProjectName = $output.project 
                        OutputType = 'log'
                    }    
                    $tempPath = SetOutputPath @setPath
                    $outLine | Out-File -FilePath ([String]$tempPath.path) -Append -Encoding Utf8
                    Write-Warning "Output path update to $($tempPath.path)"
                    $output.Path += $tempPath.path
                }
            }
        }
    }
}