<#
SYNOPSIS
This script checks for each user from the functional groups if they have been added to the Access Packages. If so, delete them from the functional group.

DESCRIPTION
1. Use "Template - deleteFromFG.csv" for this script.
2. Upload the csvfile as it required in the template.
3. Enjoy the automatic proces.

NOTES
General notes
This script is written by Janick Verbakel from IAM-Team
#>

$Tefo =@"
   _____                                     __________                __                                  
  /  _  \   ____  ____  ____   ______ ______ \______   \_____    ____ |  | _______     ____   ____   ______
 /  /_\  \_/ ___\/ ___\/ __ \ /  ___//  ___/  |     ___/\__  \ _/ ___\|  |/ /\__  \   / ___\_/ __ \ /  ___/
/    |    \  \__\  \__\  ___/ \___ \ \___ \   |    |     / __ \\  \___|    <  / __ \_/ /_/  >  ___/ \___ \ 
\____|__  /\___  >___  >___  >____  >____  >  |____|    (____  /\___  >__|_ \(____  /\___  / \___  >____  >
        \/     \/    \/    \/     \/     \/                  \/     \/     \/     \//_____/      \/     \/ 
Using all The power of Powershell Microsoft Graph to Automate the creating of access packages.

##############################################################################################
This Script is developed and tested by Janick Verbakel
##############################################################################################
"@
Write-Host $Tefo -ForegroundColor Cyan
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

$userNotFoundList = @()

$file = Import-Csv $fileDialouge -Delimiter ";"

foreach($item in $file)
{
	#R ead CSV file
	$EntraIDgroupName = $item.entraidgroup.Trim()
	$AccessPackageName = $item.accesspackagename.Trim()

	# Show the console progress
	Write-Host "Checking $EntraIDgroupName..." -ForegroundColor DarkGray

	# Find all users in the functional group
	$groupMembersAD = Get-ADGroupMember -Identity $EntraIDgroupName # all group members in the FG group in AD

	# If no users have been found, continue to the next group
	if($groupMembersAD -ne $null){ #reduce time if no users have been found
		# Find the access package in AD. These names have been trimmed to 51 characters.
		if ($AccessPackageName.Length -gt 51)
		{
			$searchPattern = $AccessPackageName.Substring(0,51)  + '*'
		}else {
			$searchPattern = $AccessPackageName + '*'
		}
		$AccessPackageNameAD = Get-ADGroup -Filter "Name -like '$searchPattern'"
		
		# Since the access package names have been trimmed to 51 characters, duplicates are possible. Loop over all these duplicates
		foreach($group in $AccessPackageNameAD){
			# Find all group members in the access package
			$groupMembersAP = Get-ADGroupMember -Identity $group 
	
			# Loop over all users 
			foreach($user in $groupMembersAD)
			{
				# Check if the user exists in the access package
				if ($groupMembersAP.SamAccountName -contains $user.SamAccountName)
				{
					# If the user exists in the access package. Delete them from the functional group and write in the console
					Remove-ADGroupMember -Identity $EntraIDgroupName -Members $user -Confirm:$False
					Write-Host "The user $user has succesfully been removed from $EntraIDgroupName" -ForegroundColor DarkGreen
				}
				else 
				{
					# If the user doesn't exist in the access package. Add them to the userNotFoundList to export after running the script
					$userNotFoundList += [PSCustomObject]@{
						Name = $user.name
						FG = $EntraIDgroupName
					}
				}
			}	
		}
	}
	
}
# Export the userNotFoundList
$userNotFoundList | Export-Csv -Path "C:\_LocalData\_git\accessPackages\userListNotFound.csv" -Delimiter ';' -NoTypeInformation

# Loop over all functional groups in the file to check if there are still users
Write-Host "Below a list of all users that are still part of any functional groups. Please check these by hand" -ForegroundColor DarkYellow
foreach($item in $file)
{
	$EntraIDgroupName = $item.entraidgroup.Trim()
	Write-Host $EntraIDgroupName -ForegroundColor DarkCyan
	$groupMembersAD = Get-ADGroupMember -Identity $EntraIDgroupName # all group members in the FG group in AD
	if($groupMembersAD -ne $null){
		foreach ($user in $groupMembersAD){
			Write-Host $user -ForegroundColor DarkGreen
		}
	}else{
		Write-Host "Functional group is empty." -ForegroundColor DarkRed
	}
}

Write-Host "Thanks for using This Code created By Janick Verbakel 2025" -ForegroundColor DarkMagenta