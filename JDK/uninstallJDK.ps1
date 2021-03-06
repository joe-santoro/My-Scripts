#do {
#Start-Sleep 1
#}
#until ((get-date) -ge (get-date "11:10 PM"))
Get-Date | Out-File c:\jdk\list_uninstall_log.txt -Append
Foreach ($ComputerName in get-content c:\JDK\list_uninstall.txt) {
$ComputerName | Out-File c:\jdk\list_uninstall_log.txt -Append
$app=get-wmiobject -Class Win32_product -ComputerName $ComputerName -Authentication 6 | where {$_.Name -like "Java SE Development Kit 8 Update 181 (64-bit)"}  
$app | Out-File c:\jdk\list_uninstall_log.txt -Append
$app.Uninstall() | Out-File c:\jdk\list_uninstall_log.txt -Append
$app=get-wmiobject -Class Win32_product -ComputerName $ComputerName -Authentication 6 | where {$_.Name -like "Java SE Development Kit 8 Update 181"}  
$app | Out-File c:\jdk\list_uninstall_log.txt -Append
$app.Uninstall() | Out-File c:\jdk\list_uninstall_log.txt -Append
} 
Get-Date | Out-File c:\jdk\list_uninstall_log.txt -Append