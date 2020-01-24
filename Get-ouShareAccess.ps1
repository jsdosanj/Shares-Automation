function Get-ouShareAccess {
[cmdletbinding()]
    param(
        [parameter(Position=0)]
        $ShareName = "utsdocs",

        [parameter(Position=1)]
        $serverName = "fileserver01"
    )

    #Pull ACL List for Share name with desired properties
    $ShareACL = invoke-command -ComputerName $serverName -ScriptBlock{
        param($ShareName)
         try { Get-SmbShareAccess $ShareName -ErrorAction stop | Select-object -Property AccountName, AccessControlType, AccessRight }
         catch { Get-SmbShareAccess ($ShareName + "$") -ErrorAction stop | Select-object -Property AccountName, AccessControlType, AccessRight}
    } -ArgumentList $ShareName

    #Initilize Custom Array for Membership List
    $ShareMembers = @()
        
    foreach ($Member in $ShareACL) {
        
        #Pull base username from group object
        #Pull Permissions
        $MemberAccess = $Member.AccessRight
        $Member = $Member.accountname
        

        #Only search for ADMNET domain users
        if ($Member -like "ADMNET\*" -and $Member -notlike "ADMNET\Domain Users") {

            #Strip ADMNET off and select group/user name
            $Member = ($Member.split("\"))[1]
            
            #Pull object class to distingush which commands to use           
            $Class = (Get-ADObject -Filter ('SamAccountName -eq "' + $Member + '"')).objectclass

            #If object is a user pull there AD Details and add to $ShareMembers Object
            if ($Class -eq "user") {
                
                #Get User's AD Info
                $ADMembers = Get-ADUser -Identity $Member 

            }
            #If object is a group pull recursive membership and pass through AD for user details. Add to $ShareMembers Object
            elseif ($Class -eq "group") {
                # what do do if all or everyone? 
                write-verbose "getting Group Membership $Member"
                $ADMembers = Get-ADGroupMember -Identity $Member -Recursive | Get-aduser                
            }

             foreach ($ADMember in $ADMembers) {

             if ($ADMember.Name -ne "svc_shareReport"){
                 write-verbose "admember is $admember"

                        #Create temporary custom PS object
                        $TempObj = New-Object psobject
                        #Add User properties to temp custom object
                        $TempObj | Add-Member -MemberType NoteProperty -Name Name -Value (get-aduser $ADMember.SamAccountName -Properties displayname | select -ExpandProperty displayname)
                        $TempObj | Add-Member -MemberType NoteProperty -Name ADMNET-ID -Value $ADMember.SamAccountName
                        $TempObj | Add-Member -MemberType NoteProperty -Name Permissions -Value $MemberAccess

                        #Add temp object to $ShareMembers
                        $ShareMembers += $TempObj
              }
            }

         } elseif (($Member -eq "Everyone") -or $Member -eq ("ADMNET\Domain Users")) {

                #Create temporary custom PS object
                $TempObj = New-Object psobject
                #Add User properties to temp custom object
                $TempObj | Add-Member -MemberType NoteProperty -Name Name -Value "Everyone"
                $TempObj | Add-Member -MemberType NoteProperty -Name ADMNET-ID -Value "Everyone"
                $TempObj | Add-Member -MemberType NoteProperty -Name Permissions -Value $MemberAccess

                #Add temp object to $ShareMembers
                $ShareMembers += $TempObj

         }


    }

    #Sort by unique names and create ADMNET ID field
    $ShareMembers = $ShareMembers | sort -Unique Name | Select-Object -Property Name, ADMNET-ID, Permissions
    #Pass Finalized List of $ShareMembers outside function
    return ($ShareMembers)
}

