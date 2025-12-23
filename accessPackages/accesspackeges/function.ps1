function Chose_ReveiwerType {
    param (
        [string[]]$Options
    )

    # Load the required assembly
    Add-Type -AssemblyName System.Windows.Forms

    # Create the form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Choose what type of reveiwer"
    $form.Size = New-Object System.Drawing.Size(300, 200)

    # Create a group box to hold the radio buttons
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Text = "Choose an option"
    $groupBox.Size = New-Object System.Drawing.Size(250, 100)
    $groupBox.Location = New-Object System.Drawing.Point(20, 20)

    # Create radio buttons dynamically based on the options provided
    $radioButtons = @()
    for ($i = 0; $i -lt $Options.Length; $i++) {
        $radioButton = New-Object System.Windows.Forms.RadioButton
        $radioButton.Text = $Options[$i]
        $radioButton.Location = New-Object System.Drawing.Point(10, 20 + ($i * 20))
        $groupBox.Controls.Add($radioButton)
        $radioButtons += $radioButton
    }

    # Add the group box to the form
    $form.Controls.Add($groupBox)

    # Variable to store the selected option
    $selectedOption = $null

    # Create a button to submit the selection
    $submitButton = New-Object System.Windows.Forms.Button
    $submitButton.Text = "Submit"
    $submitButton.Location = New-Object System.Drawing.Point(100, 130)
    $submitButton.Add_Click({
        foreach ($radioButton in $radioButtons) {
            if ($radioButton.Checked) {
                $selectedOption = $radioButton.Text
                break
            }
        }
        $form.Close()
    })

    # Add the button to the form
    $form.Controls.Add($submitButton)

    # Show the form
    $form.ShowDialog()

    # Return the selected option
    return $selectedOption
}

Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All", "Group.ReadWrite.All","User.Read.All,Directory.Read.All" -NoWelcome
Import-Module Microsoft.Graph.Identity.Governance
$EntraIDGroup = "e9e5889e-76d8-4cee-9ed2-beabef0393ab"
$AccesPackageName = "SG-VDL-EID-ETGE-Share-BU_Acht_Q_Data_TQM"
$members = @(Get-MgGroupMember -GroupId $EntraIDGroup -All)


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