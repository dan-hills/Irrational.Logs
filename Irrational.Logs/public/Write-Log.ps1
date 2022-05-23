using namespace System.Management.Automation

function Write-Log {

    <#
    .SYNOPSIS
        This function will send a standardized, structured output message for logs both to the pipeline and saved to a file

    .DESCRIPTION
        This function will send a standardized, structured output message for logs both to the pipeline and saved to a file. This function is intended to provide
        a complex solution to what is typically thought of as a simple problem, by making logs easier to digest, write and manipulate. This is primarily written
        with the interest of being used within a script so that a developer can focus writing code while having a reliable and structured method for organizing
        logs.

    .PARAMETER ProjectName
        The ProjectName can be used when organizing your logs. The ProjectName will organize all logs within a subfolder and name all logs according to this parameter

        Default: Logs

    .PARAMETER Collection
        The collection parameter can be used to output a specific set of log enteries to a new set of logs. 

        The intended use is to allow a new log for changes/modifications or errors without some of the additional noise from a standard log

    .PARAMETER Title
        The title parameter is added to the displayed log entry and intended to help organize logs of a specific type

        Default: GENERAL

    .PARAMETER Group
        Using the Group parameter is optional but provides an additional layer of organizing logging. This is particularly helpful when looping through objects.

        The group option accepts mutliple [String] inputs and can be used to organize output through multiple nested loops

    .PARAMETER Attachment
        The attachment parameter is used to store an object directly to the log message. This is particularly useful when further manipulation of the log output
        object is required

    .PARAMETER SaveAttachment
        When used, this parameter will create a new folder containing a json output of the specified log output including any attached objects

    .PARAMETER TimeFormat
        This can be used to specify the date as a ISO 8601 datetime string(standard)[default] or as an epoch time string

    .PARAMETER Message
        This is the main message which will be included in the log

        Mandatory: True

    .PARAMETER Severity
        Severity can be used to highlight specific log entries to more easily identify problems or potential issues

        Default: INFO

    .PARAMETER DisplaySeverityLevel
        This can be used to hide a specific level of messages. Default setting will display all messages marked as INFO or higher while DEBUG messages are hidden.

        When set even though messages are not displayed, all log info will still be written to a log file

    .PARAMETER LogVariable
        This will save the entire log object and any attachments included in that output to a variable. This is a global variable which will persist throughout 
        the current session

    .PARAMETER Source
        This can be used to identify the source of the log or the script where the error occurred

    .PARAMETER Path
        This is the output location where the log will be saved

        Default: ${ENV:TEMP}

    .PARAMETER OutputType
        This will specify the output type which will be generated for each log entry
        Options include:
            + csv:  A standard csv text file
            + log(DEFAULT) = this will generate a file which can be imported to ccmtrace log reader (sccm). This is ideal for shorter,simpler logs but data cannot 
                be reimported as an object when this format is used

    .PARAMETER GenerateEvent
        When used, this will generate a new Windows EventLog entry. The source type will use the ProjectName parameter.

        If the source type is new, this script must be run as an administrator to generate the new source type.

    .PARAMETER EnableLogRotation
        When enabled, this will allow the use of configuring the maximum log size and will rotate logs between output files. Files will
        no longer be date stamped when output

    .PARAMETER LogSizeMB
        When log rotation has been enabled, this is the maximum allowable log size in MB before the file will rotate

    .PARAMETER RotationLogCount
        When log rotation has been enabled, this is the maximum number of archived log files before the files are purged

    .PARAMETER PassThru
        This will send the entire log object to the pipeline

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.Information]

        By default, a log entry will only generate information output which will sent to the pipeline. If using the -PassThru switch, an object of type 
        [IrrationalLog] will be sent to the pipeline

    .EXAMPLE
        PS> Write-IrrationalLog "test message" -OutputType csv

            [2022-05-01 12:00:15][INFO ][GENERAL   ][test message]

        This example shows the output stream which has been formatted as an information block. Log data will always be written to disk (in this case as csv):
            "2022-05-01 12:00:15","Info","GENERAL","test message"

    .NOTES
        All new entries should append new entries to existing log files if possible. The only time that entries are deleted is when the rotation file count limit 
        is reached
    #>

    [cmdletbinding( DefaultParameterSetName = 'DatedLogs' )]

    param(
        [Parameter( 
            Position = 0,
            ParameterSetName = 'DatedLogs',
            Mandatory = $true,
            HelpMessage = 'Please enter any text which should be included as a log entry' )]
        [Parameter( 
            Position = 0,
            ParameterSetName = 'RotationLog',
            Mandatory = $true,
            HelpMessage = 'Please enter any text which should be included as a log entry' )]
        [String] $Message,

        # Organizational Parameters
        [Parameter( ParameterSetName = 'DatedLogs' )]
        [Parameter( ParameterSetName = 'RotationLog' )]
        [String] $Title = 'GENERAL',

        [Parameter()]
        [String[]] $Group,

        [Parameter( ParameterSetName = 'DatedLogs' )]
        [Parameter( ParameterSetName = 'RotationLog' )]
        [String] $ProjectName = 'Logs',

        [Parameter()]
        [String[]] $Collection,

        [Parameter()]
        [ValidateSet('csv','log','txt')]
        [String] $OutputType = 'log',

        [Parameter()]
        [ValidateSet('EMERGENCY','ALERT','CRIT','ERROR','WARN','NOTICE','INFO','DEBUG')]
        [String] $Severity = 'Info',

        [Parameter()]
        [ValidateSet('EMERGENCY','ALERT','CRIT','ERROR','WARN','NOTICE','INFO','DEBUG')]
        [String] $DisplaySeverityLevel = 'Info',

        [Parameter()]
        [ValidateSet('EMERGENCY','ALERT','CRIT','ERROR','WARN','NOTICE','INFO','DEBUG')]
        [String] $GenerateErrorOn,

        [Parameter( ValueFromPipeline )]
        [PSObject[]] $Attachment,

        [Parameter()]
        [Switch] $SaveAttachment,

        [Parameter()]
        [String] $LogVariable,

        [Parameter()]
        [String] $Source = (( $myinvocation.scriptName | Split-Path -Leaf -ErrorAction Ignore ) + ':' + $myInvocation.scriptLineNumber),

        [Parameter()]
        [ValidateScript({ Test-Path $_ })]
        [String] $Path = "${env:TEMP}",

        [Parameter()]
        [Alias('Session')]
        [PSObject] $ComputerName,

        [Parameter()]
        [Switch] $GenerateEvent = $false,

        [Parameter( ParameterSetName = 'RotationLog' )]
        [Switch] $EnableLogRotation = $false,

        [Parameter( ParameterSetName = 'RotationLog' )]
        [ValidateRange(1,5000)]
        [Int] $LogSizeMB = 200,

        [Parameter( ParameterSetName = 'RotationLog' )]
        [ValidateRange(1,20)]
        [Int] $RotationLogCount = 5,

        [Parameter()]
        [ValidateSet('epoch','standard')]
        [String] $TimeFormat = 'standard',

        [Parameter()]
        [Switch] $PassThru = $false
    )

    BEGIN{

        $code = {

            $outputFilePath = SetOutputPath $path $collection $projectName $outputType $enableLogRotation
            if( $PSBoundParameters['enableLogRotation'] ){ UpdateRotationLog $outputFilePath $rotationLogCount $LogSizeMB }

            # This section is used for a quick text replacement for standar 
            switch -regex ( $message ){

                '^\${{\s?LINEBREAK\s?}}$'   { $message = '-' * 120 }
            }

            # First we can determine any log settings based on severity
            $logSetting = [LogSetting]::New( $severity )

            # Now we can instantiate the log output object
            $output = [IrrationalLog]::New( $timeFormat, $projectName, $title, $group, $collection, $severity, $message, $logSetting, $attachment, $source )

            # Next we format our console output string
            $outMessage = FormatOutputString $output

            # Log settings are then injected into host display output depending on the version used and sent back to the host
            $hostMsg = FormatHostOutput $outMessage $output

            # Passes the info back to the pipeline as an object
            if( $psBoundParameters['passThru'] ){ $output }

            # Adds the output as a variable - if it does not exist a new one is created - this is a global scope var
            if( $psBoundParameters['logvariable'] ){ SetLogVar $output }

            # Finally, we can output the log data to the pipeline
            Write-Debug ("Display Option: {0}({1})"  -f $displaySeverityLevel, [int][severityMap]::($displaySeverityLevel.toUpper()) )
            Write-Debug ("Message Severity: {0}({1})" -f $Severity,[int][severityMap]::($severity.toUpper()) )
            if( [int][SeverityMap]::($displaySeverityLevel.toUpper()) -ge [int][SeverityMap]::($severity.toUpper()) ){

                Write-Information $hostmsg -InformationAction Continue
            }

            # And now we can generates the final file output
            Write-Debug "OutputType: '$outputtype' :: OutputPath: '$($outputFilePath.path -join ',')'"
            OutputLogFile $outputType $outputFilePath $hostMsg $output
            Write-Verbose "Log saved to '$($output.path -join ', ')'"

            # This option will generate a separate group of logs contains the json output of a particular attachment
            if( $psBoundParameters['saveAttachment'] ){ SaveAttachment $outputFilePath $outMessage }

            # Generates an error message when the severity level is higher than the chosen option
            if( $psBoundParameters['GenerateErrorOn'] -AND [int][SeverityMap]::($generateErrorOn.toUpper) -ge [int][SeverityMap]::($severity.toUpper()) ){

                Write-Error -Message $message
            }

            # Used to genereate an Event to the Application log on the log system
            if( $psBoundParameters['GenerateEvent'] ){ NewEventLogEntry $output }
        }

        # Imports the function to a remote session
        if( $psBoundParameters['ComputerName'] ){

            switch( $computerName ){
    
                { $_ -is [System.Management.Automation.Runspaces.PSSession] }  {
    
                    Write-Verbose ( "Existing session {0}({1}) will be used" -f $computername.computerName,$computername.instanceId )
                    Invoke-Command -Session $computerName -ScriptBlock ${function:Write-Log}
                }

                default {

                    Write-Verbose "Attempting to connect directly to the host $computerName"
                    Invoke-Command -ComputerName ([string]$computerName) -ScriptBlock ${function:Write-Log}
                }
            }
        }
    }

    PROCESS{

        # This will allow the function to be executed remotely via remote function invocation
        if( $psBoundParameters['ComputerName'] ){

            switch( $computerName ){
    
                { $_ -is [System.Management.Automation.Runspaces.PSSession] }  {
    
                    Write-Verbose ( "Existing session {0}({1}) will be used" -f $session.computerName,$session.instanceId )
                    Invoke-Command -Session $computerName -ScriptBlock 
                }
                default {

                    Write-Verbose ( "Creating new session to $($computerName)" )
                    Invoke-Command -ComputerName $computerName -ScriptBlock
                }
            }
        }
        else{

            Invoke-Command -ScriptBlock $code
        }
    }
}
