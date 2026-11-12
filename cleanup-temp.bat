@echo off
setlocal
set DAYS=7
set USER_TEMP=%TEMP%
set SYS_TEMP=%SystemRoot%\Temp

echo [%date% %time%] 开始清理用户 Temp: %USER_TEMP%
forfiles /p "%USER_TEMP%" /s /m * /d -%DAYS% /c "cmd /c del @path" 2>nul

echo [%date% %time%] 开始清理系统 Temp: %SYS_TEMP%
forfiles /p "%SYS_TEMP%" /s /m * /d -%DAYS% /c "cmd /c del @path" 2>nul

echo [%date% %time%] 清理完成