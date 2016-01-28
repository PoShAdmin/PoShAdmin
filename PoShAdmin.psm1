# PoShAdmin Module
# (c) 2016 PoShAdmin.Net. All rights reserved.
# Author: Greg Szabo
# URL: http://PoShAdmin.Net

function Start-PoShJob
{
<#

.SYNOPSIS

Starts a PoShAdmin background job.

.DESCRIPTION

The Start-PoShJob cmdlet starts a PoShAdmin background job on the local computer.

A PoShAdmin background job runs a command "in the background" using PowerShell runspaces without interacting with the current session. When you start a background job, a PoShAdmin job object is returned immediately, even if the job takes an extended time to complete. You can continue to work in the session without interruption while the job runs.

The job object contains useful information about the job, but it does not contain the job results. When the job completes, use the Receive-PoShJob cmdlet to get the results of the job. For more information about background jobs, see about_PoShJobs.

.PARAMETER ArgumentList

Specifies the arguments (parameter values) for the script that is specified by the FilePath or ScriptBlock parameter.

Because all of the values that follow the ArgumentList parameter name are interpreted as being values of ArgumentList, the ArgumentList parameter should be the last parameter in the command.

.PARAMETER FilePath

Runs the specified local script as a background job. Enter the path and file name of the script or pipe a script path to Start-PoShJob. The script must reside on the local computer or in a directory that the local computer can access.

When you use this parameter, PoShAdmin converts the contents of the specified script file to a script block and runs the script block as a background job.

.PARAMETER InputObject

WARNING! Not supported yet.

Specifies input to the command. Enter a variable that contains the objects, or type a command or expression that generates the objects.

In the value of the ScriptBlock parameter, use the $input automatic variable to represent the input objects.

.PARAMETER LiteralPath

Runs the specified local script as a background job. Enter the path to a script on the local computer.

Unlike the FilePath parameter, the value of LiteralPath is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.

.PARAMETER Name

Specifies a friendly name for the new job. You can use the name to identify the job to other job cmdlets, such as Stop-PoShJob.

The default friendly name is Job#, where "#" is an ordinal number that is incremented for each job.

.PARAMETER ScriptBlock

Specifies the commands to run in the background job. Enclose the commands in braces ( { } ) to create a script block. This parameter is required.

.INPUTS
The input type is the type of the objects that you can pipe to the cmdlet.

System.String
    You can pipe an object with the Name property to the Name parameter. For example, you can pipe a FileInfo object from Get-ChildItem to Start-PoShJob.

.OUTPUTS
The output type is the type of the objects that the cmdlet emits.

PoShAdmin.Job
    Start-PoShJob returns an object that represents the job that it started.

.EXAMPLE
Start-PoShJob -ScriptBlock {Get-Process}

This command starts a background job that runs a Get-Process command. The command returns a job object with information about the job. The command prompt returns immediately so that you can work in the session while the job runs in the background.

.EXAMPLE
Start-PoShJob -FilePath C:\Scripts\Sample.ps1

This command runs the Sample.ps1 script as a background job.

.EXAMPLE
Start-PoShJob -Name WinRm -ScriptBlock {Get-Process WinRm}

This command runs a background job that gets the WinRM process on the local computer. The command uses the ScriptBlock parameter to specify the command that runs in the background job. It uses the Name parameter to specify a friendly name for the new job.

.NOTES
To run in the background, Start-PoShJob runs in its own session within the current session.

.LINK
http://PoShAdmin.Net
Get-PoShJob
Stop-PoSh
Receive-PoShJob
Wait-PoShJob
Remove-PoShJob
#>
[CmdletBinding(DefaultParameterSetName="ComputerName")]
param(
    [Parameter(ParameterSetName="ComputerName",Position=0,Mandatory=$true)]
        [Alias("Command")][ScriptBlock]$ScriptBlock,
    [Parameter(ParameterSetName="LiteralFilePathComputerName",Position=0,Mandatory=$true)]
        [Alias("PSPath")][String]$LiteralPath,
    [Parameter(ParameterSetName="FilePathComputerName",Position=0,Mandatory=$true)]
        [String]$FilePath,
    [Parameter(ParameterSetName="ComputerName",Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName="FilePathComputerName",Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName="LiteralFilePathComputerName",Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [String]$Name,
#    [Parameter(ParameterSetName="ComputerName",Mandatory=$false,ValueFromPipeline=$true)]
#    [Parameter(ParameterSetName="FilePathComputerName",Mandatory=$false,ValueFromPipeline=$true)]
#    [Parameter(ParameterSetName="LiteralFilePathComputerName",Mandatory=$false,ValueFromPipeline=$true)]
#        [PSObject]$InputObject,
    [Parameter(ParameterSetName="ComputerName",Mandatory=$false,ValueFromRemainingArguments=$true)]
    [Parameter(ParameterSetName="FilePathComputerName",Mandatory=$false,ValueFromRemainingArguments=$true)]
    [Parameter(ParameterSetName="LiteralFilePathComputerName",Mandatory=$false,ValueFromRemainingArguments=$true)]
        [Alias("Args")][Object[]]$ArgumentList
)
begin {
    switch ($PSCmdlet.ParameterSetName) {
        "FilePathComputerName" {
            $originalOFS=$OFS
            $OFS="`n"
            $ScriptBlock=[ScriptBlock]::Create((Get-Content -Path $FilePath -ErrorAction Stop))
            $OFS=$originalOFS
        }
        "LiteralFilePathComputerName" {
            $originalOFS=$OFS
            $OFS="`n"
            $ScriptBlock=[ScriptBlock]::Create((Get-Content -LiteralPath $LiteralPath -ErrorAction Stop))
            $OFS=$originalOFS
        }
    }
}
process {
    $Job=New-Object PoShAdmin.Job -ArgumentList $Name;
    $null=$Job.PowerShell.AddScript($ScriptBlock)
#    if ($InputObject) {
#        $null=$Job.PowerShell.AddParameter("input",$InputObject)
#    }
    foreach($argument in $ArgumentList) {
        $null=$Job.PowerShell.AddArgument($argument)
    }
    [PoShAdmin.Jobs]::Add($Job)
    $Job
}
}

function Get-PoShJob
{
<#
.SYNOPSIS
Gets PoShAdmin background jobs that are running in the current session.

.DESCRIPTION
The Get-PoShJob cmdlet gets objects that represent the background jobs that were started in the current session. You can use Get-PoShJob to get jobs that were started by using the Start-PoShJob cmdlet.

Without parameters, a "Get-PoShJob" command gets all jobs in the current session. You can use the parameters of Get-PoShJob to get particular jobs.

The job object that Get-PoShJob returns contains useful information about the job, but it does not contain the job results. To get the results, use the Receive-PoShJob cmdlet.

A PoShAdmin job is a command that runs "in the background" without interacting with the current session. Typically, you use a background job to run a complex command that takes a long time to complete. For more information about background jobs in Windows PowerShell, see about_PoShJobs.

.PARAMETER Id

Gets only jobs with the specified IDs.

The ID is an integer that uniquely identifies the job within the current session. It is easier to remember and to type than the instance ID, but it is unique only within the current session. You can type one or more IDs (separated by commas). To find the ID of a job, type "Get-PoShJob" without parameters.

.PARAMETER InstanceId

Gets jobs with the specified instance IDs. The default is all jobs.

An instance ID is a GUID that uniquely identifies the job on the computer. To find the instance ID of a job, use Get-PoShJob.

.PARAMETER Name

Gets the job with the specified friendly names. Enter a job name, or use wildcard characters to enter a job name pattern. By default, Get-PoShJob gets all jobs in the current session.

.PARAMETER State

Gets only jobs in the specified state. Valid values are NotStarted, Running, Completed, Failed, Stopped. By default, Get-PoShJob gets all the jobs in the current session.

.INPUTS

The input type is the type of the objects that you can pipe to the cmdlet.

None
    You cannot pipe input to this cmdlet.

.OUTPUTS

The output type is the type of the objects that the cmdlet emits.

PoShAdmin.Job
    Get-PoShJob returns objects that represent the jobs in the session.

.EXAMPLE
Get-PoshJob

This command gets all background jobs started in the current session. It does not include jobs created in other sessions, even if the jobs run on the local computer.

.EXAMPLE
Get-PoShJob -State NotStarted

This command gets only those jobs that have been created but have not yet been started.

.EXAMPLE
Get-PoShJob -name Job*

This command gets all jobs that have job names beginning with "job". Because "job<number>" is the default name for a job, this command gets all jobs that do not have an explicitly assigned name.

.LINK
http://PoShAdmin.Net
Start-PoShJob
Stop-PoSh
Receive-PoShJob
Wait-PoShJob
Remove-PoShJob
#>
[CmdletBinding(DefaultParameterSetName="SessionIdParameterSet")]
param(
    [Parameter(ParameterSetName="SessionIdParameterSet",Position=0,Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Int32[]]$Id,
    [Parameter(ParameterSetName="InstanceIdParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Guid[]]$InstanceId,
    [Parameter(ParameterSetName="NameParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]$Name,
    [Parameter(ParameterSetName="StateParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [PoShAdmin.JobState]$State
)
process {
    switch ($PSCmdlet.ParameterSetName) {
        "SessionIdParameterSet" {
            if ($PSBoundParameters.ContainsKey("Id")) {
                [PoShAdmin.Jobs]::GetJobs($Id)
            }
            else
            {
                [PoShAdmin.Jobs]::GetJobs()
            }
        }
        "InstanceIdParameterSet" {[PoShAdmin.Jobs]::GetJobs($InstanceId)}
        "NameParameterSet" {[PoShAdmin.Jobs]::GetJobs($Name)}
        "StateParameterSet" {[PoShAdmin.Jobs]::GetJobs($State)}
    }
}
}

function Receive-PoShJob
{
<#
.SYNOPSIS
Gets the results of the PoShAdmin background jobs in the current session.

.DESCRIPTION
The Receive-PoShJob cmdlet gets the results of PoShAdmin background jobs, such as those started by using the Start-PoShJob cmdlet. You can get the results of all jobs or identify jobs by their name, ID, instance ID, or by submitting a PoShAdmin job object.

When you start a PoShAdmin background job, the job starts, but the results do not appear immediately. Instead, the command returns an object that represents the background job. The job object contains useful information about the job, but it does not contain the results. This method allows you to continue working in the session while the job runs. For more information about background jobs in PoShAdmin, see about_PoShJobs.

The Receive-PoShJob cmdlet gets all the results generated by the job. If the results are not yet complete, the cmdlet returns nothing. You can run additional Receive-PoShJob commands to get the results at a later time.

By default, job results are deleted from the system when you receive them, but you can use the Keep parameter to save the results so that you can receive them again. To delete the job results, run the Receive-PoShJob command again (without the Keep parameter), close the session, or use the Remove-PoShJob cmdlet to delete the job from the session.

.PARAMETER Id
Gets the results of jobs with the specified IDs. The default is all jobs in the current session.

The ID is an integer that uniquely identifies the job within the current session. It is easier to remember and type than the instance ID, but it is unique only within the current session. You can type one or more IDs (separated by commas). To find the ID of a job, type "Get-PoShJob" without parameters.

.PARAMETER InstanceId
Gets the results of jobs with the specified instance IDs. The default is all jobs in the current session.

An instance ID is a GUID that uniquely identifies the job on the computer. To find the instance ID of a job, use the Get-PoShJob cmdlet.

.PARAMETER Job
Specifies the job for which results are being retrieved. This parameter is required in a Receive-PoShJob command. Enter a variable that contains the job or a command that gets the job. You can also pipe a job object to Receive-PoShJob.

.PARAMETER Keep
Saves the job results in the system, even after you have received them. By default, the job results are deleted when they are retrieved.

To delete the results, use Receive-PoShJob to receive them again without the Keep parameter, close the session, or use the Remove-PoShJob cmdlet to delete the job from the session.

.PARAMETER Name
Gets the results of jobs with the specified friendly name. Wildcards are supported. The default is all jobs in the current session.

.PARAMETER Wait
Suppresses the command prompt until the job results are received. By default, Receive-PoShJob immediately returns with the results of finished jobs.

By default, the Wait parameter waits until the job is in one of the following states: Completed, Failed, Stopped.

.PARAMETER AutoRemoveJob
Deletes the job after returning the job results. Contrary to the built-in Receive-Job function, AutoRemoveJob is not dependent on the Wait parameter in Receive-PoShJob. If AutoRemoveJob is set without the Wait parameter, the job will be automatically removed if it was finished during the execution. If the job is not finished yet, AutoRemoveJob has no effect.

.INPUTS
The input type is the type of the objects that you can pipe to the cmdlet.

PoShAdmin.Job
    You can pipe job objects to Receive-PoShJob.

.OUTPUTS
The output type is the type of the objects that the cmdlet emits.

PSObject
    Receive-PoShJob returns the results of the commands in the job.
.EXAMPLE
$job = Start-PoShJob -ScriptBlock {Get-Process}; Receive-PoShJob -Job $job

These commands use the Job parameter of Receive-PoShJob to get the results of a particular job.

The first command uses the Start-PoShJob cmdlet to start a job that runs a Get-Process command. The command uses the assignment operator (=) to save the resulting job object in the $job variable.
The second command uses the Receive-PoShJob cmdlet to get the results of the job. It uses the Job parameter to specify the job.
 .LINK
http://PoShAdmin.Net
Start-PoShJob
Get-PoShJob
Stop-PoSh
Wait-PoShJob
Remove-PoShJob
#>
[CmdletBinding(DefaultParameterSetName="Location")]
param(
    [Parameter(ParameterSetName="Location",Position=0,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName="ComputerName",Position=0,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [PoshAdmin.Job[]]$Job,
#    [Parameter(ParameterSetName="ComputerName",Position=1,Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
#        [Alias('Cn')][String[]]$ComputerName,
    [Parameter(ParameterSetName="InstanceIdParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Guid[]]$InstanceId,
    [Parameter(ParameterSetName="NameParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]$Name,
    [Parameter(ParameterSetName="SessionIdParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Int32[]]$Id,
#TODO decide if I want this
#    [Parameter(ParameterSetName="PoShAllSet",Mandatory=$false)]
#        [Switch]$All,
    [Parameter(ParameterSetName="Location",Mandatory=$false)]
    [Parameter(ParameterSetName="ComputerName",Mandatory=$false)]
    [Parameter(ParameterSetName="InstanceIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="NameParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="SessionIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="PoShAllSet",Mandatory=$false)]
        [Switch]$Keep,
    [Parameter(ParameterSetName="Location",Mandatory=$false)]
    [Parameter(ParameterSetName="ComputerName",Mandatory=$false)]
    [Parameter(ParameterSetName="InstanceIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="NameParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="SessionIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="PoShAllSet",Mandatory=$false)]
        [Switch]$Wait,
    [Parameter(ParameterSetName="Location",Mandatory=$false)]
    [Parameter(ParameterSetName="ComputerName",Mandatory=$false)]
    [Parameter(ParameterSetName="InstanceIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="NameParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="SessionIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="PoShAllSet",Mandatory=$false)]
        [Switch]$AutoRemoveJob
)
process{
#    if ($ComputerName) {
#        #TODO dosomethingaboutit
#    }
    switch ($PSCmdlet.ParameterSetName) {
        "Location" {if ($Job) {[PoShAdmin.Jobs]::Receive($Job,$Keep,$Wait,$AutoRemoveJob)}}
        "ComputerName" {if ($Job) {[PoShAdmin.Jobs]::Receive($Job,$Keep,$Wait,$AutoRemoveJob)}}
        "InstanceIdParameterSet" {[PoShAdmin.Jobs]::Receive($InstanceId,$Keep,$Wait,$AutoRemoveJob)}
        "NameParameterSet" {[PoShAdmin.Jobs]::Receive($Name,$Keep,$Wait,$AutoRemoveJob)}
        "SessionIdParameterSet" {[PoShAdmin.Jobs]::Receive($Id,$Keep,$Wait,$AutoRemoveJob)}
#        "PoShAllSet" {[PoShAdmin.Jobs]::Receive($Keep,$Wait,$AutoRemoveJob)}
    }
}
}

function Stop-PoShJob
{
<#
.SYNOPSIS
Stops a Windows PowerShell background job.
.DESCRIPTION
The Stop-PoShJob cmdlet stops PoShAdmin background jobs that are in progress. You can use this cmdlet to stop all jobs or stop selected jobs based on their name, ID, instance ID, or state, or by passing a job object to Stop-PoShJob.

You can use Stop-PoShJob to stop background jobs, such as those that were started by using the Start-PoShJob cmdlet. When you stop a background job, PoShAdmin forces the job to a halt. There will be no output for Receive-PoShJob and the job state changes to Failed.

This cmdlet does not delete background jobs. To delete a job, use the Remove-PoShJob cmdlet.
.PARAMETER Id
Stops jobs with the specified IDs. The default is all jobs in the current session.

The ID is an integer that uniquely identifies the job within the current session. It is easier to remember and type than the InstanceId, but it is unique only within the current session. You can type one or more IDs (separated by commas). To find the ID of a job, type "Get-PoShJob" without parameters.
.PARAMETER InstanceId
Stops only jobs with the specified instance IDs. The default is all jobs.

An instance ID is a GUID that uniquely identifies the job on the computer. To find the instance ID of a job, use Get-PoShJob.
.PARAMETER Job
Specifies the jobs to be stopped. Enter a variable that contains the jobs or a command that gets the jobs. You can also use a pipeline operator to submit jobs to the Stop-PoShJob cmdlet. By default, Stop-PoShJob deletes all jobs that were started in the current session.
.PARAMETER Name
Stops only the jobs with the specified friendly names. Enter the job names in a comma-separated list or use wildcard characters (*) to enter a job name pattern. By default, Stop-PoShJob stops all jobs created in the current session.

Because the friendly name is not guaranteed to be unique, use the WhatIf and Confirm parameters when stopping jobs by name.
.PARAMETER PassThru
Returns an object representing the new background job. By default, this cmdlet does not generate any output.
.PARAMETER State
Stops only jobs in the specified state. Valid values are NotStarted, Running, Completed, Failed.
.PARAMETER Confirm
Prompts you for confirmation before running the cmdlet.
.PARAMETER WhatIf
Shows what would happen if the cmdlet runs. The cmdlet is not run.
.INPUTS
The input type is the type of the objects that you can pipe to the cmdlet.

PoShAdmin.Job
    You can pipe a job object to Stop-Job.
.OUTPUTS
The output type is the type of the objects that the cmdlet emits.

None or PoShAdmin.Job
    When you use the PassThru parameter, Stop-PoShJob returns a job object. Otherwise, this cmdlet does not generate any output.
.EXAMPLE
Stop-Job -Name Job1

This command stops the Job1 background job.
.EXAMPLE
Stop-Job -ID 1, 3, 4

This command stops three jobs. It identifies them by their IDs.
.EXAMPLE
Get-Job | Stop-Job

This command stops all of the background jobs in the current session.
.NOTES
.LINK
http://PoShAdmin.Net
Start-PoShJob
Get-PoShJob
Receive-PoShJob
Wait-PoShJob
Remove-PoShJob
#>
[CmdletBinding(DefaultParameterSetName="SessionIdParameterSet",SupportsShouldProcess=$true)]
param(
    [Parameter(ParameterSetName="SessionIdParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Int32[]]$Id,
    [Parameter(ParameterSetName="InstanceIdParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Guid[]]$InstanceId,
    [Parameter(ParameterSetName="JobParameterSet",Position=0,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [PoShAdmin.Job[]]$Job,
    [Parameter(ParameterSetName="NameParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]$Name,
    [Parameter(ParameterSetName="StateParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [PoShAdmin.JobState]$State,
    [Parameter(ParameterSetName="SessionIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="InstanceIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="JobParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="NameParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="StateParameterSet",Mandatory=$false)]
        [Switch]$PassThru
)
process {
    switch ($PSCmdlet.ParameterSetName) {
        "SessionIdParameterSet" {
            if ($PSCmdlet.ShouldProcess("PoShAdmin Job ID(s) $Id")) {
                [PoShAdmin.Jobs]::Stop($Id,$PassThru)
            }
        }
        "InstanceIdParameterSet" {
            if ($PSCmdlet.ShouldProcess("PoShAdmin Job InstanceID(s) $InstanceId")) {
                [PoShAdmin.Jobs]::Stop($InstanceId,$PassThru)
            }
        }
        "JobParameterSet" {
            if ($PSCmdlet.ShouldProcess("PoShAdmin Job(s)")) {
                [PoShAdmin.Jobs]::Stop($Job,$PassThru)
            }
        }
        "NameParameterSet" {
            if ($PSCmdlet.ShouldProcess("PoShAdmin Job Name(s) $Name")) {
                [PoShAdmin.Jobs]::Stop($Name,$PassThru)
            }
        }
        "StateParameterSet" {
            if ($PSCmdlet.ShouldProcess("PoShAdmin Job State $State")) {
                [PoShAdmin.Jobs]::Stop($State,$PassThru)
            }
        }
    }
}
}

function Wait-PoShJob
{
<#
.SYNOPSIS
Suppresses the command prompt until one or all of the PoShAdmin background jobs running in the session are complete.
.DESCRIPTION
The Wait-PoShJob cmdlet waits for PoShAdmin background jobs to complete before it displays the command prompt. You can wait until any background job is complete, or until all background jobs are complete, and you can set a maximum wait time for the job.

When the commands in the job are complete, Wait-PoShJob displays the command prompt and returns a job object so that you can pipe it to another command.

You can use Wait-PoShJob cmdlet to wait for background jobs, such as those that were started by using the Start-PoShJob cmdlet. For more information about PoShAdmin background jobs, see about_PoShJobs.
.PARAMETER Any
Displays the command prompt (and returns the job object) when any job completes. By default, Wait-PoShJob waits until all of the specified jobs are complete before displaying the prompt.
.PARAMETER Id
Waits for jobs with the specified IDs.

The ID is an integer that uniquely identifies the job within the current session. It is easier to remember and type than the InstanceId, but it is unique only within the current session. You can type one or more IDs (separated by commas). To find the ID of a job, type "Get-PoShJob" without parameters.
.PARAMETER InstanceId
Waits for jobs with the specified instance IDs. The default is all jobs.

An instance ID is a GUID that uniquely identifies the job on the computer. To find the instance ID of a job, use Get-PoShJob.
.PARAMETER Job
Waits for the specified jobs. Enter a variable that contains the job objects or a command that gets the job objects. You can also use a pipeline operator to send job objects to the Wait-PoShJob cmdlet. By default, Wait-PoShJob waits for all jobs created in the current session.
.PARAMETER Name
Waits for jobs with the specified friendly name.
.PARAMETER State
Waits only for jobs in the specified state. Valid values are NotStarted, Running, Completed, Failed.
.PARAMETER Timeout
Determines the maximum wait time for each background job, in seconds. The default, 0, waits until the job completes, no matter how long it runs. The timing starts when you submit the Wait-PoShJob command, not the Start-PoShJob command.
If this time is exceeded, the wait ends and the command prompt returns, even if the job is still running. No error message is displayed.
.INPUTS
The input type is the type of the objects that you can pipe to the cmdlet.

PoShAdmin.Job
    You can pipe a job object to Wait-PoShJob.
.OUTPUTS
The output type is the type of the objects that the cmdlet emits.
PoShAdmin.Job
    Wait-PoShJob returns job objects that represent the completed jobs. If the wait ends because the value of the Timeout parameter is exceeded, Wait-PoShJob does not return any objects.
.EXAMPLE
Get-PoShJob | Wait-PoShJob

This command waits for all of the background jobs running in the session to complete.
.EXAMPLE
Wait-Job -id 1,2,5 -Any

This command identifies three jobs by their IDs and waits until any of them are complete. The command prompt returns when the first job completes.
.EXAMPLE
Wait-Job -Name DailyLog -Timeout 120

This command waits 120 seconds (two minutes) for the DailyLog job to complete. If the job does not complete in the next two minutes, the command prompt returns anyway, and the job continues to run in the background.
.EXAMPLE
Wait-Job -Name Job3

This Wait-PoShJob command uses the job name to identify the job to wait for.
.NOTES
.LINK
http://PoShAdmin.Net
Start-PoShJob
Get-PoShJob
Stop-PoSh
Receive-PoShJob
Remove-PoShJob
#>
[CmdletBinding(DefaultParameterSetName="SessionIdParameterSet")]
param(
    [Parameter(ParameterSetName="SessionIdParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Int32[]]$Id,
    [Parameter(ParameterSetName="InstanceIdParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Guid[]]$InstanceId,
    [Parameter(ParameterSetName="JobParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [PoShAdmin.Job[]]$Job,
    [Parameter(ParameterSetName="NameParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]$Name,
    [Parameter(ParameterSetName="StateParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [PoShAdmin.JobState]$State,
    [Parameter(ParameterSetName="SessionIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="InstanceIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="JobParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="NameParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="StateParameterSet",Mandatory=$false)]
        [Switch]$Any,
    [Parameter(ParameterSetName="SessionIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="InstanceIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="JobParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="NameParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="StateParameterSet",Mandatory=$false)]
        [Alias("TimeoutSec")][Int32]$Timeout = 0
)
process {
    switch ($PSCmdlet.ParameterSetName) {
        "SessionIdParameterSet" {[PoShAdmin.Jobs]::Wait($Id,$Any,$Timeout)}
        "InstanceIdParameterSet" {[PoShAdmin.Jobs]::Wait($InstanceId,$Any,$Timeout)}
        "JobParameterSet" {[PoShAdmin.Jobs]::Wait($Job,$Any,$Timeout)}
        "NameParameterSet" {[PoShAdmin.Jobs]::Wait($Name,$Any,$Timeout)}
        "StateParameterSet" {[PoShAdmin.Jobs]::Wait($State,$Any,$Timeout)}
    }
}
}

function Remove-PoShJob
{
<#
.SYNOPSIS
Deletes a PoShAdmin background job.
.DESCRIPTION
The Remove-PoShJob cmdlet deletes PoShAdmin background jobs that were started by using the Start-PoShJob.

You can use this cmdlet to delete all jobs or delete selected jobs based on their name, ID, instance ID, or state, or by passing a job object to Remove-PoShJob. Without parameters or parameter values, Remove-PoShJob has no effect.
Before deleting a running job, use the Stop-PoShJob cmdlet to stop the job. If you try to delete a running job, the command fails. You can use the Force parameter of Remove-PoShJob to delete a running job.
If you do not delete a background job, the job remains in the global job cache until you close the session in which the job was created.
.PARAMETER Force
Deletes the job even if the status is "Running". Without the Force parameter, Remove-PoShJob does not delete running jobs.
.PARAMETER Id
Deletes background jobs with the specified IDs.

The ID is an integer that uniquely identifies the job within the current session. It is easier to remember and type than the instance ID, but it is unique only within the current session. You can type one or more IDs (separated by commas). To find the ID of a job, type "Get-PoShJob" without parameters.
.PARAMETER InstanceId
Deletes jobs with the specified instance IDs.

An instance ID is a GUID that uniquely identifies the job on the computer. To find the instance ID of a job, use Get-PoShJob or display the job object.
.PARAMETER Job
Specifies the jobs to be deleted. Enter a variable that contains the jobs or a command that gets the jobs. You can also use a pipeline operator to submit jobs to the Remove-PoShJob cmdlet.
.PARAMETER Name
Deletes only the jobs with the specified friendly names. Wildcards are permitted.

Because the friendly name is not guaranteed to be unique, even within the session, use the WhatIf and Confirm parameters when deleting jobs by name.
.PARAMETER State
Deletes only jobs with the specified status. Valid values are Valid values are NotStarted, Running, Completed, Failed, Stopped. To delete jobs with a state of Running, use the Force parameter.
.PARAMETER Confirm
Prompts you for confirmation before running the cmdlet.
.PARAMETER WhatIf
Shows what would happen if the cmdlet runs. The cmdlet is not run.
.INPUTS
The input type is the type of the objects that you can pipe to the cmdlet.

PoShAdmin.Job
    You can pipe a job object to Remove-PoShJob.
.OUTPUTS
The output type is the type of the objects that the cmdlet emits.

None
    This cmdlet does not generate any output.
.EXAMPLE
Get-PoShJob | Remove-Job

This command deletes all of the jobs in the current session.
.EXAMPLE
Remove-Job -State NotStarted

This command deletes all jobs from the current session that have not yet been started.
.EXAMPLE
Remove-Job -Name *batch -Force

This command deletes all jobs with friendly names that end with "batch" from the current session, including jobs that are running.

It uses the Name parameter of Remove-PoShJob to specify a job name pattern, and it uses the Force parameter to ensure that all jobs are removed, even those that might be in progress.
.NOTES
.LINK
http://PoShAdmin.Net
Start-PoShJob
Get-PoShJob
Stop-PoSh
Receive-PoShJob
Wait-PoShJob
#>
[CmdletBinding(DefaultParameterSetName="SessionIdParameterSet",SupportsShouldProcess=$true)]
param(
    [Parameter(ParameterSetName="SessionIdParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Int32[]]$Id,
    [Parameter(ParameterSetName="InstanceIdParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Guid[]]$InstanceId,
    [Parameter(ParameterSetName="JobParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [PoShAdmin.Job[]]$Job,
    [Parameter(ParameterSetName="NameParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]$Name,
    [Parameter(ParameterSetName="StateParameterSet",Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [PoShAdmin.JobState]$State,
    [Parameter(ParameterSetName="SessionIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="InstanceIdParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="JobParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="NameParameterSet",Mandatory=$false)]
    [Parameter(ParameterSetName="StateParameterSet",Mandatory=$false)]
        [Alias('F')][Switch]$Force
)
process {
    switch ($PSCmdlet.ParameterSetName) {
        "SessionIdParameterSet" {
            if ($PSCmdlet.ShouldProcess("PoShAdmin Job ID(s) $Id")) {
                [PoShAdmin.Jobs]::Remove($Id,$Force)
            }
        }
        "InstanceIdParameterSet" {
            if ($PSCmdlet.ShouldProcess("PoShAdmin Job InstanceID(s) $InstanceId")) {
                [PoShAdmin.Jobs]::Remove($InstanceId,$Force)
            }
        }
        "JobParameterSet" {
            if ($PSCmdlet.ShouldProcess("PoShAdmin Job(s)")) {
                [PoShAdmin.Jobs]::Remove($Job,$Force)
            }
        }
        "NameParameterSet" {
            if ($PSCmdlet.ShouldProcess("PoShAdmin Job Name(s) $Name")) {
                [PoShAdmin.Jobs]::Remove($Name,$Force)
            }
        }
        "StateParameterSet" {
            if ($PSCmdlet.ShouldProcess("PoShAdmin Job State $State")) {
                [PoShAdmin.Jobs]::Remove($State,$Force)
            }
        }
    }
}
}
