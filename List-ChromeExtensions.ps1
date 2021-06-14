<#
  .SYNOPSIS
  Returns list of installed Chrome extensions.

  .DESCRIPTION
  The List-ChromeExtensions.ps1 script searches the AppData\Local\Google\Chrome directories
  for each Chrome profile for every user, enumerates the extensions and lists attributes.

  .PARAMETER showdefaults
  If set to true shows all installed extensions. If false, omits the extensions installed 
  with Chrome by default.
  Default is false.

  .PARAMETER showpermissions
  If set to true, shows the permissions blob in the manifest.json. This is helpful in analyzing
  extensions but is messy unless output is in JSON. 
  Default is false.

  .PARAMETER output
  Specifies the output format. Options are json and table. 
  Default is table.

  .INPUTS
  None. You cannot pipe objects to List-ChromeExtensions.ps1.

  .OUTPUTS
  A table or a JSON blob with the list of Chrome extensions and attributes.

  .EXAMPLE
  PS> .\List-ChromeExtensions.ps1

  .EXAMPLE
  PS> .\List-ChromeExtensions -showdefaults $true

  .EXAMPLE
  PS> .\List-ChromeExtensions -showpermissions $true -output json

  .EXAMPLE
  PS> .\List-ChromeExtensions -showdefaults $true -showpermissions $true -output json
#>


param(
    [bool]$showdefaults = $false,
    [string]$output = "table",
    [bool]$showpermissions = $false
)

$userdir = "$env:SystemDrive\Users\"
$users = Get-ChildItem $userdir
$cpuname = $env:COMPUTERNAME
$extensiontable = @()
$initialfolder = Get-Location 


# Check each user
Foreach($user in $users){
    $username_string = $user.Name
    $BaseDir = "$userdir$user\AppData\Local\Google\Chrome\User Data"

    try{
        # Find folders named "Extensions" inside \AppData\Local\Google\Chrome\User Data for each user. This works for multiple Chrome profiles. 
        $extensiondirs = Get-ChildItem $BaseDir -Recurse -Depth 2 -ErrorAction Stop | Where-Object { $_.PSIsContainer -and $_.Name.Equals("Extensions") }
        foreach($dir in $extensiondirs){
            # For each folder named "Extensions", should be one for every active Chrome profile (Default, Profile 1, Profile 2, etc) for each user
            try{
                $extensions = Get-ChildItem $dir.FullName -ErrorAction Stop

                # Check each extension
                Foreach($extname in $extensions){
                    $loc = $dir.FullName + "\" + $extname
                    $split = $dir.FullName -split "\\"
                    $profile = $split[-2]     # Which Chrome profile? Default, Profile 1, Profile 2, etc

                    Set-Location $loc -ErrorAction SilentlyContinue
                    $folders = (Get-ChildItem).Name

                    $ext = New-Object System.Object
                    $time = Get-Item $loc | Select-Object CreationTimeUtc    # Creation time of the extension code's folder is essentially the install time
                    $ext | Add-Member -MemberType NoteProperty -NAme CreationTimeUTC -Value $time.CreationTimeUTC.ToString("G");

                    # Find the subfolder with the manifest.json file
                    Foreach($folder in $folders){
                        try{
                            Set-Location $folder -ErrorAction Stop
                            $manifest_path = (Get-Location).Path + "/manifest.json"
                            $defaultext = $false

                            # If manifest.json doesn't exist in this extension folder...
                            if(!(Test-Path $manifest_path -PathType Leaf)){
                                
                                # If manifest.json not found it was likely removed. Attempt to get details from the Chrome Web Store

                                # Look up the title of the extension in the Chrome Store
                                $url = "https://chrome.google.com/webstore/detail/" + $extname.Name

                                try{
                                    # Retrieve the website
                                    $result = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 5
                                    # Get the title, parse to first dash. Typical title is "Application Title - Chrome Web Store"
                                    $title = $result.ParsedHtml.title
                                    $parsedtitle = $title.Substring(0,$title.IndexOf(" -"))
                                    $ext | Add-Member -MemberType NoteProperty -Name Name -Value $parsedtitle
                                    $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Yes"
                                    $ext | Add-Member -MemberType NoteProperty -Name Description -Value "No Manifest.json found"
                                }
                                catch [System.Net.WebException]{
                                    # Something went wrong trying to find the extension
                                    $statusDesc = $_.Exception.Response.StatusDescription
                                    if([string]::IsNullOrEmpty($statusDesc)){
                                        # Website did not load
                                        $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Error"
                                    }
                                    else{
                                        $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value $statusDesc
                                    }
                                    $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Unknown"
                                }
                                catch{
                                    # Extension is not in the Chrome Web Store
                                    $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store "Not Found"
                                }

                                $ext | Add-Member -MemberType NoteProperty -Name Version -Value "Unknown"
                                $ext | Add-Member -MemberType NoteProperty -Name Code -Value $extname.Name
                                $ext | Add-Member -MemberType NoteProperty -Name User -Value $username_string
                                $ext | Add-Member -MemberType NoteProperty -Name Profile -Value $profile
                                $ext | Add-Member -MemberType NoteProperty -Name Computer -Value $cpuname
                                #$ext | Add-Member -MemberType NoteProperty -Name Update_URL -Value "Unknown"

                                $extensiontable += $ext
                                Break
                            }

                            $json = Get-Content $manifest_path -Raw | ConvertFrom-Json

                            # manifest.json was found
                            switch($extname){
                                # Handles the default Chrome extensions. Some are not in the Chrome Web Store.
                                aapocclcgogkmnckokdopfmhonfmgoek { $defaultext = $true; $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Google Slides"; $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Default"; $ext | Add-Member -MemberType NoteProperty -Name Description -Value "Default"; Break}
                                aohghmighlieiainnegkcijnfilokake { $defaultext = $true; $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Google Docs"; $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Default"; $ext | Add-Member -MemberType NoteProperty -Name Description -Value "Default"; Break}
                                apdfllckaahabafndbhieahigkjlhalf { $defaultext = $true; $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Google Drive"; $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Default"; $ext | Add-Member -MemberType NoteProperty -Name Description -Value "Default"; Break}
                                coobgpohoikkiipiblmjeljniedjpjpf { $defaultext = $true; $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Google Search"; $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Default"; $ext | Add-Member -MemberType NoteProperty -Name Description -Value "Default"; Break}
                                felcaaldnbdncclmgdcncolpebgiejap { $defaultext = $true; $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Google Sheets"; $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Default"; $ext | Add-Member -MemberType NoteProperty -Name Description -Value "Default"; Break}
                                ghbmnnjooekpmoecnnnilnnbdlolhkhi { $defaultext = $true; $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Google Docs Offline"; $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Default"; $ext | Add-Member -MemberType NoteProperty -Name Description -Value "Default"; Break}
                                nmmhkkegccagdldgiimedpiccmgmieda { $defaultext = $true; $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Google Wallet"; $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Default"; $ext | Add-Member -MemberType NoteProperty -Name Description -Value "Default"; Break}
                                pkedcjkdefgpdelpbcmbmeomcjbeemfm { $defaultext = $true; $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Chrome Media Router"; $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Default"; $ext | Add-Member -MemberType NoteProperty -Name Description -Value "Default"; Break}
                                blpcfgokakmgnkcojhhkbfbldkacnbeo { $defaultext = $true; $ext | Add-Member -MemberType NoteProperty -Name Name -Value "YouTube"; $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Default"; $ext | Add-Member -MemberType NoteProperty -Name Description -Value "Default"; Break}
                                pjkljhegncpnkpknbcohdijeoejaedia { $defaultext = $true; $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Gmail"; $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Default"; $ext | Add-Member -MemberType NoteProperty -Name Description -Value "Default"; Break}
                                # For all non default extensions
                                Default{
                                    # Many legitimate extensions don't populate name in the manifest.json, they have the default __MSG_appName__ or nothing
                                    if($json.name -like "__MSG_*"){
                                        # Try to look up the title in the Chrome Store since manifest.json doesn't contain the title
                                        $url = "https://chrome.google.com/webstore/detail/$extname"

                                        try{
                                            # Retrieve the website
                                            $result = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 5
                                            # Get the title, parse to first dash. Typical title is "Application Title - Chrome Web Store"
                                            $title = $result.ParsedHtml.title
                                            $parsedtitle = $title.Substring(0,$title.IndexOf(" -"))
                                            $ext | Add-Member -MemberType NoteProperty -Name Name -Value $parsedtitle
                                            $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Yes"
                                            $ext | Add-Member -MemberType NoteProperty -Name Description -Value "No Manifest.json found"
                                        }
                                        catch [System.Net.WebException]{
                                            # Something went wrong trying to find the extension
                                            $statusDesc = $_.Exception.Response.StatusDescription
                                            if([string]::IsNullOrEmpty($statusDesc)){
                                                # Website did not load
                                                $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Error"
                                            }
                                            else{
                                                $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value $statusDesc
                                            }
                                            $ext | Add-Member -MemberType NoteProperty -Name Name -Value "Unknown"
                                        }
                                        catch{
                                            $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store "Not Found"
                                        }
                                    }
                                    else{
                                        # It has a valid name in the manifest.json so add it

                                        $ext | Add-Member -MemberType NoteProperty -Name Name -Value $json.name

                                        # Is there a description populated in the manifest.json?
                                        if([string]::IsNullOrEmpty($json.description)){
                                            $ext | Add-Member -MemberType NoteProperty -Name Description -Value "No Description Found"
                                        }
                                        else{
                                            if($json.description -like "__MSG_*"){
                                                $ext | Add-Member -MemberType NoteProperty -Name Description -Value "No Description Found"
                                            }
                                            else{
                                                $ext | Add-Member -MemberType NoteProperty -Name Description -Value $json.description
                                            }
                                        }
                                        
                                        # Check if extension is in the Chrome Web Store
                                        $checkurl = "https://chrome.google.com/webstore/detail/$extname"
                                        try{
                                            # Attempt to retrieve the Chrome Web Store site
                                            $result = Invoke-WebRequest -Uri $checkurl -Method Get -TimeoutSec 5
                                            $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Yes"
                                        }
                                        catch [System.Net.WebException]{
                                            # Something went wrong trying to find the extension
                                            $statusDesc = $_.Exception.Response.StatusDescription
                                            if([string]::IsNullOrEmpty($statusDesc)){
                                                $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Error"
                                            }
                                            else{
                                                $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value $statusDesc
                                            }
                                        }
                                        catch{
                                            $ext | Add-Member -MemberType NoteProperty -Name Chrome_Store -Value "Not Found"
                                        }
                                    }
                                }
                            }

                            $ext | Add-Member -MemberType NoteProperty -Name Version -Value $json.version
                            $ext | Add-Member -MemberType NoteProperty -Name Code -Value $extname.Name
                            $ext | Add-Member -MemberType NoteProperty -Name User -Value $username_string
                            $ext | Add-Member -MemberType NoteProperty -Name Profile -Value $profile
                            $ext | Add-Member -MemberType NoteProperty -Name Computer -Value $cpuname
                            #$ext | Add-Member -MemberType NoteProperty -Name Update_URL -Value $json.update_url
                            
                            # Show permissions if parameter specified. This is messy, which is why it's off by default.
                            if($showpermissions){
                                if([string]::IsNullOrEmpty($json.permissions)){
                                    $ext | Add-Member -MemberType NoteProperty -Name Permissions -Value "None"
                                }
                                else{
                                    $ext | Add-Member -MemberType NoteProperty -Name Permissions -Value $json.permissions
                                }
                            }

                            # List extension if it is a non-default extension or if parameter used to show default extensions
                            if(!$defaultext -Or $showdefaults){
                                # Add extension with to the array of extensions
                                $extensiontable += $ext
                            }
                        }
                        catch{
                            # Write-Error "Unexpected error analyzing extension."
                        }
                    }
                }
            }
            catch{}
        }
    }
    catch{}
}

Set-Location $initialfolder
# If there's extensions to be outputted...
if($extensiontable.Length -gt 0){
    if($output -like "json"){
        $extensiontable | ConvertTo-Json | Out-String
    }
    else{
        $extensiontable | ft
    }
}
elseif($showdefaults){
    # For this case we're trying to show defaults but there's nothing to output
    # Create JSON table that says "No extensions found."
    $zero = New-Object System.Object
    $zero | Add-Member -MemberType NoteProperty -Name Results -Value "No extensions found."
    $noresults = @()
    $noresults += $zero
    if($output -like "json"){
        $noresults | ConvertTo-Json | Out-String
    }
    else{
        Write-Output "No extensions found."
    }
}
else{
    # Not showing default extensions, no other extensions found.
    $zero = New-Object System.Object
    $zero | Add-Member -MemberType NoteProperty -Name Results -Value "No non-default extensions found."
    $noresults = @()
    $noresults += $zero
    if($output -like "json"){
        $noresults | ConvertTo-Json | Out-String
    }
    else{
        Write-Output "No non-default extensions found."
    }

}