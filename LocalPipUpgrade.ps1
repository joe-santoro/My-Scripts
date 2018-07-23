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


For ($i=0; $i -lt $arrayPy.count; $i++){
	# Upgrade pip
	#$pip = $arrayPy[$i].pip
	
	$python = $arrayPy[$i].python
	Start-Process -Wait $python -ArgumentList "-m", "pip", "install", "--upgrade", "pip"

	# Install Numpy	
	Start-Process -Wait $python -ArgumentList "-m", "pip", "install", "numpy", "--no-cache-dir"
}
	