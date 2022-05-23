function SaveAttachment( $path, $log ){

    <#
    .SYNOPSIS
        This function deals with saving the log output object to a file as json
    #>

    if( !(Test-Path "$($Path.parent)\attachments")){

        New-Item -Path $Path.parent -ItemType Directory -Name attachments | Out-Null
    }

    $filetime = GetEpochTime
    $attachPath = "$Path\attachments\${filetime}_$($log.projectName).json"
    ($log.attachment | ConvertTo-Json ) | Out-File -FilePath $attachPath -Encoding Utf8
}