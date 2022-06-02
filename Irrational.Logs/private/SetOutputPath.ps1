function SetOutputPath {

    <#
    .SYNOPSIS
        This function will configure the project folder and manages and any settings pertaining to the output file name
    #>
    
    [cmdletbinding()]

    param(
        $Path,
        $Collection,
        $ProjectName,
        $OutputType,
        $EnableLogRotation
    )

    $date = Get-Date 

    # Creates a new log directory if there is not already one
    $projpath = Join-Path $path $projectname
    if( ! ( Test-Path $projpath )){

        Write-Verbose "No project folder discovered at $projpath. A new one will now be created"
        New-Item -ItemType Directory -Name $projectname -Path $path | Out-Null
    }

    # Sets the output project/collection folder and logs
    $fileName = if( $Collection ){

        forEach( $col in $collection ){

            if( $col -eq 'default' ){
                
                $projectName + '.' + $outputType
            }
            else{

                $projectName + '_' + $col + '.' + $outputType 
            }
        }
    }
    else{

        $projectName + '.' + $outputType 
    }

    # Configures the file output path based on the log type assigned
    $files = forEach( $file in $fileName ){
        
        Switch( $enablelogrotation ){
            $true   { Join-Path $projpath $file }
            default { Join-Path $projpath "$($date.toString('yyyyMMdd'))_$file" }
        }
    }

    [LogPath]::New( $projPath, $files )
}