########################################
#Setting the rights for the new HomeDrive location
########################################
# Create the ACE
$identity = 'User'##here is the samaccountname for the user
$rights = 'FullControl' #Other options: [enum]::GetValues('System.Security.AccessControl.FileSystemRights')
$inheritance = 'ContainerInherit, ObjectInherit' #Other options: [enum]::GetValues('System.Security.AccessControl.Inheritance')
$propagation = 'None' #Other options: [enum]::GetValues('System.Security.AccessControl.PropagationFlags')
$type = 'Allow' #Other options: [enum]::GetValues('System.Securit y.AccessControl.AccessControlType')
$ACE = New-Object System.Security.AccessControl.FileSystemAccessRule($identity,$rights,$inheritance,$propagation, $type)
##setting the rights
$path = "\\vdlgroep.local\Home\..."##here set the new home directory rights
$Acl = Get-Acl -Path $path
$Acl.AddAccessRule($ACE)

Set-Acl -Path $path -AclObject $Acl

########################################
#remove the rights from the old location
########################################
$oldPath = "\\vdlgroep.local\Home\...."
$Acl1 = Get-Acl -Path $oldPath
$Ace = $Acl1.Access|Where-Object{$_.IdentityReference -eq 'VDLGROEP\identity'}
$Acl1.RemoveAccessRule($Ace)
Set-Acl -Path $oldPath -AclObject $Acl1