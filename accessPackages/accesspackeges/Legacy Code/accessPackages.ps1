<#
SYNOPSIS
This script Will create a complete access package with access review that occure every six month

DESCRIPTION
1. There will be a popups prompt to ask you to provide the The Samaccountname of the EntraID groupName,And provide the description,the approvals, requestors and the disired bane of the access packege.
2. Enjoy the automatic proces
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


#.\function.ps1
##connecting to the Graph using a service principle.
Connect-MgGraph -TenantID $global:tenID  -ClientSecretCredential $global:credential -NoWelcome

Import-Module Microsoft.Graph.Identity.Governance
Add-Type -AssemblyName Microsoft.VisualBasic
# Example usage


# Validate the choice and get the corresponding option
<# if ($choice -ge 1 -and $choice -le $choices.Length) {
    $selectedOption = $choices[$choice - 1]
    Write-Output "You selected: $selectedOption"
} else {
    Write-Output "Invalid choice. Please enter a number between 1 and 3."
} #>
###################################
#Explain Alert!
###################################
<# $wshell = New-Object -ComObject Wscript.Shell
$wshell.Popup("Provide the required Variables",0,"Starting",0x1) #>
############################################################
##this Sets all the variables
############################################################
$EntraIDgroupName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter The Name of the EntraID Group", "Set the group")
$accessPackageDisplayName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter The desired description of the Access Package", "Enter")
$accessPackageBeheerderGroupGui = [Microsoft.VisualBasic.Interaction]::InputBox("Enter The name of the matrix beheerders group", "Enter The group")
$matrixAanvragerGroupGui = [Microsoft.VisualBasic.Interaction]::InputBox("Enter The name of the matrix requester group (Dynamische bedrijf groep)", "Enter The group")
$AccesPackageName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Desired name of the Access package", "Enter")

##Assigning the Type of the reviewer in access review if it is needed
<# $reviewerID = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the objectId of the user(reviewer)", "Enter")
$reviewerType= "/users/$reviewerID" #>
<# $options = @("User", "Group")
$selectedOption = Chose_ReveiwerType -Options $options
if($selectedOption -eq "User"){
	
	$reviewerID = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the objectId of the user(reviewer)", "Enter")
	
}else {
	$reviewerType
	$reviewerID = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the objectId of the group(reviewer)", "Enter")
	$reviewerType= "/groups/$reviewerID/transitiveMembers"
} #>


############################################################
Write-Host "Getting the Information to start the Process!" -ForegroundColor Cyan
############################################################
$EntraGroup = Get-MgGroup -Filter "DisplayName eq '$EntraIDgroupName'"
$EntraIDGroup = $EntraGroup.Id
$EntraGroupName = $EntraGroup.DisplayName

##Getting the groups of beheerders and requestors

$accessPackageBeheerderGroup = Get-MgGroup -Filter "DisplayName eq '$accessPackageBeheerderGroupGui'"
$EntraIDGroupMatrixBeheerderGroup = $accessPackageBeheerderGroup.Id
$EntraGroupNameMatrixBeheerderGroup = $accessPackageBeheerderGroup.DisplayName



$matrixAanvragerGroup = Get-MgGroup -Filter "DisplayName eq '$matrixAanvragerGroupGui'"
$EntraIDGroupMatrixAanvragerGroup = $matrixAanvragerGroup.Id
$EntraGroupNameMatrixAanvragerGroup = $matrixAanvragerGroup.DisplayName

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
	isApprovalRequiredForAdd    = "true"
	isApprovalRequiredForUpdate = "true"
	stages                      = @(
		@{
			durationBeforeAutomaticDenial   = "P2D"
			isApproverJustificationRequired = "false"
			isEscalationEnabled             = "false"
			primaryApprovers                = @(
				@{
					"@odata.type" = "#microsoft.graph.groupMembers"
					 description   = "$EntraGroupNameMatrixBeheerderGroup"
					 groupId       = "$EntraIDGroupMatrixBeheerderGroup"#here comes the matrix beheerder groep
				}
			)
			fallbackPrimaryApprovers        = @(
				@{

				}
			)
			escalationApprovers             = @(
			)
			fallbackEscalationApprovers     = @(
			)
		}
	)
}
$allowedTargetScope = "specificDirectoryUsers"

$specificAllowedTargets = @(
	@{
		"@odata.type" = "#microsoft.graph.groupMembers"
		description   = "$EntraGroupNameMatrixAanvragerGroup"
		groupId       = "$EntraIDGroupMatrixAanvragerGroup"
	}
)
$expiration = @{
	type = "noExpiration"
}
<# ## This part is for Access reviews 
$reviewSettings = @{
	isEnabled = $true
	expirationBehavior = "keepAccess"
	isRecommendationEnabled = $true
	isReviewerJustificationRequired = $true
	isSelfReview = $false
	schedule = @{
		startDateTime = [System.DateTime]::Parse("2022-07-02T06:59:59.998Z")
		expiration = @{
			duration = "P14D"
			type = "afterDuration"
		}
		recurrence = @{
			pattern = @{
				type = "absoluteMonthly"
				interval = 6 # accure every six months
				month = 0
				dayOfMonth = 0
				daysOfWeek = @(
				)
			}
			range = @{
				type = "noEnd"
				numberOfOccurrences = 0
			}
		}
	}
	primaryReviewers = @(
		@{
			"@odata.type" = "#microsoft.graph.users"
			userId = "cd4a96cf-f66e-4314-9b92-4824a7e9013e"
		}
	)
	fallbackReviewers = @(
	)
}
 #>
#this part is made in case it is needed that the manager can request instead of the employee( stil preview) .
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
Write-Host "Adding the current users from the EntraID groep: $EntraGroupName"
#######################################################
$accessPackageAssignment = Get-MgEntitlementManagementAccessPackage -Filter "displayname eq '$AccesPackageName'" -ExpandProperty "assignmentpolicies"
$policy = $accessPackageAssignment.AssignmentPolicies[0]
foreach ($user in $members)
{
	$userID = $user.Id
	$params = @{
		requestType = "adminAdd"
		assignment = @{
		   targetId = $userID
		   assignmentPolicyId = $policy.Id
		   accessPackageId = $accessPackageAssignment.Id
		}
	 }
	 New-MgEntitlementManagementAssignmentRequest -BodyParameter $params
}

######################################################
##Write-Host "Step Five !" -ForegroundColor Yellow
############################################################
############################################################
##Write-Host "Creating the Access review for the Entra ID Group  $EntraGroupName !!" -ForegroundColor Cyan
############################################################
<# $date = (Get-Date).AddMonths(6)
$accessReview = @{
    displayName = "Access Review"
    descriptionForAdmins = "Review of accessPackage membership"
    descriptionForReviewers = "This is an access review to decide who would have still have access to '$accessPackageDisplayName' "
    scope = @{
        "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
        query = "/groups/$EntraIDGroup/transitiveMembers"
        #query = "/identitygovernance/entitlementmanagement/accesspackages/f8b9bdd0-bd85-4057-81a3-3b3e90623e14"
        #queryRoot = "/identitygovernance"
        queryType = "MicrosoftGraph"
    }
    reviewers = @(
        @{
         query = "/groups/$EntraIDGroupMatrixBeheerderGroup/transitiveMembers"##reviewer moet nog aangepast worden
         queryType = "MicrosoftGraph"
        }	
    )
	fallbackReviewers = @(
				@{
					query = "/groups/$EntraIDGroupMatrixBeheerderGroup/transitiveMembers"##reviewer moet nog aangepast worden
					queryType = "MicrosoftGraph"
				}
	)
    settings = @{
		mailNotificationsEnabled = $true
		reminderNotificationsEnabled = $true
		justificationRequiredOnApproval = $true
		defaultDecisionEnabled = $true
		defaultDecision = "Approve"
		instanceDurationInDays = 14
		recommendationsEnabled = $true
		recurrence = @{
			pattern = @{
				type = "absoluteMonthly"
				interval = 6 # accure every six months
				month = 0
				dayOfMonth = 0
				daysOfWeek = @(
				)
			}
			range = @{
				type = "noEnd"
				startDate = $date
			}
		}
	}
}
############################################################
############################################################
New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter $accessReview #>
############################################################
############################################################
Write-Host "Thanks for using This Code created By Abdulmohsen Alshalabi 2024" -ForegroundColor DarkMagenta




<# #######Test Area#########
############################################################
##creating the policy and adding it to access package
############################################################
$fetchaccess = Get-MgEntitlementManagementAccessPackage -AccessPackageId "332a93f8-d01b-4c92-950e-5321a5128d2b"
$id= $fetchaccess.Id
$accessPackaege = @{
	id = "$id"
}
$requestApprovalSettings = @{
	isApprovalRequiredForAdd    = "true"
	isApprovalRequiredForUpdate = "true"
	stages                      = @(
		@{
			durationBeforeAutomaticDenial   = "P2D"
			isApproverJustificationRequired = "false"
			isEscalationEnabled             = "false"
			primaryApprovers                = @(
				@{
					"@odata.type" = "#microsoft.graph.singleUser"
					 userId = "571dc986-4b9e-4620-87f2-4a0bcce64b1e"#here comes the matrix beheerder groep
				}
			)
			fallbackPrimaryApprovers        = @(
				@{

				}
			)
			escalationApprovers             = @(
			)
			fallbackEscalationApprovers     = @(
			)
		}
	)
}
$allowedTargetScope = "specificDirectoryUsers"

$specificAllowedTargets = @(
	@{
		"@odata.type" = "#microsoft.graph.groupMembers"
		groupId       = "91017fec-1714-4f19-a46d-57433939b08a"
	}
)
$expiration = @{
	type = "noExpiration"
}
#this part is made in case it is needed that the manager can request instead of the employee( stil preview) .
$requestorsettings = @{
	#enableNewRequests = "true"
	#allowRequestorManagerApproval = "true"
	enableTargetsToSelfAddAccess = "true"
	enableOnBehalfRequestorsToUpdateAccess = "true"
	enableOnBehalfRequestorsToRemoveAccess = "true"
	enableOnBehalfRequestorsToAddAccess = "true"
	allowCustomAssignmentSchedule = "false"
	#allowManagerToRequestOnBehalfOfEmployees ="true"
	onBehalfRequestors = @(
		@{
			"@odata.type"= "#microsoft.graph.requestorManager"##the manager as on behalf requestor
			 managerLevel= 1
		}
	)
}

############################################################
Write-Host "Step Four !" -ForegroundColor Yellow
############################################################
############################################################
Write-Host "Creating the policy and adding to the access packeg $EntraGroupName !!" -ForegroundColor Cyan
############################################################
New-MgEntitlementManagementAssignmentPolicy -AccessPackage $accessPackaege -RequestApprovalSettings $requestApprovalSettings -DisplayName "Internal Policy-Test" -Description "Internal Policy-Test" -AllowedTargetScope $allowedTargetScope -SpecificAllowedTargets $specificAllowedTargets  -Expiration $expiration -RequestorSettings $requestorsettings #-ReviewSettings $reviewSettings

 #>