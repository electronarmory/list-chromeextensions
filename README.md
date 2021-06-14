# list-chromeextensions
Powershell script for Windows, Python script for Mac

A while back I started investigating malicious Chrome extensions and had no easy way to translate the 32 letter extension codes into what extensions were actually installed. I looked around but couldn't find anything useful on the Internet. So I wrote a few scripts to automate the task and pull out relevant attributes to help with investigations. Hopefully this helps some other incident responders. I've found it useful in conjunction with our SOAR platform and Crowdstrike's Real Time Response.

List-ChromeExtensions.ps1 for Windows
Optional Parameters (default):
-showdefaults ($false)/$true
-showpermissions ($false)/$true (recommended with -output json for readability)
-output (table)/json

-output table
![image](https://user-images.githubusercontent.com/63032888/121832066-019dda80-cc7e-11eb-8b04-a274fabd722b.png)

-output json
![image](https://user-images.githubusercontent.com/63032888/121831774-2e052700-cc7d-11eb-81ba-8d212618f300.png)

