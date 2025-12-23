<#
SYNOPSIS
This script will create a clone of AD group member Of to the EntraID group

DESCRIPTION
1. There will be a popups prompt to ask you to provide the The Samaccountname of the AD groupName,And provide the description of the EntraID group that would be created!
2. 
2. Enjoy the automatic proces
NOTES
General notes
This script is written by Abdulmohsen Alshalabi from IAM-Team
#>


Add-Type -AssemblyName Microsoft.VisualBasic

#get the groups names.
##here is the old group
$samaccountToCopy = [Microsoft.VisualBasic.Interaction]::InputBox("Enter The SamAccounName of the Group To copy from (AD)", "Set the group")
## here is the recently synced group
$samaccountToCopyTo = [Microsoft.VisualBasic.Interaction]::InputBox("Enter The SamAccounName of the Group To copy To (SG group in EntraID Groups OU)", "Set the group")

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
            Get-ADGroup $group.Name | Add-ADGroupMember -Members $samaccountToCopyTo -ErrorAction Continue
            Write-Host "The group "+$samaccountToCopyTo+" Has been added to "+$group.Name
        }
        catch {
            "The Group " + $samaccountToCopyTo + " Cann`t be added to " + $group.Name
        }
        
    }
}

