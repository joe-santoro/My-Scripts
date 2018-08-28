[CmdletBinding()]
$VerbosePreference = "continue"

#List computers to install Python onto in this file
$colComputer = Get-Content d:\PowerShell\ITK_win.txt

# Enter list of computers to upgrade python into d:\powershell\targets.txt

# Network Mapping
Write-Host "Enter Password for nlmlhcaa on mini9"
net use \\mini9\Data /u:nlmlhcaa "xxxxxx"

$deploymentDir = "\\mini9\Data\Software\Deploy\"

#Be sure the software deployment repository is available 
If (!(Test-Path $deploymentDir)){
		Write-Verbose "$deploymentDir does NOT exist, exiting"
		Write-Verbose "Please ensure network drive is mounted"
		Exit 1
	}
	

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
#$arrayPy += $python3464 
#$arrayPy += $python3432 
$arrayPy += $python2732
$arrayPy += $python2764

#Write-Output $arrayPy.count
#Write-Output $arrayPy

#Install Python either via it's exe or use MSI exec.
function PythonEXEInstall {
	[CmdletBinding()]
	Param ( [string]$strComputer, 
	[string]$pythonInstall, 
	[string]$args,
	[int] $isMSI
	)

	
	#Run the installer
	Write-Verbose "Invoke-Command $strComputer $pythonInstall $args"
	If ( $isMSI -eq 1 ) {
		#install using msiexec for *.msi files
	    Write-Verbose "MSI executable"
		Invoke-Command -ComputerName $strComputer -ScriptBlock {
            #$msiArgs = "/i $using:pythonInstall $using:args /L*V C:\windows\temp\install.log"
			$msiArgs = "/i $using:pythonInstall $using:args"
			Write-Verbose "msiexec.exe  $msiArgs"
			Start-Process "msiexec.exe" -Wait -ArgumentList $msiArgs
			}
	}
	Else {
		#Install using the python EXE installer 
		#Invoke the executable to install python
		Invoke-Command -ComputerName $strComputer -ScriptBlock {
		    $argumentList = " $using:args"
			Start-Process -FilePath $using:pythonInstall -Wait -ArgumentList $argumentList
		}
	}
}


Foreach ($strComputer in $colComputer){
		
	
	For ($i=0; $i -lt $arrayPy.count; $i++){

        Write-Verbose "Running on $strComputer"

		#Basefile deployment location for Python
		$file = "\\mini9\Data\Software\Deploy\" + $arrayPy[$i].baseFile
        Write-Verbose "File=$file"

		#Copies installer to the remote machine
		Write-Verbose "Copy-Item -Path $file -Destination $rmtFile"
		Copy-Item -Path $file -Destination $rmtFile
		
		#Install Python
		#PythonEXEInstall $strComputer $arrayPy[$i].installPath $arrayPy[$i].args $arrayPy[$i].isMSI
		
		$delFile = $rmtFile + $arrayPy[$i].baseFile
		If (Test-Path $delFile){
			#Clean up, remove install file
			Write-Verbose "Remove-Item $delFile -force"
			Remove-Item $delFile -force
		}
	}
	
    #Copies a PS script to run locally to do the "pip upgrade" and "install numpy"
    $pipUpgrade = "LocalPipUpgrade.ps1"
	$LocalPS = "\\mini9\Data\Software\Deploy\$pipUpgrade"

    Write-Verbose "LocalPS=$LocalPS"
	Write-Verbose "Copy-Item -Path $LocalPS -Destination $rmtFile"
	Copy-Item -Path $LocalPS -Destination $rmtFile

	
	$delFile = $rmtFile + $pipUpgrade
	If (Test-Path $delFile){
		#Clean up, remove install file
		Write-Verbose "Remove-Item $delFile -force"
		#Remove-Item $delFile -force
	}
}

#Remote network mounted
#net use T: /delete

