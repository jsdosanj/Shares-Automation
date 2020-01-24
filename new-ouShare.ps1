#Requires -Version 3.0
function new-OUShare {

<#
.SYNOPSIS
    Create new share

.PARAMETER name
    Share name

.EXAMPLE
    new-oushare -name mySoftware -departmentName "University Technology Services" -owner ejsteven, jdplines -writeAccessMembers crcrowley 
 
.OUTPUTS
    PSCustomObject
 
.NOTES
    Author:  Eric Stevens
#>

    [CmdletBinding()]
    [OutputType('PSCustomObject')]
    param (
        $name,
        
        [ValidateScript({$(get-ouResourceDepartment -deptName $_ | measure).count -eq 1})]
        $departmentName,

        [ValidateScript({$(get-aduser $_ | measure).count -eq 1})]
        [string[]]$owner,
        
        [ValidateScript({$(get-aduser $_ | measure).count -eq 1})]
        [string[]]$readAccessMembers,
        
        [ValidateScript({$(get-aduser $_ | measure).count -eq 1})]
        [string[]]$WriteAccessMembers,
        
         [ValidateSet('fileserver01','fileserver02')]
         [string] $server = 'fileserver01'
    )
    
    #TODO validate department name has root drive
    $deptDirName = $($departmentName.replace(" ","_"))
    
    ### Create Security Groups
    new-ouShareGroup -deptName $departmentName -shareName $name -WriteAccessMembers $WriteAccessMembers -readAccessMembers $readAccessMembers

    # Create share and and set permissions 
    new-ouSmbShare -name $name -server $server -departmentName $departmentName

    ### Add to dept drive
    $serverFqdn = [System.Net.Dns]::GetHostByName(($server)).HostName
    $sharePath = "\\$serverFqdn\$name"
    $dfsPath = join-path "\\admnet.oakland.edu\Shares\" $deptDirName
    $path = join-path $dfsPath $name 
    New-DfsnFolder -path $path -TargetPath $sharePath
        
    new-ouShareDbEntry -departmentName $departmentName -shareName $name -shareServer $server -owner $owner
}