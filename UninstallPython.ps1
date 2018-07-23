
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

Remove-Item "C:\Windows\Temp\MSI*.log" -force
