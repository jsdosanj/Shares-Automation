#requires -version 2
<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
  <This is where the user would enter their name, university email, and what shares they would like access to>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
  <This is where the the script would read the inputs and verify that the user is allowed access to the drive they are requesting.>
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
  $Share = Read-Host -Prompt 'Input the Share name you are requesting'
  $UserName = Read-Host -Prompt 'Input your Full Name'
  $Uni_Email = Read-Host =-Prompt 'Input your Oakland University Email'
  $Date = Get-Date
  Write-Host "You input server '$Share' and '$Username'  and '$Uni_Email' on '$Date'" 
  

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Temp"
$sLogName = "<script_name>.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#-----------------------------------------------------------[Functions]------------------------------------------------------------

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
$UserName = Read-Host -Prompt 'Please enter your first and last name'
if ($UserName) {
    Write-Host "You are: [$UserName]"
}
function findUser ([string]$UserName)
{
 Get-ADUser -filter "name -like '$UserName*'" -properties ipphone | ft Name, ipphone
}

$Share = Read-Host -Prompt 'Server name to process'
if ($Share) {
	Write-Host "You have requested access to the [$Share] share."
} else {
	Write-Warning -Message "Please enter the correct Shares name."
}
function findShare ([string]$Share)
{
 Get-ADUser -filter "name -like '$Share*'" -properties ipphone | ft Name, ipphone
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
#Script Execution goes here
#Log-Finish -LogPath $sLogFile