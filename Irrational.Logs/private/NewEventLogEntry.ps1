function NewEventLogEntry( $log ){

    <#
    .SYNOPSIS
        This function will generate a new Windows Event entry to the local events in the 'Application' log
    #>

    try{

        New-EventLog -LogName Application -Source $log.projectName -ErrorAction Stop
    }
    catch [System.InvalidOperationException]{ 
        
        # TODO: Improve method for determining if a log source exists
        # This behavior occurs because we have no way to determine if a log source exists and failure is expected if a log type exists
    }
    catch {

        Write-Warning "Unable to create new WinEvent source '$($log.projectName)' (an Event source may already exist): $($_.exception.message)"
    }

    try{

        $eventLog = @{
            LogName   = 'Application'
            Source    = $log.projectName
            Message   = $log.message
            EventId   = 1337
            EntryType = $log.settings.type
        }
        Write-EventLog @eventLog
    }
    catch [System.Security.SecurityException]{

        Write-Warning "WinEvent source '$($log.projectName)' does not exist. You will need admin access to generate a new source: $($_.exception.message)"
    }
    catch{

        Write-Warning "An unknown error occurred when attemtping to create a new WinEvent: $($_.exception.message)"
    }
}