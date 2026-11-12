Set ws = CreateObject("WScript.Shell")
ws.CurrentDirectory = "E:\tools\autostart"
ws.Run """C:\Users\123mc\AppData\Local\Programs\Python\Python312\pythonw.exe"" ""E:\tools\autostart\daily-launcher.py"" --gui", 0, False
