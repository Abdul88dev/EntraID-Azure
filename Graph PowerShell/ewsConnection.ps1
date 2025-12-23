

$TenantId      = "TenantID"
$ClientId      = "ClientId"
$ClientSecret  = "ClientSecret"
$TargetMailbox = "Targeet@target.com"


$Scope    = "https://outlook.office365.com/.default"
$TokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
$EwsUrl   = "https://outlook.office365.com/EWS/Exchange.asmx"


$Body = @{
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = $Scope
    grant_type    = "client_credentials"
}
$TokenResponse = Invoke-RestMethod -Uri $TokenUrl -Method POST -Body $Body
$AccessToken   = $TokenResponse.access_token


$EwsRequest = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
               xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types">
  <soap:Header>
    <t:RequestServerVersion Version="Exchange2016" />
    <t:ExchangeImpersonation>
      <t:ConnectingSID>
        <t:PrincipalName>$TargetMailbox</t:PrincipalName>
      </t:ConnectingSID>
    </t:ExchangeImpersonation>
  </soap:Header>
  <soap:Body>
    <GetFolder xmlns="http://schemas.microsoft.com/exchange/services/2006/messages">
      <FolderShape>
        <t:BaseShape>Default</t:BaseShape>
      </FolderShape>
      <FolderIds>
        <t:DistinguishedFolderId Id="inbox" />
      </FolderIds>
    </GetFolder>
  </soap:Body>
</soap:Envelope>
"@

$Headers = @{
    Authorization   = "Bearer $AccessToken"
    "Content-Type"  = "text/xml"
    "X-AnchorMailbox" = $TargetMailbox 
}

$response = Invoke-RestMethod -Uri $EwsUrl -Method POST -Headers $Headers -Body $EwsRequest
$response
