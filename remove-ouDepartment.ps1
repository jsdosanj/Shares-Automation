#Requires -Version 3.0 -modules ActiveDirectory

function remove-ouDepartment {

<#
.SYNOPSIS
    Remove an official Oakland University Departments
 
.DESCRIPTION
    Remove the require Orginization Units, groups, and structure for a deparment
 
.PARAMETER name
    The short name of the department

.EXAMPLE
     Remove-ouDepartment -name secs
.INPUTS
    String
 
.NOTES
    Author:  Eric Stevens
#>

    [CmdletBinding()]
    [OutputType('PSCustomObject')]
    param (
        [Parameter(Mandatory)]
        [string[]]$Deptname,
        [bool]$confirm=$true
    )

    BEGIN {
        #Used for prep. This code runs one time prior to processing items specified via pipeline input.
    }

    PROCESS {
        $ouEnv = get-ouEnv

        foreach ($name in $Deptname){
            $departmentDN = $ouEnv.ouPath | Where-Object {$_.name -eq "departments"} | select -ExpandProperty dn
            $ouIdentity = "ou=$name,$departmentDN"
            #$ouIdentity = Get-ADGroup -Identity $ouIdentity 

            $dept = get-oudepartment -deptName $name
            Remove-ADOrganizationalUnit -identity $ouIdentity -Recursive -Confirm:$confirm -ErrorAction SilentlyContinue

            # remove associated OU's

            $filter = "*_$($name)*"
            Write-Verbose "removing Default resource groups for $name using filter $filter" 
            $groupsToRemove = Get-ADGroup -filter {name -like $filter}
            Write-Verbose "Resource Groups to remove $($groupsToRemove | measure | select -ExpandProperty count)" 
            foreach ($group in $groupsToRemove){
                remove-adgroup -Identity ($group.name) -Confirm:$confirm 
            }

            # delete dept_stc Group Policy
            Remove-GPO "dept_$($Deptname)"

            #remove OU for department computers (where should any remaing computers go? Could test if empty)
            $computerDN = $ouEnv.ouPath | Where-Object {$_.name -eq "computers"} | select -ExpandProperty dn
            $ouIdentity = "ou=$($dept.longname),$computerDN"
            set-adobject -Identity $ouIdentity -ProtectedFromAccidentalDeletion:$false
            Remove-ADOrganizationalUnit  -Identity $ouIdentity -Recursive -Confirm:$confirm -ErrorAction SilentlyContinue

        }







    }

    END {
        #Used for cleanup. This code runs one time after all of the items specified via pipeline input are processed.
    }

}
