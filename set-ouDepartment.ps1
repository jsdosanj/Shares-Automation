#Requires -Version 3.0
function set-ouDepartment {

<#
.SYNOPSIS
    Brief synopsis about the function.
 
.DESCRIPTION
    Detailed explanation of the purpose of this function.
 
.PARAMETER Param1
    The purpose of param1.

.PARAMETER Param2
    The purpose of param2.
 
.EXAMPLE
     set-ouDepartment -Param1 'Value1', 'Value2'

.EXAMPLE
     set-ouDepartment -Param1 'Value1', 'Value2' -Param2 'Value'
 
.INPUTS
    String
 
.OUTPUTS
    PSCustomObject
 
.NOTES
    Author:  Eric Stevens
#>

    [CmdletBinding()]
    [OutputType('PSCustomObject')]
    param (
        [string[]]$deptName
    )

    BEGIN {
        #Used for prep. This code runs one time prior to processing items specified via pipeline input.
    }

    PROCESS {
        #can all this be in the begin?
        $ouEnv = get-ouEnv
        #This code runs one time for each item specified via pipeline input.
        if (-not $deptName){
            $deptName = Get-ADOrganizationalUnit -filter * -SearchBase $ouENV.ouPath.departments | where {$_.DistinguishedName -ne $($ouENV.ouPath.departments)} | select -ExpandProperty name

        } 

        $departments = New-Object System.Collections.ArrayList
        foreach ($name in $deptName) {
            $head="ejsteven"
            $deptOU = Get-ADOrganizationalUnit -filter {name -eq $name} -SearchBase $ouENV.ouPath.departments -Properties description,managedBy,displayName
            $properties = @{'name'=$name;
                'longName'=$($deptOU.displayName);
                'head'=$head
            }
            
            $department = New-Object -TypeName psobject -prop $properties
            $departments.add($department) | Out-Null
        }

        Write-Output $departments
        
    }

    END {
        #Used for cleanup. This code runs one time after all of the items specified via pipeline input are processed.
    }

}
