Import-Module Microsoft.Graph.Reports
Connect-Graph -Scope "AuditLog.Read.All"
$devices = Import-Csv .\AFEDdevices1.csv -Delimiter ";"
$UsersArray = @()
foreach($device in $devices)
{
    $deviceDesplayName=$device.DeviceNAme
    $users = Get-MgAuditLogSignIn -Filter "(deviceDetail/displayName eq '$($deviceDesplayName)')" -Property "userDisplayName " -Top 100 |select userDisplayName
    $usersString=@()
    $countusers=1
    $seen=@{}
    $deviceType = "Not Shared"
    foreach($user in $users)
    {
        $displayname = $user.UserDisplayName
        if(-not $seen.ContainsKey($displayname))
        {
          $usersString += $displayname
          $countusers +=1
          $seen[$displayname] =$true
        }
    }
    if($countusers -gt 1){
        $deviceType ="Shared"
    }
    $UsersArray +=[PSCustomObject]@{
        DeviceName = $device.DeviceNAme
        DeviceOwner = $device.DeviceOwner
        DeviceID= $device.DeviceID
        DeviceID2= $device.DeviceID2
        UserSignIns = $usersString
        DeviceType = $deviceType
    }
}

$UsersArray |Export-Csv .\AFEDDevicesFilterd.csv -Delimiter ";"
$UsersArray|Out-File .\Atestdevice1.txt
