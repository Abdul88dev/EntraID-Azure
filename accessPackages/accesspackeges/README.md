# AccessPackeges

## Getting started

### If you are runnung the script for the first time : 
1. Activate PIM Role : Privileged Role Administrator ..>  not nessecary anymore
2. Run the local file auth.(ask for the location of this file)

This Script is created for porpose of Matrix automation proces. What does the Proces:

1. Creates the EntraID Group
2. Add the created group in EntraID to the Cloud Sync Scoping Filter.(Manullay)
3. Clones the members and the membership of the old AD group to the EntraID Group.
4. Create the Access Package for the EntraID Group ,creates the policy and adds the resource to cataloug then adds the resource to the access packages.
5. The access reviews should be created manually. 

## Ask permissions to run Order to work >> not nessecary anymore

You have to ask permissions to run all scripts

1. Privileged Role Administrator : To activate one time Microsoft Graph
2. User Administrator
3. Authentication Administrator
4. Hybrid Identity Administrator
5. Identity Governance Administrator

## The prober Order to work

You have to follow the Order as it`s given :
1. Run the local file auth.(ask for the location of this file)
2. CopyADToEntra.ps1
3. accessPackages.ps1
4. CopyGroupMemberOF.ps1

## Note


