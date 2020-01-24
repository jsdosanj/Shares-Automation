#Requires -Version 3.0
function get-ouServer {

<#
.SYNOPSIS
    Gets information about servers at OU from varus sorces and compiles them
 
.EXAMPLE
     get-ouServer
 
.OUTPUTS
    PSCustomObject
 
.NOTES
    Author:  Eric Stevens
#>

    [CmdletBinding()]
    [OutputType('PSCustomObject')]
    param (
        [string]$computerName 
    )

    BEGIN {
        #Used for prep. This code runs one time prior to processing items specified via pipeline input.
    }

    PROCESS {
        $ADproperties = @("OperatingSystem",
        "name", 
        "description",
        "lastLogonDate",
        "Location")
        

        $domainServers = get-ouServerFromADMNET -properties $ADproperties 
        $domainServers =  $domainServers + $(get-ouServerFromOaklandDomain -properties $ADproperties)
        $domainServers =  $domainServers + $(get-ouServerFromPCIDomain -properties $ADproperties)
                        
        $wsusServers =  get-ouServerFromWindowsUpdate
        $virtualServers = get-ouServerFromVmware

        $servers = @()
        
        foreach ($domainServer in $domainServers){
            write-verbose "Inspecting: $($domainServer.name)"
            $wsusMatch = $wsusServers | ? {($_.FullDomainName -like $($domainServer.name + "*")) -or ($_.FullDomainName -eq $domain.name)} | select -first 1
            
            if ($($domainServer.name)) {
                $server = [Server]::New()
                
                $Server.name = $domainServer.name                
                $server.lastLoginDate = $domainServer.lastLogonDate
                $server.description = $domainServer.description
                $server.Location = $domainServer.location
                $server.MSsqlInfo = $domainServer.MSsqlInfo
                
                if ($wsusMatch ) {
                    write-verbose "Ading WSUS info for : $($domainServer.name)"
                    
                    $server.make = $wsusMatch.make 
                    $server.model = $wsusMatch.model
                    $server.ipAddress = $wsusMatch.ipAddress
                    $server.osDescription = $wsusMatch.OSDescription
                    $server.lastReportedStatusTime = $wsusMatch.lastReportedStatusTime
                    $server.sourceOfData = "Domain, Wsus"

                   

                } else {
                    write-verbose "No  WSUS info for : $($domainServer.name)"
                    $server.sourceOfData = "Domain"
                }
                
                $servers = $servers + $server
            }
        }
        
        foreach ($wsusServer in $wsusServers){
                 $domainServerMatch = $domainServers | ? {($wsusServer.FullDomainName -like $($_.name + "*")) -or ($wsusServer.FullDomainName -eq $_.name)} | select -first 1
                 
                 if (-not $domainServerMatch){
                    write-verbose "no match fround for Wsus server $($wsusServer.fullDomainName)"
                    
                    $server = [Server]::New()
                    
                    $Server.name = $($wsusServer.fullDomainName).split(".")[0]
                    $server.make = $wsusMatch.make 
                    $server.model = $wsusMatch.model
                    $server.ipAddress = $wsusMatch.ipAddress
                    $server.osDescription = $wsusMatch.OSDescription
                    $server.lastReportedStatusTime = $wsusMatch.lastReportedStatusTime
                    $server.sourceOfData = "wsus"
                    
                    $servers = $servers + $server
                    
                 }
        }
        
        foreach ($vmGuest in $virtualServers ){
            
            $vm = $vmGuest.vm
            $computerName = ($vmGuest.HostName).split(".")[0]
            
            $vmMatch = $servers | where-object {$_.name -eq $computerName}
            
            write-verbose "$($vmMatch).length VM matches found"
            
            if ($vmMatch){
                write-verbose "Adding Vmware info to ($vm.name)"
                $vmMatch.location = "Virtual"
                $vmMatch.poweredOn = $vmGuest.state
                $vmMatch.NumCpu = $vm.numCpu
                $vmMatch.MemoryGb = $vm.memoryGb
                $vmMatch.sourceOfData =  $vmMatch.sourceOfData + ", VMware"
              
            } else {
                write-verbose "Adding vm: $computerName to server list, no exsting match found"
                $server = [Server]::New()
                
                $server.name = $computerName
                $server.make = "VM info Only"
                $server.sourceOfData =  "VMware"
                 
                $servers = $servers + $server
            }
             
        }
                      
                        
         Write-Output $servers
        

         
    }

    END {
        #Used for cleanup. This code runs one time after all of the items specified via pipeline input are processed.
    }



}

function checkSubnet ([string]$cidr, [string]$ip)
{
    $network, [int]$subnetlen = $cidr.Split('/')
    $a = [uint32[]]$network.split('.')
    [uint32] $unetwork = ($a[0] -shl 24) + ($a[1] -shl 16) + ($a[2] -shl 8) + $a[3]

    $mask = (-bnot [uint32]0) -shl (32 - $subnetlen)

    $a = [uint32[]]$ip.split('.')
    [uint32] $uip = ($a[0] -shl 24) + ($a[1] -shl 16) + ($a[2] -shl 8) + $a[3]

    $unetwork -eq ($mask -band $uip)
}


