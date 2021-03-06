do {
Start-Sleep 1
}
until ((get-date) -ge (get-date "6:10 PM"))

Get-Date | Out-File c:\jdk\list_uninstall_log.txt -Append
Foreach ($ComputerName in get-content c:\JDK\Listjdk.txt) {
$ComputerName | Out-File c:\jdk\list_uninstall_log.txt -Append
$app=get-wmiobject -Class Win32_product -ComputerName $ComputerName -Authentication 6 | where {$_.Name -like "Java SE Development Kit 8 Update 181 (64-bit)"}  
$app | Out-File c:\jdk\list_uninstall_log.txt -Append
$app.Uninstall() | Out-File c:\jdk\list_uninstall_log.txt -Append
$app1=get-wmiobject -Class Win32_product -ComputerName $ComputerName -Authentication 6 | where {$_.Name -like "Java SE Development Kit 8 Update 181"}  
$app1 | Out-File c:\jdk\list_uninstall_log.txt -Append
$app1.Uninstall() | Out-File c:\jdk\list_uninstall_log.txt -Append

$app=get-wmiobject -Class Win32_product -ComputerName $ComputerName -Authentication 6 | where {$_.Name -like "Java SE Development Kit 8 Update 191 (64-bit)"}  
$app | Out-File c:\jdk\list_uninstall_log.txt -Append
$app.Uninstall() | Out-File c:\jdk\list_uninstall_log.txt -Append
$app1=get-wmiobject -Class Win32_product -ComputerName $ComputerName -Authentication 6 | where {$_.Name -like "Java SE Development Kit 8 Update 191"}  
$app1 | Out-File c:\jdk\list_uninstall_log.txt -Append
$app1.Uninstall() | Out-File c:\jdk\list_uninstall_log.txt -Append

} 
Get-Date | Out-File c:\jdk\list_uninstall_log.txt -Append