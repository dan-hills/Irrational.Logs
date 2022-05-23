# Irrational.Logs

## SYNOPSIS

This module is intended to package functions and scripts which can be used to create a uniform, structured logging platform for your scripts

## BRIEF DESCRIPTION

This module is intended to package functions and scripts which can be used to create a uniform, structured logging platform for your scripts

Current functions include the following capabilities:

* Object-oriented Logging
* Sending structured email notifications

## DETAILED DESCRIPTION

Detailed below are highlights for each of the included functions
## Usage

### Set-Log/Write-Log

This set of functions has been designed with the intention of building a robust, standardized logging tool which outputs using a clean, consistent format to both the console window as well as outputting a structured object to a file.

#### Overview of Write-Log

This function can be used to create a standardized system of logging for your scripts and outputs the results as a CSV file, text file, or `.log` file (supported by the SCCM CMTrace logging).

The saved CSV can then be used for easier querying when re-imported to Powershell.

Example output:

```csv
"time","severity","title","message"
"1544634485","Info","SlackChannelAdd","Channel 'rsg-am-map-structures' already exists: [ ""GDB9M5JHM"",""rsg-am-map-structures"", ]"
```

* **time:** This is the epoc timestamp and is automatically generated based on when the command is initiated within a script
* **severity:** This is a pre-configured set of categories which can be used. These will follow all syslog standarized conventions. The default entry is *info*
* **title:** This field can be used to identify the location within the script a particular action/result is performed
* **message:** Can be set to provide any information

This example presents the default output from a traditional rotation log. By default, this will also output directly to the Powershell
host and can be used to track progress of a running script as well as saving to a file. This csv file can then be imported through
the use of `Import-CSV` to parse through the file as desired or using an external application such as Excel.

Import Example:

```Powershell
PS> $csv = Import-Csv "LogFile.log"

PS> $csv | Select -First 3

time       severity title         message
----       -------- -----         -------
1544634375 Info     Initalization Initialization completed at: 01/01/2022 12:00:01
1544634375 Info     Test          This step has completed successfully
1544634381 Error    Test2         This step has started and failed to complete

PS> $csv | Where-Object { $_.severity -eq 'error' }

time       severity title          message
----       -------- -----          -------
1544634381 Error    Test2          This step has started and failed to complete
```

#### Overview of Set-Log

While it is not required, the function `Set-Log` will apply default settings which can be utilized throughout your script. These
values are saved to the [`$PSDefaultParameterValues`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-6) values table and as a result will respond any time a call is made to use the `Write-Log` function.