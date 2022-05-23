function Set-Log {

    <#
    .SYNOPSIS
        This function will set the default logging settings which will be used throughout a script
    
    .DESCRIPTION
        This function will set the default logging settings which will be used throughout a script. This utilizes the $psdefaultparametervalues
        variable so it will not be carried to a new session or be available within an imported module unless it is configured to 
        replicate the variable within the module/session.

    .PARAMETER ProjectName
        This parameter sets the project name that will accompany the exported file as well as the parent folder that is created
        for the logging folders

    .PARAMETER Path
        This is the export path where the project folder will be created. 

        NOTE: A subfolder for the project will be created below this path and the logging files will not be saved directly to this folder

    .PARAMETER OverWriteDefaults
        This will need to be used should any previous logging settings have been saved to the current powershell session. This will
        completely wipe out the previous settings

    .PARAMETER Scope
        This indicates the scope of the PSDefaultParameterValues settings if they do not need to be saved as Global within a script

    .PARAMETER LogSizeMB
        This parameter can be used only for rotation logs but will set the maximum log size for a log before it rolls into using the 
        next available logging file

    .PARAMETER RotationLogCount
        This is the number of log files which are kept local to the system. The oldest file will be purged and deleted once the
        number or $RotationLogCount is exceeded

    .INPUTS
        [System.String]

    .OUTPUTS
        No output is expected but will update the values saved to $PSDefaultParameterValues

    .EXAMPLE
        PS> Set-Log -ProjectName ProjectX -Path c:\Scripts\Logs -RotationLogCount 5 -LogSizeMB 20 -OverWriteDefaults

        This will create a new series or rotation log files called 'ProjectX.log' (and when rotated: ProjectX.0, ProjectX.1, etc)
        All log files will be within the folder 'C:\Script\Logs\ProjectX'
        Maximum number of log files is 5 files with a maximum size of 20MB each

    .NOTES
        This function should be used in conjunction with the Write-Log function and currently only outputs to a csv formatted file
    #>

    [cmdletbinding(DefaultParameterSetName = 'DatedLog')]

    param(
        [Parameter( ParameterSetName = 'DatedLog')]
        [Parameter( ParameterSetName = 'LogRotation')]
        [String] $ProjectName,

        [Parameter()]
        [String] $Collection,

        [Parameter()]
        [String] $Group,

        [Parameter( ParameterSetName = 'DatedLog' )]
        [Parameter( ParameterSetName = 'LogRotation' )]
        [String] $Path = "${env:TEMP}",

        [Parameter()]
        [Alias('OverwriteDefaults')]
        [Switch] $Force = $false,

        [Parameter()]
        [Switch] $RemoveAllDefaults = $false,

        [Parameter()]
        [ValidateSet('global','script')]
        [String] $Scope = 'global',

        [Parameter()]
        [ValidateSet('EMERGENCY','ALERT','CRIT','ERROR','WARN','NOTICE','INFO','DEBUG')]
        [String] $DisplaySeverityLevel = 'info',

        [Parameter()]
        [ValidateSet('csv','log','txt')]
        [String] $OutputType = 'log',

        [Parameter( ParameterSetName = 'LogRotation' )]
        [Switch] $EnableLogRotation = $false,

        [Parameter( ParameterSetName = 'LogRotation' )]
        [Int] $LogSizeMB,

        [Parameter( ParameterSetName = 'LogRotation' )]
        [Int] $RotationLogCount,

        [Parameter()]
        [Switch] $PassThru = $false
    )

    $staticParam = 'Force','RemoveAllDefaults','passThru','verbose','debug','erroraction','warningaction','informationAction','errorVariable','warningVariable','informationVariable','outVariable','outBuffer','pipelineVariable'

    $variables = forEach( $item in $myInvocation.myCommand.Parameters.keys.where{$_ -notIn $staticParam} ){ 

        try{ Get-Variable -Name $item -ErrorAction 'stop' }catch{ Write-Warning "Error retrieving settings for '$item'"; continue }
    }

    # This will go through and remove any of the previously assigned settings
    foreach( $var in $variables ){

        $varName = "Write-RSGLog:" + $var.name

        # Debug current variable details
        Write-Debug $varName
        if( ![String]::IsNullOrEmpty($global:PSDefaultParameterValues.$varName) ){ Write-Debug ("Current Settings:" + $global:PSDefaultParameterValues.$varName) }else{ Write-Debug 'Current Settings: null' }
        Write-Debug "New Settings: $( $var | ConvertTo-Json )"
        
        # Removes all saved settings
        if( $PSBoundParameters['RemoveAllDefaults'] ){

            Write-Verbose "Removing $varName"
            $global:psdefaultparametervalues.remove("$varName")
        }
        
        # no changes required if default value is already assigned
        elseif( $var.value -eq $global:PSDefaultParameterValues.$varName -OR [String]::IsNullOrEmpty($var.value) ){
            
            Write-Verbose "No updates required for '$varName'"
            continue
        }

        # remove the current assigned value
        elseif( $PSBoundParameters['force'] -AND $PSBoundParameters[$var.name]){

            Write-Verbose "Removing current default parameter settings for '$varName'"
            $global:psdefaultparametervalues.remove("$varName")
        }

        if(![String]::IsNullOrEmpty( $var.value )){

            try{

                $global:PSDefaultParameterValues.Add($varName,$var.value)
                Write-Verbose "Settings have been added for '$($varName)' => $($var.value)"
            }
            catch [System.ArgumentException]{
            
                Write-Warning "Default parameter is set for $varName=='$($global:PSDefaultParameterValues.$varName)'. Use -Force to overwrite"
            }
            catch {

                Write-Error "An unknown error has occurred when retrieving the variable $varName"
                continue
            }
        }
    }

    $outputpath = Switch ($psCmdlet.ParameterSetname ){

        'LogRotation'      { Join-Path $path "$($global:PSDefaultParameterValues['Write-Log:projectName'])\$($global:PSDefaultParameterValues['Write-Log:projectName']).$($global:PSDefaultParameterValues['Write-Log:outputtype'])" }
        'datedlog'         { 
            $date = Get-Date -f 'yyyyMMdd' 
            Join-Path $path "$($global:PSDefaultParameterValues['Write-Log:projectName'])\${date}_$($global:PSDefaultParameterValues['Write-Log:projectName']).$($global:PSDefaultParameterValues['Write-Log:outputtype'])" }
    }
    
    if( $psBoundParameters['PassThru'] ){

        [pscustomobject][ordered]@{
            ProjectName = $projectName
            Path        = $outputPath
            Parent      = Join-Path $path $global:PSDefaultParameterValues['Write-LoG:projectName']
            LogType     = $pscmdlet.ParameterSetName
            Defaults    = $global:PSDefaultParameterValues.getEnumerator().where{$_.name -like "Write-Log:*"} | ConvertTo-Json
        }
    }
}
