# Network Mapping
Write-Host Enter Password for nlmlhcaa on mini9
net use T: \\mini9\Data /u:nlmlhcaa "xxxxx"

$deploymentDir = "T:\Software\Deploy\"

#Be sure the software deployment repository is available 
If (!(Test-Path $deploymentDir)){
		Write-Host $deploymentDir " does NOT exist, exiting"
		Write-Host "Please ensure network drive is mounted"
		Exit 1
	}
	
#List computers to install Python onto in this file
$colComputer = Get-Content d:\PowerShell\targets1.txt

#Custom Object for each Python installation
# Set isMSI to 1 if installing from a .MSI file, set to 0 for EXE file.

$python3764 = [PSCustomObject]@{

	baseFile = "python-3.7.0-amd64.exe"
	args = "/quite /passive TargetDir=c:\Python37 InstallAllUsers=1 PrependPath=1 Include_test=0"
	installPath = "c:\windows\temp\python-3.7.0-amd64.exe"
	isMSI = 0
	
}

$python3732 = [PSCustomObject]@{

	baseFile = "python-3.7.0.exe"
	args = "/quite /passive TargetDir=c:\Python37-32 InstallAllUsers=1 PrependPath=1 Include_test=0"
	installPath = "c:\windows\temp\python-3.7.0.exe"
	isMSI = 0
	
}

$python3664 = [PSCustomObject]@{

	baseFile = "python-3.6.6-amd64.exe"
	args = "/quite /passive TargetDir=c:\Python36 InstallAllUsers=1 PrependPath=1 Include_test=0"
	installPath = "c:\windows\temp\python-3.6.6-amd64.exe"
	isMSI = 0
	
}

$python3632 = [PSCustomObject]@{

	baseFile = "python-3.6.6.exe"
	args = "/quite /passive TargetDir=c:\Python36-32 InstallAllUsers=1 PrependPath=1 Include_test=0"
	installPath = "c:\windows\temp\python-3.6.6.exe"
	isMSI = 0
	
}

$python2764 = [PSCustomObject]@{

	baseFile = "python-2.7.15.amd64.msi"
	args = "/qn TARGETDIR=c:\Python27 ALLUSERS=1"
	installPath = "c:\windows\temp\python-2.7.15.amd64.msi"
	isMSI = 1
	
}


$python2732 = [PSCustomObject]@{

	baseFile = "python-2.7.15.msi"
	args = "/qn TARGETDIR=c:\Python27-32 ALLUSERS=1"
	installPath = "c:\windows\temp\python-2.7.15.msi"
	isMSI = 1
	
}

#Init blank object array to hold the PSCustomObjects
$arrayPy = @()

#Add custom object to the array.
$arrayPy += $python3732
$arrayPy += $python3764 
$arrayPy += $python3632
$arrayPy += $python3664
$arrayPy += $python2732
$arrayPy += $python2764

#$arrayPy.count
#$arrayPy


Foreach ($strComputer in $colComputer){
	Echo $strComputer
	#Set to 1 to first do a Python uninstall
	$doUninstall = 1
	
	#Location to copy Python installer executable
	$rmtFile = "\\$strComputer\c$\windows\temp\"
	#If (!(Test-Path $rmtFile)){
	#	mkdir $rmtFile
	#	}

	For ($i=0; $i -lt $arrayPy.count; $i++) {
		#Basefile deployment location for Python
		$file = "T:\Software\Deploy\" + $arrayPy[$i].baseFile

		#Copies installer to the remote machine
		Echo "Copy-Item -Path " + $file + " " + $rmtFile
		Copy-Item -Path $file $rmtFile
		
	}
}
#Remote network mounted
net use T: /delete

