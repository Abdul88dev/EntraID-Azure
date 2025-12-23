Connect-Graph -scopes "User.Read.All"
$enabledUsers = Get-MgUser -All -Filter "accountEnabled eq true AND userType eq 'member'" | Where-Object {$_.DisplayName -notlike "*TEST*"  -and $_.UserPrincipalName -notlike "*#EXT*" }

$fido2Users = @()


foreach ($user in $enabledUsers) {
    $user ="r.peters@vdl.nl"
    $fido2Methods = Get-MgUserAuthenticationFido2Method -UserId $user
    $lastSignIn = Get-MgAuditLogSignIn -Filter "userId eq '$($user)' " | Where-Object { $_.authenticationDetails -like 'FIDO2*' } | Sort-Object createdDateTime -Descending | Select-Object -First 1
    foreach ($method in $fido2Methods) {
        $fido2Users += [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName       = $method.DisplayName
            Model             = $method.Model
            LastSignIn        = $lastSignIn.createdDateTime
        }
    }
}


$fido2Users | Format-Table -Property UserPrincipalName, DisplayName, Model

$fido2Users |Export-Csv .\Fidokeys1.csv -Delimiter ";" -NoTypeInformation


$lastSignIn = Get-MgAuditLogSignIn -Filter "userId eq '$($user.Id)' and authenticationMethods/any(a:a/authenticationMethod eq 'FIDO2')" | Sort-Object createdDateTime -Descending | Select-Object -First 1
