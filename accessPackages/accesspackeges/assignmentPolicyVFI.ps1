<#
SYNOPSIS
This script Will create a complete access package with access review that occure every six month
And would change the policy to approval stage

DESCRIPTION
NOTES
General notes
This script is written by Abdulmohsen Alshalabi from IAM-Team
#>
#################################################################
### This part is for assiging the global variables##
#################################################################
############################################################
Write-Host "Getting the Information to start the Process!" -ForegroundColor Cyan
############################################################
Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All", "Group.ReadWrite.All","User.Read.All,Directory.Read.All" -NoWelcome
Import-Module Microsoft.Graph.Identity.Governance

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic


$date =(Get-Date).AddMinutes(5)
$formattedDate = $date.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

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

$EntraGroupNameMatrixBeheerderGroup = "Groupname"
$EntraIDGroupMatrixBeheerderGroup = "groupID"
$EntraGroupNameMatrixAanvragerGroup = "GroupName"
$EntraIDGroupMatrixAanvragerGroup = "GroupID"
    
   
foreach($item in $file)
{
    $AccesPackageName = $item.accesspackagename.Trim()


    $accessPackageAssignment = Get-MgEntitlementManagementAccessPackage -Filter "displayname eq '$AccesPackageName'" -ExpandProperty "assignmentpolicies"
    $policy = $accessPackageAssignment.AssignmentPolicies[0]
    $policyID = $policy.Id

    

    #################################################################
    ### This part is for assiging json file to update the policy##
    #################################################################
    ############################################################
    Write-Host "Getting the Information and assign it to a json format to start the Process!" -ForegroundColor Cyan
    $policyID
    ############################################################
    $json= @"
    {
        "@odata.context": "https://graph.microsoft.com/v1.0/identityGovernance/entitlementManagement/assignmentPolicies/$($policyID)",
        "displayName": "Internal Policy",
        "description": "Internal Policy",
        "allowedTargetScope": "specificDirectoryUsers",
        "automaticRequestSettings": null,
        "specificAllowedTargets": [
            {
                "@odata.type": "#microsoft.graph.groupMembers",
                "groupId": "$($EntraIDGroupMatrixAanvragerGroup)",
                "description": "$($EntraGroupNameMatrixAanvragerGroup)"
            }
        ],
        "expiration": {
            "endDateTime": null,
            "duration": null,
            "type": "noExpiration"
        },
        "requestorSettings": {
            "enableTargetsToSelfAddAccess": true,
            "enableTargetsToSelfUpdateAccess": false,
            "enableTargetsToSelfRemoveAccess": true,
            "allowCustomAssignmentSchedule": false,
            "enableOnBehalfRequestorsToAddAccess": true,
            "enableOnBehalfRequestorsToUpdateAccess": true,
            "enableOnBehalfRequestorsToRemoveAccess": true,
            "onBehalfRequestors": [
                {
                    "@odata.type": "#microsoft.graph.targetManager",
                    "managerLevel": 1
                }
            ]
        },
        "requestApprovalSettings": {
            "isApprovalRequiredForAdd": true,
            "isApprovalRequiredForUpdate": true,
            "stages": [
                {
                    "durationBeforeAutomaticDenial": "P7D",
                    "isApproverJustificationRequired": true,
                    "isEscalationEnabled": false,
                    "durationBeforeEscalation": null,
                    "primaryApprovers": [
                        {
                            "@odata.type": "#microsoft.graph.groupMembers",
                            "groupId": "$($EntraIDGroupMatrixBeheerderGroup)",
                            "description": "$($EntraGroupNameMatrixBeheerderGroup)"
                        }
                    ],
                    "fallbackPrimaryApprovers": [],
                    "escalationApprovers": [],
                    "fallbackEscalationApprovers": []
                }
            ]
        },
        "reviewSettings": {
            "isEnabled": true,
            "expirationBehavior": "keepAccess",
            "isRecommendationEnabled": true,
            "isReviewerJustificationRequired": true,
            "isSelfReview": false,
            "schedule": {
                "startDateTime": "$formattedDate",
                "expiration": {
                    "endDateTime": null,
                    "duration": "P25D",
                    "type": "afterDuration"
                },
                "recurrence": {
                    "pattern": {
                        "type": "absoluteMonthly",
                        "interval": 6,
                        "month": 0,
                        "dayOfMonth": 0,
                        "daysOfWeek": [],
                        "firstDayOfWeek": null,
                        "index": null
                    },
                    "range": {
                        "type": "noEnd",
                        "numberOfOccurrences": 0,
                        "recurrenceTimeZone": null,
                        "startDate": null,
                        "endDate": null
                    }
                }
            },
            "primaryReviewers": [
                {
                    "@odata.type": "#microsoft.graph.groupMembers",
                    "groupId": "$($EntraIDGroupMatrixBeheerderGroup)",
                    "description": "$($EntraGroupNameMatrixBeheerderGroup)"
                }
            ],
            "fallbackReviewers": []
        }
    
    }
"@
    $uri = "https://graph.microsoft.com/v1.0/identityGovernance/entitlementManagement/assignmentPolicies/$($policyID)"
    #################################################################
    ### This part is for assiging the policy and the access reviews##
    #################################################################
    ############################################################
    Write-Host "Http request is being triggerd to assign the policy.!" -ForegroundColor Cyan
    ############################################################

    try {
        Invoke-MgGraphRequest -Uri $uri -Method PUT -Body $json -ContentType "application/json"
        #Invoke-MgGraphRequest -Uri $uri -Method GET
        $count +=1
    }
    catch {
        <#Do this if a terminating exception happens#>
        "Error"
    }  
    if($count -eq 60)
    {
        Write-Host "The accepted amount of API call to Graph per Minute has exceeded the accepted value." -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "Wiating for couple secondes"
        Start-Sleep -Seconds 60
        $count =0
    }
}
