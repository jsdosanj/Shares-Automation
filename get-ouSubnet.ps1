#Requires -Version 3.0
function get-ouSubnet {

<#
.SYNOPSIS
    Gets the vlan for a given ip address
 
.EXAMPLE
     get-ouSubnet -ipAddress 141.210.8.150
 
.OUTPUTS
    PSCustomObject
 
.NOTES
    Author:  Eric Stevens
#>

    [CmdletBinding()]
    [OutputType('PSCustomObject')]
    param (
        $ipAddress
    )

    BEGIN {
        #Used for prep. This code runs one time prior to processing items specified via pipeline input.
    }

    PROCESS {
        $ouEnv = get-ouEnv
        foreach ($vlan in $OuEnv.vlans){

            if (checkSubnet $vlan.range $ipAddress){
                return $vlan
            }


        }
        

        $ouEnv = New-Object -TypeName psobject -prop $properties
         Write-Output $ouEnv
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


