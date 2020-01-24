function get-oushareSize{
[cmdletbinding()]
param(
    $shareName
)
    $share = get-oushare $shareName

    $sizeInMb = Invoke-Command -ComputerName $share.server -ScriptBlock {
        param($share)
        $ShareName = try { Get-SmbShareAccess $Share.Name -ErrorAction stop | select -ExpandProperty name} catch {$Share.Name + "$"} 
        $path = Get-SmbShare $shareName | select -ExpandProperty path
        "{0:N2}" -f ((Get-ChildItem $path -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1GB)
    } -ArgumentList $share

    Write-Output $sizeInMb
   

}

