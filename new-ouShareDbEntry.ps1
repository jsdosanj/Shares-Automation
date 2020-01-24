function new-ouShareDbEntry{
    [cmdletbinding()]
    param(
        $departmentName,
        $shareName,
        $shareServer,
        $owner
    )
    $ouEnv = get-ouEnv
    $db = $ouEnv.datastores | where name -eq "IT-resoruces"
    
    $connectionString = "Data Source=$($db.instance); " +
            "Integrated Security=SSPI; " +
            "Initial Catalog=$($db.name)"

    Write-Verbose "getting Department ID"
    $dept = get-ouResourceDepartment -deptName $departmentName
    if (($dept | measure).count -eq 1){
        write-verbose "department Name $departmentName is valide"
    } else {
        Write-Warning "Department Name $departmentName is invalid"
        Exit
    }
    $deptID = $dept.department_id
    
    Write-Verbose "creating share table entry"

    $shareInsert = "INSERT INTO dbo.share (name, server) VALUES ('$shareName', '$shareServer');"
    
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $connection.open()
    $command = new-object system.data.sqlclient.sqlcommand($shareInsert,$connection)   
    $command.ExecuteNonQuery()
    
    Write-Verbose "getting share id"
    $share_idQuery = "SELECT share_id from dbo.share WHERE  dbo.share.name = '$shareName' AND dbo.share.server = '$shareServer';"
    $command = new-object system.data.sqlclient.sqlcommand($share_idQuery,$connection)
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    $share_id = $dataSet.tables.share_id
        
    write-verbose "new Share ID is $share_id"           
    
    write-verbose "Adding to department junction"
    $deptInsert =  "INSERT INTO dbo.DepartmentShareJunction  (DepartmentID, ShareID)  VALUES ('$deptID', '$share_id');"
    $command = new-object system.data.sqlclient.sqlcommand($deptInsert,$connection)   
    $command.ExecuteNonQuery()
    
    write-verbose "Adding to department junction"
    $ownerInsert =""
    foreach ($ownerID in $owner){
        $ownerInsert = "INSERT INTO dbo.shareShareOwnerJunction (shareId, shareOwner) VALUES ('$share_id', '$ownerID');"
        $command = new-object system.data.sqlclient.sqlcommand($ownerInsert,$connection)   
        $command.ExecuteNonQuery()
    }
    
    write-verbose "running querry: $shareInsert" 
    
    $connection.close()
              
  } 