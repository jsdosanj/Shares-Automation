function add-OUShareOwner {
    [cmdletbinding()]
    param(
        $shareName,
        $shareServer,
        $owner
    )

    $ouEnv = get-ouEnv
    $db = $ouEnv.datastores | where name -eq "IT-resoruces"
    
    $connectionString = "Data Source=$($db.instance); " +
    "Integrated Security=SSPI; " +
    "Initial Catalog=$($db.name)"

    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $connection.open()
    
    Write-Verbose "getting share id"

    $share_idQuery = "SELECT share_id from dbo.share WHERE  dbo.share.name = '$shareName' AND dbo.share.server = '$shareServer';"
    $command = new-object system.data.sqlclient.sqlcommand($share_idQuery, $connection)
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    $share_id = $dataSet.tables.share_id
        
    write-verbose "Share ID is $share_id"  
    
    write-verbose "Adding to owners"
    $ownerInsert = ""
    foreach ($ownerID in $owner) {
        $ownerInsert = "INSERT INTO dbo.shareShareOwnerJunction (shareId, shareOwner) VALUES ('$share_id', '$ownerID');"
        $command = new-object system.data.sqlclient.sqlcommand($ownerInsert, $connection)   
        $command.ExecuteNonQuery()
    }
        
    $connection.close()
              
} 