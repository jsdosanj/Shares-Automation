function new-ouSharereport{
[cmdletbinding()]
param(
    $deptName,
    $reportPath
)

$deptShares = get-ouShare | ? department -eq $deptName

$htmlFile = 
@'
<html>
    <head>
        <link href="http://thomasf.github.io/solarized-css/solarized-light.min.css" rel="stylesheet"></link>
        <style>
        
            table, th, td {
            border: 1px solid 
            }

            #toc_container {
                background: #f9f9f9 none repeat scroll 0 0;
                border: 1px solid #aaa;
                display: table;
                font-size: 95%;
                margin-bottom: 1em;
                padding: 20px;
                width: auto;
            }

            .toc_title {
                font-weight: 700;
                text-align: center;
            }

            #toc_container li, #toc_container ul, #toc_container ul li{
                list-style: outside none none !important;
            }
            th {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #073642; color:#2aa198 }
}
        </style>

        <title>Share report to remember</title>
    </head>
        <body>


'@



#creating TOC
$htmlFile = $htmlFile + 
@'
    <div id="toc_container">
        <p class="toc_title">Contents</p>
        <ul class="toc_list">
'@

foreach ($share in $deptShares){
    $shareTag = "#" + $($share.name).Replace(" ","_")
    $htmlFile = $htmlFile + "<li><a href='$shareTag'>$($share.name)</a></li>"
}

$htmlFile = $htmlFile + 
@'
        </ul>
    </div>
'@


$totalDeptSize = 0
$shareDetails = ""
foreach ($share in $deptShares){

$shareTag = $($share.name).Replace(" ","_")
$shareDetails = $shareDetails + "<a name='$shareTag'><h1>$($share.name)</h1></a>"
$shareDetails = $shareDetails + "<h2>Owner(s)</h2>"

    if ( $share.owner -eq "") {
        #not TESTED
        $shareDetails = $shareDetails + "<p>Unknown)</p>"
    }
    foreach ($owner in $share.owner){
        $shareDetails = $shareDetails + "<p>$owner</p>"
    }

    $shareServer = $share.server
    $shareName = $share.name

 
    $permissions = Get-ouShareAccess -serverName $shareServer -ShareName $shareName

    $shareDetails = $shareDetails + "<h2>Permissions</h2>"
   $shareDetails = $shareDetails + $($permissions | convertTo-html -Fragment)
   $sizeOfShare = get-oushareSize $share.name
   $totalDeptSize = $totalDeptSize + $sizeOfShare
   $shareDetails = $shareDetails + "<h2>Size of Share</h2><p>$sizeOfShare GB</p>"


}

$htmlFile = $htmlFile + "<h1>Summary</h1>"
$htmlFile = $htmlFile + "<ul><li>Size of Shares: $totalDeptSize GB</li>"


$htmlFile = $htmlFile + "<li>Number of Shares: $($deptShares.count)</li>"
$dollarPerGig = 2.76 # used s3 price per gig per year as market price
$AnnualmaintainanceHoursPerShare = 10 #estimate
$ItCostPerHour = 12 #mostly student work so lower then normal

$estimatedCost = $totalDeptSize * $dollarPerGig + $AnnualmaintainanceHoursPerShare * $ItCostPerHour * $deptShares.count
$htmlFile = $htmlFile + "<li>Estimated Annual Cost to the University: $(“{0:C}” -f $estimatedCost)</li></ul>"

$htmlFile = $htmlFile + $shareDetails


$htmlFile = $htmlFile + "<p> Generated on $(get-date)</p>" +
@'
        </body>
</html>
'@

$htmlFile | Out-File $reportPath

} 