<#
.SYNOPSIS
    remove share and share related information
.PARAMETER name
    Share name

.EXAMPLE
    remove-oushare -sharename utsusers
 
.NOTES
    Author:  Eric Stevens, with a little help from my friends
#>

function remove-oushare{
[cmdletbinding()]
param(
    $shareName
)    

    #remove sbm share
    #get the share server
    $shareInfo = get-oushare $sharename -includePath
    #invoke remove-smb and dir
    Invoke-Command -computerName $shareInfo.server -scriptblock {
        param($shareName, $path)
        Remove-SmbShare -Name $shareName -force
        remove-item -path $path -recurse -force
    } -ArgumentList $shareInfo.name, $shareInfo.fileSystemPath   
   

    #remove assocaited AD groups
    $filterString=  "share_$shareName`_r`*"
    $shareGroups = get-adgroup -filter {name -like $filterString}
    foreach ($shareGroup in $shareGroups){
        Remove-ADGroup -identity $sharegroup.name -confirm:$false
    }

    #remove DFS pointer
    remove-DfsnFolder -path $shareInfo.dfsPaths -confirm:$false -force
    
    #remove from database
    remove-ouShareFromDatabase -name $sharename

}