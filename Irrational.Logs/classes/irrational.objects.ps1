enum severityMap {
    EMERGENCY = 0
    ALERT     = 1
    CRIT      = 2
    ERROR     = 3
    WARN      = 4
    NOTICE    = 5
    INFO      = 6
    DEBUG     = 7
}

class LogSetting {
    [String] $Color
    [String] $AnsiId
    [String] $Type

    LogSetting( $s ){

        # Used to assign different configuration options
        $colorName, $id, $sevType = Switch -regex ( $s ){

            'EMERGENCY' { 'Red'        ; "`e[91m" ; 'error' }
            'ALERT'     { 'Red'        ; "`e[91m" ; 'error' }
            'CRIT'      { 'DarkRed'    ; "`e[31m" ; 'error' }
            'ERROR'     { 'Magenta'    ; "`e[95m" ; 'error' }
            'WARN'      { 'DarkYellow' ; "`e[93m" ; 'warning' }
            'NOTICE'    { 'Cyan'       ; "`e[96m" ; 'warning' }
            'INFO'      { 'Green'      ; "`e[92m" ; 'information' }
            'DEBUG'     { 'Gray'       ; "`e[90m" ; 'information' }
        }

        $this.color     = $colorName
        $this.ansiId    = $id
        $this.type      = $sevType
    }
}

class LogPath {
    [String] $Parent
    [String[]] $Path
    [PSObject[]] $Attachment

    LogPath( $p, $l ){
        $this.parent = $p
        $this.path = $l
    }
}

class IrrationalLog {
    [String] $Time
    [DateTime] $Date
    [String] $Instance
    [String] $Severity
    [String] $Project
    [String] $Title
    [String[]] $Group
    [String[]] $Collection
    [String] $Message
    [LogSetting] $Settings
    [PSObject[]] $Attachment
    [String] $Source
    [String[]] $Path

    IrrationalLog( $timeFormat, $p, $t, $g, $c, $s, $m, $l, $a, $f ){

        $dateTime = Get-Date
        $timeStr = if( $timeFormat -eq 'epoch' ){ GetEpochTime $dateTime }else{ $dateTime.toString('yyyy-MM-dd HH:mm:ss') }
        
        $this.time = $timeStr
        $this.date = $dateTime
        $this.instance = $global:pid
        
        $this.project = $p
        $this.title = $t
        $this.severity = $s 
        $this.group = $g
        $this.collection = $c
        $this.message = $m
        $this.settings = $l
        $this.attachment = $a
        $this.source = $f
    }

    IrrationalLog(){}
}
