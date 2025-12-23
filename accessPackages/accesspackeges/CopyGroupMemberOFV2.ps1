<#
SYNOPSIS
This script will create a clone of AD group member Of to the EntraID group

DESCRIPTION
1. Use "Template - CopyGroupMemberOf.csv" for this script.
2. There will be a popups prompt to ask you to provide the The Samaccountname of the AD groupName,And provide the description of the EntraID group that would be created!
3. Enjoy the automatic proces.

NOTES
General notes
This script is written by Abdulmohsen Alshalabi from IAM-Team
#>


Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

###explorer dialog to open the csv file for Uitdienst
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Title = 'Select files to open'
    Filter = 'CSV files (*.csv)|*.csv'
}
$null = $FileBrowser.ShowDialog()
$fileDialouge = $FileBrowser.FileName

$file = Import-Csv $fileDialouge -Delimiter ";"

foreach($item in $file)
{
    $samaccountToCopy = $item.adgroup.Trim()
    $entraIDgroup = $item.EntraIDgroup.Trim()
    $samaccountToCopyTo = Get-ADGroup -filter "DisplayName -eq '$entraIDgroup'" |Select SamAccountName

#get the groups names.
##here is the old group


##Get the member of of the group to be copied 
try {
    $AdGroupmembersOf = Get-ADGroup $samaccountToCopy -Properties MemberOf | Select-Object -ExpandProperty MemberOf | Get-ADGroup | Select-Object Name
    $Continue = $true
}
catch {
    $Continue = $false
}
###Check if the membership has been succsessfuly fetched.and then trying to add the recently synced group to the list of the groups.
if ($Continue -eq $true ) {
    foreach ($group in $AdGroupmembersOf ) {
        try {
            Get-ADGroup $group.Name | Add-ADGroupMember -Members $samaccountToCopyTo.SamAccountName -ErrorAction Continue
            Write-Host "The group "+$samaccountToCopyTo+" Has been added to "+$group.Name
        }
        catch {
            "The Group " + $samaccountToCopyTo + " Can't be added to " + $group.Name
        }
        
    }
}

}

