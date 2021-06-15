# List-ChromeExtensions
Powershell script for Windows/Python script for Mac

A while back I started investigating malicious Chrome extensions and had no easy way to translate the 32 letter extension codes into what extensions were actually installed. I looked around but couldn't find anything useful on the Internet. So I wrote a few scripts to automate the task and pull out relevant attributes to help with investigations. Hopefully this helps some other incident responders. I've found it useful in conjunction with a SOAR platform and Crowdstrike's Real Time Response.

## List-ChromeExtensions.ps1

Optional Parameters (default):
```
-showdefaults ($false)/$true
-showpermissions ($false)/$true (recommended with -output json for readability)
-output (table)/json
```

-output table
![image](https://user-images.githubusercontent.com/63032888/121832066-019dda80-cc7e-11eb-8b04-a274fabd722b.png)

-output json
![image](https://user-images.githubusercontent.com/63032888/121831774-2e052700-cc7d-11eb-81ba-8d212618f300.png)


## List-ChromeExtensions.py

Optional Parameters (default):
```
--showdefaults (False)/True
--showpermissions (False)/True
```

![screenshotcropped](https://user-images.githubusercontent.com/63032888/121852572-88fe4480-cca4-11eb-9590-a542e1075fc3.jpg)

## Output Attributes
* CreationTimeUTC - The folder creation time from the file system for the specific extension. This is the install time.
* Name - The title of the extension.
* Description - The description provided in the manifest.json if it exists.
* Chrome_Store - Lists whether the extension is in the Chrome Web Store or is an extension installed by default.
* Version - The version provided in the manifest.json.
* Code - The 32 letter code for the extension as seen in the extension folder.
* User - The user with the extension installed.
* Profile - The Chrome profile where the extension is installed. Typically is Default, but if more than one Chrome profile exists it will show Profile 1, Profile 2, Profile 3, etc.
* Computer - The Computer name. Helpful if you're aggregating results or storing data in a SOAR or ticketing platform.
* Permissions (optional) - The permissions listed in the manifest.json. This is what the extension is allowed to access. This is helpful when looking for potentially malicious extensions that have more permissions than they should reasonably need.
