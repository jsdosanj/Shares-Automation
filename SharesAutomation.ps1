#requires -version 2
<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
  <This script will allow users to enter their info, and the script will search the shares and 
  AD to find the user
  and give them access to the shares upon approval, and give them the access/ownership.>
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
  <This is where the user would enter their name, university email, 
  and what shares they would like access to>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
  <This is where the the script would read the inputs 
  and verify that the user is allowed access to the drive they are requesting.>
    <From there, the script would notify the correct owner(s) of the share for approval>
.NOTES
  Version:        1.0
  Author:         <Jasvant Singh Dosanjh>
  Creation Date:  <1/22/2020>
  Purpose/Change: Initial script development based on outline
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
    Input 1: Ask for user input
  #>
  $Share = Read-Host -Prompt 'What Share(S) Do You Need Access To'
    if ($Share) {
	    Write-Host "You have requested access to the [$Share] share."
    } else {
	    Write-Warning -Message "Please enter the correct Shares name."
    }
  $UserName = Read-Host -Prompt 'Input your Full Name'
  $Uni_Email = Read-Host =-Prompt 'Input your Oakland University Email'  

#---------------------------------------------------------[Initialisations]-------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
. "C:\Scripts\Functions\Logging_Functions.ps1"
$Date = Get-Date
  Write-Host "You input server '$Share' and '$Username'  and '$Uni_Email' on '$Date'"
#----------------------------------------------------------[Declarations]--------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Temp"
$sLogName = "<script_name>.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName
Invoke-Expression "$Script:psouservertools:getoushare.ps1 $argumentList"

Invoke-Item (start powershell ((Split-Path $MyInvocation.InvocationName) + "\send-ouServerNetTicket.ps1"))

#-----------------------------------------------------------[Functions]---------------------------

<#
Function <FunctionName>{
  Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process{
    Try{
      <code goes here>
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}
#>

#-----------------------------------------------------------[Execution]-----------------------

#Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
#Script Execution goes here
#Log-Finish -LogPath $sLogFile
