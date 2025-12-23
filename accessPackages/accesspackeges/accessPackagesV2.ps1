<#
SYNOPSIS
This script Will create a complete access package with access review that occure every six month

DESCRIPTION
1. Use "Template - AccessPackages.csv" for this script.
2. Upload the csvfile as it required in the template.
3. Enjoy the automatic proces.

NOTES
General notes
This script is written by Abdulmohsen Alshalabi from IAM-Team
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
This Script is developed and tested by Abdulmohsen Alshalabi
##############################################################################################
"@
Write-Host $Tefo -ForegroundColor Cyan
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

<# $TopMostForm = New-Object System.Windows.Forms.Form -Property @{
	 	TopMost = $true
	 	ShowInTaskbar = $false
		WindowState = 'Minimized'
		Load = { $_.Hide() }
	} #>
	

###explorer dialog to open the csv file for Uitdienst
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Title = 'Select files to open'
    Filter = 'CSV files (*.csv)|*.csv'
}
$null = $FileBrowser.ShowDialog()
$fileDialouge = $FileBrowser.FileName

$file = Import-Csv $fileDialouge -Delimiter ";"
##connecting to the Graph using a service principle.
#Connect-MgGraph -TenantID $global:tenID  -ClientSecretCredential $global:credential -NoWelcome
Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All", "Group.ReadWrite.All","User.Read.All,Directory.Read.All" -NoWelcome
Import-Module Microsoft.Graph.Identity.Governance

##Global Variables 
$global:EntraIDGroupMatrixBeheerderGroup = @()
$global:EntraGroupNameMatrixBeheerderGroup =@()
$global:EntraIDGroupMatrixAanvragerGroup = @()
$global:EntraGroupNameMatrixAanvragerGroup =@()
$global:policyId = @()
$global:Stage= @()


foreach($item in $file)
{
$EntraIDgroupName = $item.entraidgroup.Trim()
$accessPackageDisplayName = $item.displayname.Trim()
$accessPackageBeheerderGroupGui = $item.beheerder.Trim()
$matrixAanvragerGroupGui = $item.aanvrager.Trim()
$AccesPackageName = $item.accesspackagename.Trim()

############################################################
Write-Host "Getting the Information to start the Process!" -ForegroundColor Cyan
############################################################
$EntraGroup = Get-MgGroup -Filter "DisplayName eq '$EntraIDgroupName'"
$EntraIDGroup = $EntraGroup.Id
$EntraGroupName = $EntraGroup.DisplayName
$global:Stage += $item.stages.Trim()


##Getting the groups of beheerders and requestors

$accessPackageBeheerderGroup = Get-MgGroup -Filter "DisplayName eq '$accessPackageBeheerderGroupGui'"
$global:EntraIDGroupMatrixBeheerderGroup += $accessPackageBeheerderGroup.Id
$global:EntraGroupNameMatrixBeheerderGroup += $accessPackageBeheerderGroup.DisplayName



$matrixAanvragerGroup = Get-MgGroup -Filter "DisplayName eq '$matrixAanvragerGroupGui'"
$matrixAanvragerGroupGuiId = $matrixAanvragerGroup.Id
$global:EntraIDGroupMatrixAanvragerGroup += $matrixAanvragerGroup.Id
$global:EntraGroupNameMatrixAanvragerGroup += $matrixAanvragerGroup.DisplayName

############################
#Getting the all Entra ID Group members.
############################
$members = @(Get-MgGroupMember -GroupId $EntraIDGroup -All)

############################################################
##this gets the the catalougId.
############################################################
$displayCatalouge = "Matrix Beheer"
$catalougID = Get-MgEntitlementManagementCatalog -Filter "(displayname eq '$displayCatalouge')"  | Select-Object Id
if ($null -eq $catalougID) { throw "Cataloug not found!" }



############################################################
## create the access Packege
############################################################
$paramsAccesPackege = @{
	displayName = "$AccesPackageName"
	description = "$accessPackageDisplayName"
	isHidden    = $false
	catalog     = @{
		id = $catalougID.Id
	}
} 
############################################################
Write-Host "Starting the process !" -ForegroundColor Magenta
############################################################
############################################################
Write-Host "Step one !" -ForegroundColor Yellow
############################################################
############################################################
Write-Host "Creating the Access Package $EntraGroupName within the Catalouge $displayCatalouge" -ForegroundColor Cyan
############################################################
$accessPackaegeCreate = New-MgEntitlementManagementAccessPackage -BodyParameter $paramsAccesPackege  | Select-Object -ExpandProperty Id 
$accessPackageID = $accessPackaegeCreate
############################################################
## add a resource to catalouge
############################################################
$accessPackageResource = @{
	requestType = "adminAdd"
	resource    = @{
		displayName  = "$EntraGroupName"
		originId     = "$EntraIDGroup"
		originSystem = "AadGroup"
	}
	catalog     = @{
		id = $catalougID.Id
	}
  
}
############################################################
Write-Host "Step Two !" -ForegroundColor Yellow
############################################################
############################################################
Write-Host "Adding the EntraID Group $EntraGroupName as a resource to the catalaouge $displayCatalouge" -ForegroundColor Cyan
############adding the resource to the catalouge
New-MgEntitlementManagementResourceRequest -BodyParameter $accessPackageResource
####################

############################################################
#. Add Resource Role (Member Role) in the Access Package:-
############################################################
$rsc = Get-MgEntitlementManagementCatalogResource -AccessPackageCatalogId $catalougID.Id -Filter "originSystem eq 'AadGroup'" -ExpandProperty scopes
$filter = "(displayname eq '$EntraGroupName')"
$rrs = Get-MgEntitlementManagementCatalogResource -AccessPackageCatalogId $catalougID.Id -Filter $filter -ExpandProperty roles, scopes
$rparams = @{
	role  = @{
		id           = [string]$rrs.Id
		displayName  = [string]$rrs.DisplayName
		description  = [string]$rrs.Description
		originSystem = [string]$rrs.OriginSystem
		originId     = [string]"Member_" + $rrs.OriginId
		resource     = @{
			id           = [string]$rrs.Id
			originId     = [string]$rrs.OriginId
			originSystem = [string]$rrs.OriginSystem
		}
	}
	scope = @{
		id           = [string]$rsc.Scopes[0].Id
		originId     = [string]$rsc.Scopes[0].OriginId
		originSystem = [string]$rsc.Scopes[0].OriginSystem
	}
}

############################################################
Write-Host "Step Three !" -ForegroundColor Yellow
############################################################
############################################################
Write-Host "Adding the Resource Role as member to the access packeg $EntraGroupName !!" -ForegroundColor Cyan
############################################################
New-MgEntitlementManagementAccessPackageResourceRoleScope -AccessPackageId $accessPackageID -BodyParameter $rparams

############################################################
##creating the policy and adding it to access package
############################################################

$accessPackaege = @{
	id = "$accessPackageID"
}
$requestApprovalSettings = @{
	isApprovalRequiredForAdd    = "false"
	isApprovalRequiredForUpdate = "false"
	stages                      = @(
		@{	
		}
	)
}
$allowedTargetScope = "specificDirectoryUsers"

$specificAllowedTargets = @(
	@{
		"@odata.type" = "#microsoft.graph.groupMembers"
		description   = "$matrixAanvragerGroupGui"
		groupId       = "$matrixAanvragerGroupGuiId"
	}
)
$expiration = @{
	type = "noExpiration"
}

#this part is made in case it is needed that the manager can request instead of the employee( stil preview) .
$requestorsettings = @{
	enableTargetsToSelfAddAccess = "true"
	enableOnBehalfRequestorsToUpdateAccess = "true"
	enableOnBehalfRequestorsToRemoveAccess = "true"
	enableOnBehalfRequestorsToAddAccess = "true"
	allowCustomAssignmentSchedule = "false"
	onBehalfRequestors = @{
		
			"@odata.type"= "#microsoft.graph.requestorManager"##the manager as on behalf requestor
		 	managerLevel= 1
		}
		
	
}

############################################################
Write-Host "Step Four !" -ForegroundColor Yellow
############################################################
############################################################
Write-Host "Creating the policy and adding to the access packeg $EntraGroupName !!" -ForegroundColor Cyan
############################################################
New-MgEntitlementManagementAssignmentPolicy -AccessPackage $accessPackaege -RequestApprovalSettings $requestApprovalSettings -DisplayName "Internal Policy" -Description "Internal Policy" -AllowedTargetScope $allowedTargetScope -SpecificAllowedTargets $specificAllowedTargets -Expiration $expiration -RequestorSettings $requestorsettings #-ReviewSettings $reviewSettings

######################################################
Write-Host "Step Five !" -ForegroundColor Yellow
############################################################
########################################################
##Adding the current users from the EntraID groep: 
Write-Host "Assigning the group $EntraGroupName members to the access package and assign the approvals settings !!" -ForegroundColor Cyan
#######################################################




$accessPackageAssignment = Get-MgEntitlementManagementAccessPackage -Filter "displayname eq '$AccesPackageName'" -ExpandProperty "assignmentpolicies"
$policy = $accessPackageAssignment.AssignmentPolicies[0]
$global:policyId += $policy.Id
foreach ($user in $members)
{
	$userID = $user.Id
	$params = @{
		requestType = "adminAdd"
		assignment = @{
		   targetId = $userID
		   assignmentPolicyId = $policy.Id
		   accessPackageId = $accessPackageAssignment.Id
		   status = "Delivered"
		}
	 }
	 New-MgEntitlementManagementAssignmentRequest -BodyParameter $params
}
Write-Host "Waiting for 25 Seconds !!" -ForegroundColor Cyan
######################################################
#Write-Host "Step six !" -ForegroundColor Yellow
############################################################
}
Write-Host "Thanks for using This Code created By Abdulmohsen Alshalabi 2024" -ForegroundColor DarkMagenta