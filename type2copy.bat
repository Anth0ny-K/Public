@echo off
REM This batch file takes a block of text as an argument
REM Waits 5 seconds, then simulates typing the text

REM Check if argument is provided
if "%~1"=="" (
    echo No text provided.
    exit /b 1
)

REM Call PowerShell to simulate typing after 5 seconds
powershell -Command "Start-Sleep -Seconds 5; Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::Send('%~1')"
