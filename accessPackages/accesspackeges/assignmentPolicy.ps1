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
$EntraIDGroupMatrixAanvragerGroup = $global:EntraIDGroupMatrixAanvragerGroup
$EntraGroupNameMatrixAanvragerGroup = $global:EntraGroupNameMatrixAanvragerGroup
$policyID = $global:policyID
$EntraIDGroupMatrixBeheerderGroup = $global:EntraIDGroupMatrixBeheerderGroup
$EntraGroupNameMatrixBeheerderGroup = $global:EntraGroupNameMatrixBeheerderGroup
$countpolicy = $policyID.count
$stage = $global:Stage
$date = (Get-Date).AddMinutes(5)

$formattedDate = $date.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$count = 0
for ($i = 0; $i -lt $countpolicy; $i++) {
   
    $EntraIDGroupMatrixAanvragerGroup[$i]
    $EntraGroupNameMatrixAanvragerGroup[$i]
    $policyID[$i]
    #################################################################
    ### This part is for assiging json file to update the policy##
    #################################################################
    ############################################################
    Write-Host "Getting the Information and assign it to a json format to start the Process!" -ForegroundColor Cyan
    ############################################################
    if ($stage[$i] -eq "A") {
        $json = @"
{
	"@odata.context": "https://graph.microsoft.com/v1.0/identityGovernance/entitlementManagement/assignmentPolicies/$($policyID[$i])",
    "displayName": "Internal Policy",
    "description": "Internal Policy",
    "allowedTargetScope": "specificDirectoryUsers",
    "automaticRequestSettings": null,
    "specificAllowedTargets": [
        {
            "@odata.type": "#microsoft.graph.groupMembers",
            "groupId": "$($EntraIDGroupMatrixAanvragerGroup[$i])",
            "description": "$($EntraGroupNameMatrixAanvragerGroup[$i])"
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
                        "groupId": "$($EntraIDGroupMatrixBeheerderGroup[$i])",
                        "description": "$($EntraGroupNameMatrixBeheerderGroup[$i])"
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
                    "interval": 3,
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
                "groupId": "$($EntraIDGroupMatrixBeheerderGroup[$i])",
                "description": "$($EntraGroupNameMatrixBeheerderGroup[$i])"
            }
        ],
        "fallbackReviewers": []
    }
   
}
"@
    }
    elseif ($stage[$i] -eq "B") {
        $json = @"
{
	"@odata.context": "https://graph.microsoft.com/v1.0/identityGovernance/entitlementManagement/assignmentPolicies/$($policyID[$i])",
    "displayName": "Internal Policy",
    "description": "Internal Policy",
    "allowedTargetScope": "specificDirectoryUsers",
    "automaticRequestSettings": null,
    "specificAllowedTargets": [
        {
            "@odata.type": "#microsoft.graph.groupMembers",
            "groupId": "$($EntraIDGroupMatrixAanvragerGroup[$i])",
            "description": "$($EntraGroupNameMatrixAanvragerGroup[$i])"
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
                        "@odata.type": "#microsoft.graph.requestorManager",
                        "managerLevel": 1
                    }
                ],
                "fallbackPrimaryApprovers": [],
                "escalationApprovers": [],
                "fallbackEscalationApprovers": []
            },
            {
            "durationBeforeAutomaticDenial": "P7D",
                "isApproverJustificationRequired": true,
                "isEscalationEnabled": false,
                "durationBeforeEscalation": null,
                "primaryApprovers": [
                    {
                        "@odata.type": "#microsoft.graph.groupMembers",
                        "groupId": "$($EntraIDGroupMatrixBeheerderGroup[$i])",
                        "description": "$($EntraGroupNameMatrixBeheerderGroup[$i])"
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
                "groupId": "$($EntraIDGroupMatrixBeheerderGroup[$i])",
                "description": "$($EntraGroupNameMatrixBeheerderGroup[$i])"
            }
        ],
        "fallbackReviewers": []
    }
   
}
"@
    }
    $uri = "https://graph.microsoft.com/v1.0/identityGovernance/entitlementManagement/assignmentPolicies/$($policyID[$i])"
    #################################################################
    ### This part is for assiging the policy and the access reviews##
    #################################################################
    ############################################################
    Write-Host "Http request is being triggerd to assign the policy.!" -ForegroundColor Cyan
    ############################################################

    try {
        Invoke-MgGraphRequest -Uri $uri -Method PUT -Body $json -ContentType "application/json"
        $count += 1
    }
    catch {
        <#Do this if a terminating exception happens#>
    
    }  
    if ($count -eq 60) {
        Write-Host "The accepted amount of API call to Graph per Minute has exceeded the accepted value." -BackgroundColor Red -ForegroundColor Yellow
        Write-Host "Wiating for couple secondes"
        Start-Sleep -Seconds 60
        $count = 0
    }
}