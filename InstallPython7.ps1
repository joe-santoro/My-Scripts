# Network Mapping
Write-Host Enter Password for nlmlhcaa on mini9
net use T: \\mini9\Data /u:nlmlhcaa

$deploymentDir = "T:\Software\Deploy\"

#Be sure the software deployment repository is available 
If (!(Test-Path $deploymentDir)){
		Write-Host $deploymentDir " does NOT exist, exiting"
		Write-Host "Please ensure network drive is mounted"
		Exit 1
	}
	
#List computers to install Python onto in this file
$colComputer = Get-Content d:\PowerShell\targets.txt

#Custom Object for each Python installation
# Set isMSI to 1 if installing from a .MSI file, set to 0 for EXE file.

$python3764 = [PSCustomObject]@{

	baseFile = "python-3.7.0-amd64.exe"
	args = "/quite /passive TargetDir=c:\Python37 InstallAllUsers=1 PrependPath=1 Include_test=0"
	installPath = "c:\windows\temp\python-3.7.0-amd64.exe"
	pip = "c:\Python37\scripts\pip.exe"
	python = "c:\Python37\python.exe" 
	isMSI = 0
	
}

$python3732 = [PSCustomObject]@{

	baseFile = "python-3.7.0.exe"
	args = "/quite /passive TargetDir=c:\Python37-32 InstallAllUsers=1 PrependPath=1 Include_test=0"
	installPath = "c:\windows\temp\python-3.7.0.exe"
	pip = "c:\Python37-32\scripts\pip.exe"
	python = "c:\Python37-32\python.exe" 
	isMSI = 0
	
}

$python3664 = [PSCustomObject]@{

	baseFile = "python-3.6.6-amd64.exe"
	args = "/quite /passive TargetDir=c:\Python36 InstallAllUsers=1 PrependPath=1 Include_test=0"
	installPath = "c:\windows\temp\python-3.6.6-amd64.exe"
	pip = "c:\Python36\scripts\pip.exe"
	python = "c:\Python36\python.exe" 
	isMSI = 0
	
}

$python3632 = [PSCustomObject]@{

	baseFile = "python-3.6.6.exe"
	args = "/quite /passive TargetDir=c:\Python36-32 InstallAllUsers=1 PrependPath=1 Include_test=0"
	installPath = "c:\windows\temp\python-3.6.6.exe"
	pip = "c:\Python36-32\scripts\pip.exe"
	python = "c:\Python36-32\python.exe" 
	isMSI = 0
	
}

$python3464 = [PSCustomObject]@{

	baseFile = "python-3.4.4.amd64.msi"
	args = "/qn TARGETDIR=c:\Python34 ALLUSERS=1"
	installPath = "c:\windows\temp\python-3.4.4.amd64.msi"
	pip = "c:\Python34\scripts\pip.exe"
	python = "c:\Python34\python.exe" 
	isMSI = 1
	
}

$python3432 = [PSCustomObject]@{

	baseFile = "python-3.4.4.msi"
	args = "/qn TARGETDIR=c:\Python34-32 ALLUSERS=1"
	installPath = "c:\windows\temp\python-3.4.4.msi"
	pip = "c:\Python36-32\scripts\pip.exe"
	python = "c:\Python36-32\python.exe" 
	isMSI = 1
	
}

$python2764 = [PSCustomObject]@{

	baseFile = "python-2.7.15.amd64.msi"
	args = "/qn TARGETDIR=c:\Python27 ALLUSERS=1"
	installPath = "c:\windows\temp\python-2.7.15.amd64.msi"
	pip = "c:\Python27\scripts\pip.exe"
	python = "c:\Python27\python.exe" 
	isMSI = 1
	
}


$python2732 = [PSCustomObject]@{

	baseFile = "python-2.7.15.msi"
	args = "/qn TARGETDIR=c:\Python27-32 ALLUSERS=1"
	installPath = "c:\windows\temp\python-2.7.15.msi"
	pip = "c:\Python27-32\scripts\pip.exe"
	python = "c:\Python27-32\python.exe" 
	isMSI = 1
	
}

#Init blank object array to hold the PSCustomObjects
$arrayPy = @()

#Add custom object to the array.
$arrayPy += $python3732
$arrayPy += $python3764 
$arrayPy += $python3632
$arrayPy += $python3664
$arrayPy += $python3464 
$arrayPy += $python3432 
$arrayPy += $python2732
$arrayPy += $python2764

#$arrayPy.count
#$arrayPy

#Install Python either via it's exe or use MSI exec.
function PythonEXEInstall {
	[CmdletBinding()]
	Param ( [string]$strComputer, 
	[string]$pythonInstall, 
	[string]$args,
	[int] $isMSI
	)

	
	#Run the installer
	Write-Host Invoke-Command $strComputer $pythonInstall $args
	If ( $isMSI -eq 1 ) {
		#install using msiexec for *.msi files
	    Write-Host MSI executable
		Invoke-Command -ComputerName $strComputer -ScriptBlock {
			#$msiArgs = "/i " + $using:pythonInstall + " " + $using:args + " /L*V C:\windows\temp\install.log"
			$msiArgs = "/i " + $using:pythonInstall + " " + $using:args
			Write-Host "msiexec " $msiArgs
			Start-Process "msiexec" -Wait -ArgumentList $msiArgs
			}
	}
	Else {
		#Install using the python EXE installer 
		#Invoke the executable to install python
		Invoke-Command -ComputerName $strComputer -ScriptBlock {
		    $argumentList = " " + $using:args
			Start-Process -FilePath $using:pythonInstall -Wait -ArgumentList $argumentList
		}
	}
}

$pipUpgrade = "LocalPipUpgrade.ps1"

Foreach ($strComputer in $colComputer){
	#Set computer name for pip upgrade and numpy
	
	#Set to 1 to first do a Python uninstall otherwise 0
	$doUninstall = 1
	
	#Location to copy Python installer executable
	$rmtFile = "\\$strComputer\c$\windows\temp\"
	If (!(Test-Path $rmtFile)){
		mkdir $rmtFile
	}

	If ($doUninstall -eq 1) {
		#First Uninstall Python
		#NEED TO TEST (JSS)
		$apps = Get-WmiObject -Query "Select * from Win32_Product WHERE 
			   ( Name LIKE 'Python 2.7%' )  
			or ( Name LIKE 'Python 3.4%' ) 
			or ( Name LIKE 'Python 3.5%' )
			or ( Name LIKE 'Python 3.6%' ) "

		ForEach ($app in $apps) {
			Write-Host "Uninstalling " $app.Name
			$app.uninstall()
		}
	}
	
	#Copies a PS script to run locally to do the "pip upgrade" and "install numpy"
	$LocalPS = "T:\Software\Deploy\" + $pipUpgrade
	Write-Host Copy-Item -Path $LocalPS -Destination $rmtFile
	Copy-Item -Path $LocalPS -Destination $rmtFile

	
	For ($i=0; $i -lt $arrayPy.count; $i++){
		#Basefile deployment location for Python
		$file = "T:\Software\Deploy\" + $arrayPy[$i].baseFile

		#Copies installer to the remote machine
		Write-Host Copy-Item -Path $file -Destination $rmtFile
		Copy-Item -Path $file -Destination $rmtFile
		
		#Install Python
		PythonEXEInstall $strComputer $arrayPy[$i].installPath $arrayPy[$i].args $arrayPy[$i].isMSI
		
		$delFile = $rmtFile + $arrayPy[$i].baseFile
		If (Test-Path $delFile){
			#Clean up, remove install file
			Remove-Item $delFile -force -recurse
		}
	
	}
	#Invoke the local PS scripts to upgrade pip and install numpy
	Write-host Invoke-Command -ComputerName $strComputer -FilePath $LocalPS
	Invoke-Command -ComputerName $strComputer -FilePath $LocalPS
	
	#Clean up
	$delFile = $rmtFile + $ps1
	If (Test-Path $delFile){
		#Clean up, remove install file
		Remove-Item $delFile -force -recurse
	}
}

#Remote network mounted
net use T: /delete

