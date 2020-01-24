    
    [cmdletbinding()]
    Param(
    [Parameter()]
        [array]$Shares
    )

function main {
    
    [cmdletbinding()]
    Param(
    [Parameter()]
        [array]$Shares

    )
            #Init Default Shares Array
            $SkipShares = @('ADMIN$', 'C$', 'IPC$', 'E$')
            
            #Init Log File
            Write-Log -Status "Initialize"

            #Get List of Shares in Object
            $Shares = Get-SharesObject -Shares $Shares

            foreach ($Share in $Shares) {
        
                #Pull sharepath and name for function params
                $SharePath = $Share.Path
                $ShareName = $Share.Name
                $Computer = "Shares"

                #Do not enumerate the following Built In Shares
                if ($SkipShares.Contains($ShareName)) {

                    #If $Share equals one of the above shares do nothing.
                    #Log skipped shares
                    Write-Log -Status "Skipped" -ShareName $ShareName -Sharepath $SharePath -LogLocation $LogLocation
                    
                    #Go to next value in for loop
                    Continue
                }
            
                       
                    #Pull documents from share and sort by oldest and largest
                    $Docs = Get-Docs -Sharepath $SharePath
                    
                    #Sort Docs
                    $OldDocs = Get-DocAge $Docs
                    $SizeDocs = Get-DocSize $Docs
                    

                    #Get Share Summary Stats
                    $SumDoc = Get-ShareSummary -SharePath $SharePath -ShareName $ShareName -Docs $Docs -Computer $Computer

                    #Pull Share ACL
                    $MemberDocs = Get-ADShareAccess -Sharename $ShareName

                    #Send Shares info to be converted to HTML
                    $ShareReport = Get-HTMLReport -OldDocs $OldDocs -SizeDocs $SizeDocs -MemberDocs $MemberDocs -SumDoc $SumDoc -ShareName $ShareName
            
                    #Place report in root of share
                    $Result = Write-Report -ShareReport $ShareReport -SharePath $SharePath -ShareName $ShareName

                    If ($Result) {
                        Write-Log -Status "Share" -ShareName $ShareName -Sharepath $SharePath
                    }    
                
            }

    #Write to log that script has finished
    Write-Log -Status "Completed"

}

function Get-ShareSummary {

    param($SharePath, $ShareName, $Docs, $Computer) 

    $Size = $Docs | Measure -Property Size_in_Gb -sum

    #Create temporary custom PS object
    $SumDoc = New-Object psobject
    #Add User properties to temp custom object
    $SumDoc | Add-Member -MemberType NoteProperty -Name "Share Name" -Value $ShareName
    $SumDoc | Add-Member -MemberType NoteProperty -Name "Share Path" -Value "\\$Computer\$ShareName"
    $SumDoc | Add-Member -MemberType NoteProperty -Name "Share Size in GB" -Value (&{[math]::Round($Size.Sum, 4)})
    $SumDoc | Add-Member -MemberType NoteProperty -Name "Server" -Value $Computer

    return $SumDoc


}

function Write-report {

    param($ShareReport, $SharePath, $ShareName)

    #Create path to report
    $ReportLocation = $SharePath + "\" + $ShareName + "StorageReport.html"

    #Write report

    Try {
        out-file -InputObject $Sharereport -FilePath $ReportLocation -Force
        $Result = $True
    }
    Catch
    {
        Write-Log -Status "Write Error" -Info $Error[0] -ShareName $ShareName
        $Result = $False
    }

    return $Result
    
}

function Write-Log ($Status, $ShareName, $Sharepath, $LogLocation, $Info) {
    
    $Date = Get-Date -Format G
    
    $LogLocation = "C:\StorageReports\ShareReport_Logging\Shares_Status_Log.txt"
    #Pick Status message based on input
    If ($Status -eq "Share") {

        $Status = "Finished"
    
    } ElseIf ($Status -eq "Completed"){

        $Status = "Completed"
        $ShareName = "Shares Script"
    } ElseIf ($Status -eq "Skipped") {

        $Status = "Skipped"
    } ElseIf ($Status -eq "Initialize") {
        #Create new empty log file over old one
        #Create Header Row
        $Date = "DATE `t `t "
        $Status = "STATUS"
        $ShareName = "SHARENAME"
        $SharePath = "INFO"
        $NULL | Out-File $LogLocation -Force
    } ElseIf ($Status -eq "Write Error") {
        $Sharepath = $Info
        $Status = "Write Error"
    }

    $Message = "$Date `t $Status `t $ShareName `t $SharePath"
            
    #Output Status message
    $Message | Out-File -Append -FilePath $LogLocation

}


function Get-HTMLReport {

    param($OldDocs, $SizeDocs, $MemberDocs, $SumDoc, $ShareName)
            
            #Get date for report header
            $Date = get-date -format d
    
            #Convert reports to HTML
            $SizeHTML = $SizeDocs | ConvertTo-Html -PreContent '<h2>Files by Largest Size</h2>' | Out-String
            $OldHTML = $OldDocs | ConvertTo-Html -PreContent '<h2>Files by Oldest Write Time</h2>' | Out-String
            $MembersHTML = $MemberDocs | ConvertTo-Html -PreContent '<h2>Share Access Control List</h2>' | Out-String
            $SumHTML = $SumDoc | ConvertTo-Html -PreContent '<h2>Share Summary</h2>' | Out-String

            #Set CSS

            #Create header
            $Header = @"
<title>$ShareName Storage Report</title>
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
TR:Nth-Child(Even) {Background-Color: #dddddd;}
</style>
"@
            #Return report after converted to HTML 
            return (ConvertTo-Html -Head $header -PostContent $SumHTML, $MembersHTML, $OldHTML, $SizeHTML -PreContent "<h1>$ShareName Storage Report - $Date</h1>" | Out-String)
            
}

function Get-ADShareAccess {

    param($ShareName)

    #Pull ACL List for Share name with desired properties
    $ShareACL = Get-SmbShareAccess $ShareName | Select-object -Property AccountName, AccessControlType, AccessRight

    #Initilize Custom Array for Membership List
    $ShareMembers = @()
        
    foreach ($Member in $ShareACL) {
        
        #Pull base username from group object
        #Pull Permissions
        $MemberAccess = $Member.AccessRight
        $Member = $Member.accountname
        

        #Only search for ADMNET domain users
        if ($Member -like "ADMNET\*") {

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
                
                $ADMembers = Get-ADGroupMember -Identity $Member -Recursive | Get-aduser                
            }

             foreach ($ADMember in $ADMembers) {

                    #Create temporary custom PS object
                    $TempObj = New-Object psobject
                    #Add User properties to temp custom object
                    $TempObj | Add-Member -MemberType NoteProperty -Name Name -Value $ADMember.Name
                    $TempObj | Add-Member -MemberType NoteProperty -Name ADMNET-ID -Value $ADMember.SamAccountName
                    $TempObj | Add-Member -MemberType NoteProperty -Name Permissions -Value $MemberAccess

                    #Add temp object to $ShareMembers
                    $ShareMembers += $TempObj

            }

         } elseif ($Member -eq "Everyone") {

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

function Get-SharesObject {

    
    param($Shares)
    $Result = @()

    #Grab list of shares
    #If shares list is empty grab all the shares
    if (!$shares) {
        
       $Result = Get-SmbShare

    }
    #Grab only specified shares
    else {
       
       
       foreach ($Share in $Shares) {

            [array]$Result += Get-SmbShare -Name $Share
            
        }
    }
    
    return $Result
}

function Get-Docs {
    
    param($SharePath)

    #Run a recursive get-childitem for the specified share path
    
    $Docs = Get-ChildItem -Path $SharePath -Recurse -ErrorAction SilentlyContinue -File | Select-Object -Property Name, @{l="Location";e={$_.FullName}}, LastAccessTime, @{l="Size_in_GB"; e={[math]::Round(($_.length / 1Gb), 4)}}
    
    return $Docs

}


function Get-DocSize  {
    
    param($Docs)

    #Sort docs by size (MB) and select name, directory, lastaccesstime and size and item type
    $SizeDocs = $Docs | Sort-Object Size_in_GB -Descending | Select-Object -Property Name, Location, LastAccessTime, Size_in_GB -First 15
            #Sort-Object Size_in_GB -Descending | Select-Object -Property Name, Location, LastWriteTime, Size_in_GB -First 15

    return $SizeDocs

}


function Get-DocAge {

    param($Docs)

    #Sort docs by lastaccesstime (age) and select name, directory, lastaccesstime and size and item type
    $OldDocs = $Docs | Sort-Object LastAccessTime | Select-Object -Property Name, Location, LastAccessTime, Size_in_GB -First 15
       
    return $OldDocs


}

main -Shares $Shares
