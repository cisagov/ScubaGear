# Download and Execute Latest ScubaGear Development Branch 

1. Browse to https://github.com/cisagov/ScubaGear

2. Download the zip file of the main branch  
    1. Confirm the selected branch is "main"  
	2. Click the green "Code" button  
	3. Select "Download ZIP"   

3. Unzip the file to create a folder with the ScubaGear code 
	```powershell
	cd c:\folder_containing_code
	import-module .\powershell\scubagear
	```
	If you see any execution warning when trying to import the module or run cmdlets type 
	```powershell
	Get-ChildItem . -recurse | unblock-file
	```

4. Check Dependencies 
	```powershell
	Get-ScubaGearDependencyStatus
	```
	If any dependencies are missing (besides ScubaGear) run: 
	```powershell
	Install-ScubaDependencies
	```
	
5. Execute ScubaGear 
	```powershell
	Invoke-Scuba -ProductNames * 
	```