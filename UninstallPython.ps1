
#First Uninstall Python
#NEED TO TEST (JSS)

Get-Date | Out-File c:\jdk\list_uninstall_log.txt -Append
Foreach ($ComputerName in get-content c:\JDK\list_uninstall.txt) {
$ComputerName | Out-File c:\jdk\list_uninstall_log.txt -Append
$app=get-wmiobject -Class Win32_product -ComputerName $ComputerName -Authentication 6 | where {$_.Name -like "Python 2.7%"}  
$app | Out-File c:\jdk\list_uninstall_log.txt -Append
$app.Uninstall() | Out-File c:\jdk\list_uninstall_log.txt -Append

$ComputerName | Out-File c:\jdk\list_uninstall_log.txt -Append
$app=get-wmiobject -Class Win32_product -ComputerName $ComputerName -Authentication 6 | where {$_.Name -like "Python 3.4%"}  
$app | Out-File c:\jdk\list_uninstall_log.txt -Append
$app.Uninstall() | Out-File c:\jdk\list_uninstall_log.txt -Append

$ComputerName | Out-File c:\jdk\list_uninstall_log.txt -Append
$app=get-wmiobject -Class Win32_product -ComputerName $ComputerName -Authentication 6 | where {$_.Name -like "Python 3.5%"}  
$app | Out-File c:\jdk\list_uninstall_log.txt -Append
$app.Uninstall() | Out-File c:\jdk\list_uninstall_log.txt -Append

$ComputerName | Out-File c:\jdk\list_uninstall_log.txt -Append
$app=get-wmiobject -Class Win32_product -ComputerName $ComputerName -Authentication 6 | where {$_.Name -like "Python 3.6%"}  
$app | Out-File c:\jdk\list_uninstall_log.txt -Append
$app.Uninstall() | Out-File c:\jdk\list_uninstall_log.txt -Append

} 
#$apps = Get-WmiObject -Query "Select * from Win32_Product WHERE 
#	   ( Name LIKE 'Python 2.7%' )  
#	or ( Name LIKE 'Python 3.4%' ) 
#	or ( Name LIKE 'Python 3.5%' )
#	or ( Name LIKE 'Python 3.6%' ) "

#ForEach ($app in $apps) {
#	Write-Host "Uninstalling " $app.Name
#	$app.uninstall()
#	}

#Remove-Item "C:\Windows\Temp\MSI*.log" -force
