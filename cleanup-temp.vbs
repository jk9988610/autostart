Set ws = CreateObject("WScript.Shell")
WScript.Sleep 30000
ws.Run "cmd /c ""E:\tools\autostart\cleanup-temp.bat""", 0, False