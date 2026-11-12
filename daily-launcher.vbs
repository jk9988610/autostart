Set ws = CreateObject("WScript.Shell")
WScript.Sleep 15000
ws.CurrentDirectory = "E:\tools\autostart"
ws.Run """C:\Users\123mc\AppData\Local\Programs\Python\Python312\pythonw.exe"" ""E:\tools\autostart\daily-launcher.py"" -p work", 0, False
