<#
SYNOPSIS
This script will create a clone of AD group in EntraID

DESCRIPTION
1. There will be a popups prompt to ask you to provide the The Samaccountname of the AD groupName,And provide the description of the EntraID group that would be created!
2. 
2. Enjoy the automatic proces
NOTES
General notes
This script is written by Abdulmohsen Alshalabi from IAM-Team
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

###explorer dialog to open the csv file for 
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Title = 'Select files to open'
    Filter = 'CSV files (*.csv)|*.csv'
}
$null = $FileBrowser.ShowDialog()
$fileDialouge = $FileBrowser.FileName

$file = Import-Csv $fileDialouge -Delimiter ";"

if (Get-InstalledModule Microsoft.Graph) {
   ##connecting to the Graph using a service principle.
    Connect-MgGraph -TenantID $global:tenID  -ClientSecretCredential $global:credential -NoWelcome
    
    #get the AD group to copy and the membership of het
    #$adgroupName ="TestMatrixGroup"
    foreach($item in $file){
        $adgroupName = $item.adgroupname.Trim()
        $adgroupDiscription = $item.description.Trim()
        $prefix = $item.prefix.Trim()

    
    
    $AdGroupmembers = Get-ADGroupMember -Identity $adgroupName | Get-aduser | Select-Object displayName, userPrincipalName
    #set the variables for the EntraID group
    $param = @{
        description     = $adgroupDiscription
        displayName     = $prefix+$adgroupName
        mailEnabled     = $false
        securityEnabled = $true
        mailNickname    = $false
    }
    $displayname = $param.displayName
    
    #check if the group exist in EntraID
    if (Get-MgGroup -Filter "DisplayName eq '$displayname'") {
        $EntraIDGroup = Get-MgGroup -Filter "DisplayName eq '$displayname'"
        "This group " + $displayname + " already exist!"
    }
    else {
        try {
            $EntraIDGroup = New-MgGroup @param
            "The group " + $displayname + " has been created! "
        }
        catch {
            "The Entra ID group " + $displayname + "can not be created!" 
        }
        
    }
    Start-Sleep 25
  
    #check if a group in entra ID is created the copy the membership of the AD group to EntraID Group that recently has been created!
    
        "Copying the AD group members to EntraID group"
        $AdGroupmembers | ForEach-Object {
            $userToAdd = Get-MgUser -Filter "userPrincipalName eq '$($_.userPrincipalName)' "
        
            New-MgGroupMember -GroupId $EntraIDGroup.Id -DirectoryObjectId $userToAdd.Id
        } 
    }     
}
else {
    Install-Module Microsoft.Graph -Scope AllUsers
        
}
  



