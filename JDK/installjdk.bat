@ECHO OFF
date /t >> c:\jdk\installjdk_log.txt
time /t >> c:\jdk\installjdk_log.txt
for /f  %%a in (c:\JDK\Listjdk.txt) do (
	echo "----" >> c:\jdk\installjdk_log.txt
	echo %%a >> c:\jdk\installjdk_log.txt
	net use x: \\%%a\c$\temp /persistent:no >> c:\jdk\installjdk_log.txt
	copy C:\JDK\jdk-8u192-windows*.exe x:\  >> c:\jdk\installjdk_log.txt
	C:\PStools\PsExec.exe \\%%a cmd /c c:\temp\jdk-8u192-windows-x64.exe /s >> c:\jdk\installjdk_log.txt
	C:\PStools\PsExec.exe \\%%a cmd /c c:\temp\jdk-8u192-windows-i586.exe /s >> c:\jdk\installjdk_log.txt
	del x:\jdk-8u192-windows*.exe >> c:\jdk\installjdk_log.txt
	net use x: /delete >> c:\jdk\installjdk_log.txt
	echo %%a >> c:\jdk\installjdk_log.txt
	echo "----" >> c:\jdk\installjdk_log.txt
)
date /t >> c:\jdk\installjdk_log.txt
time /t >> c:\jdk\installjdk_log.txt