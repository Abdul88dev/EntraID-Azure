Connect-Graph -Scopes "User.Read.All", "Directory.Read.All", "UserAuthenticationMethod.Read.All"
$createdDate= (Get-date).AddMonths(-3)
$users = Get-MgUser -All -Filter "accountEnabled eq true and userType eq 'Member'" -Property id,DisplayName,UserPrincipalName,OnPremisesSyncEnabled,CreatedDateTime |Where-Object { $_.OnPremisesSyncEnabled -eq $true} #-and $_.CreatedDateTime -ge $createdDate}

$newUsers = @()
foreach($user in $users){
    if(Get-MgUserAuthenticationMethod -UserId $user.id | where { $_.AdditionalProperties["@odata.type"]  -eq "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" -or $_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.fido2AuthenticationMethod"} ){
        write-host "$($user.DisplayName) Has Mfa Enabeld" 
    $newUsers += [PSCustomObject]@{
        DisplayName = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        MFAEnable = $true
}
    }else
    {
        write-host "$($user.DisplayName) Has Mfa not activated"
         $newUsers += [PSCustomObject]@{
        DisplayName = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        MFAEnable = $false
}
    }
}


$newUsers |export-csv .\mfausersAll.csv
