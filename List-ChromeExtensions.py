#######################################################################
# Parses user profiles, finds each Chrome profile, identifies each
# Chrome extension via manifest.json or Chrome Web Store lookup.
# Output is a JSON blob with extension information
#
# Omits default Chrome extensions unless argument is used
# Optional argument: --showdefaults   (lists extensions installed with Chrome by default)
# Optional argument: --showpermissions   (lists extension permissions from manifest.json)
#
#######################################################################

import os
import sys
import argparse
import urllib2
import re
import json
import socket
import time
import datetime
from collections import OrderedDict

usersdir = os.listdir("/Users/")
hostname = socket.gethostname()
extlist = []

parser = argparse.ArgumentParser()
parser.add_argument('--showdefaults', default=False, help='Set to True if you want to show all extensions.', required=False)
parser.add_argument('--showpermissions', default=False, help='Set to True if you want to output permissions from manifest.json', required=False)
args = parser.parse_args()

# Check each user for extensions
for user in usersdir:
    chromeprofiles = []
    try:
        # print ("Enumerating Chrome Extensions for %s" % (user))

        # Identify Chrome profiles for each user
        for root, subdirs, files in os.walk("/Users/%s/Library/Application Support/Google/Chrome/" % (user)):
            for d in subdirs:
                # print(d)
                if d == "Default":
                    # Add to array of Chrome profiles to check
                    chromeprofiles.append(d)
                    #print(d)
                elif d.startswith("Profile"):
                    chromeprofiles.append(d)
                    #print(d)
            break

        for profile in chromeprofiles:
            # Ensure extensions directory exists for the User/Chrome profile
            try:
                ext = os.listdir("/Users/%s/Library/Application Support/Google/Chrome/%s/Extensions" % (user,profile))
            except:
                #print("/Users/%s/Library/Application Support/Google/Chrome/%s/Extensions does not exist" % (user,profile))
                continue

            url = 'https://chrome.google.com/webstore/detail/'

            # for each extension in extensions folder
            for code in ext:
                extcode = code
                extname = ""
                extuser = user
                extprofile = profile
                extchromestore = ""
                extcomputer = hostname
                extcreationtime = ""
                extdescription = ""
                extversion = ""
                extupdateurl = ""
                extpermissions = ""

                localcreationdate=os.path.getctime("/Users/%s/Library/Application Support/Google/Chrome/%s/Extensions/%s" % (user,profile,code))
                extcreationtime=(datetime.datetime.utcfromtimestamp(localcreationdate).strftime("%m/%d/%Y %H:%M:%S"))
                # print("Extension " + code + " created at " + extcreationtime)

                # pull version, description, name (if exists), update_url, permissions from manifest.json
                try:
                    vers = os.listdir("/Users/%s/Library/Application Support/Google/Chrome/%s/Extensions/%s" % (user,profile,code))
                except:
                    continue
                for folder in vers:
                    manifest = "/Users/%s/Library/Application Support/Google/Chrome/Default/Extensions/%s/%s/manifest.json" % (user,code,folder)
                    try:
                        with open(manifest) as f:
                            manifestjson = json.load(f)

                        if(manifestjson['description'].startswith('__MSG_')):
                            extdescription = "No description found."
                            # print("No description found")
                        else:
                            extdescription = str(manifestjson['description'])
                            # print("Description: " + manifestjson['description'])
                        if (not manifestjson['name'].startswith('__MSG_')):
                            extname = str(manifestjson['name'])
                            # print(manifestjson['name'])
                        extversion = str(manifestjson['version'])
                        # print("Version: " + manifestjson['version'])
                        extupdateurl = str(manifestjson['update_url'])
                        # print("Update_url: " + manifestjson['update_url'])
                        extpermissions = manifestjson['permissions']

                    except:
                        continue

                # Handle default extensions
                code = str(code)
                if code == "aapocclcgogkmnckokdopfmhonfmgoek":
                    if args.showdefaults == "True":
                        extname = "Google Slides"
                        extchromestore = "Default"
                        # print("aapocclcgogkmnckokdopfmhonfmgoek Google Slides")
                    else:
                        continue
                elif code == "aohghmighlieiainnegkcijnfilokake":
                    if args.showdefaults == "True":
                        extname = "Google Docs"
                        extchromestore = "Default"
                        # print("aohghmighlieiainnegkcijnfilokake Google Docs")
                    else:
                        continue
                elif code == "apdfllckaahabafndbhieahigkjlhalf":
                    if args.showdefaults == "True":
                        extname = "Google Drive"
                        extchromestore = "Default"
                        # print("apdfllckaahabafndbhieahigkjlhalf Google Drive")
                    else:
                        continue
                elif code == "blpcfgokakmgnkcojhhkbfbldkacnbeo":
                    if args.showdefaults == "True":
                        extname = "YouTube"
                        extchromestore = "Default"
                        # print("blpcfgokakmgnkcojhhkbfbldkacnbeo YouTube")
                    else:
                        continue
                elif code == "coobgpohoikkiipiblmjeljniedjpjpf":
                    if args.showdefaults == "True":
                        extname = "Google Search"
                        extchromestore = "Default"
                        # print("coobgpohoikkiipiblmjeljniedjpjpf Google Search")
                    else:
                        continue
                elif code == "felcaaldnbdncclmgdcncolpebgiejap":
                    if args.showdefaults == "True":
                        extname = "Google Sheets"
                        extchromestore = "Default"
                        # print("felcaaldnbdncclmgdcncolpebgiejap Google Sheets")
                    else:
                        continue
                elif code == "ghbmnnjooekpmoecnnnilnnbdlolhkhi":
                    if args.showdefaults == "True":
                        extname = "Google Docs Offline"
                        extchromestore = "Default"
                        # print("ghbmnnjooekpmoecnnnilnnbdlolhkhi Google Docs Offline")
                    else:
                        continue
                elif code == "nmmhkkegccagdldgiimedpiccmgmieda":
                    if args.showdefaults == "True":
                        extname = "Google Wallet"
                        extchromestore = "Default"
                        # print("nmmhkkegccagdldgiimedpiccmgmieda Google Wallet")
                    else:
                        continue
                elif code == "pjkljhegncpnkpknbcohdijeoejaedia":
                    if args.showdefaults == "True":
                        extname = "Gmail"
                        extchromestore = "Default"
                        # print("pjkljhegncpnkpknbcohdijeoejaedia Gmail")
                    else:
                        continue
                elif code == "pkedcjkdefgpdelpbcmbmeomcjbeemfm":
                    if args.showdefaults == "True":
                        extname = "Chrome Media Router"
                        extchromestore = "Default"
                        # print("pkedcjkdefgpdelpbcmbmeomcjbeemfm Chrome Media Router")
                    else:
                        continue
                elif len(code) != 32:
                    continue
                    # Directory is not an extension directory
                else:
                    # Look up extension in the Chrome Store
                    # print("Looking up %s" % str(code))
                    try:
                        response = urllib2.urlopen(url+code)
                        html = response.read()
                        title = re.findall(r'(?<=og:title" content=")([\S\s]*?)(?=">)', str(html))
                        extname= str(title)[2:-2]
                        # print ("%s %s" % (code, extname))
                        extchromestore = "Yes"
                    except:
                        # print ("There was an error looking up %s in the Chrome store" % code)
                        if(extname==""):
                            extname = "Unknown"
                        extchromestore = "Not Found"
                        # continue
                # print("Adding %s to dictionary" % extcode)

                od = OrderedDict()
                od["CreationTimeUTC"] = extcreationtime
                od["Name"] = extname
                od["Description"] = extdescription
                od["Chrome_Store"] = extchromestore
                od["Version"] = extversion
                od["Code"]=extcode
                od["User"]=extuser
                od["Profile"]=extprofile
                od["Computer"]=extcomputer
                #od["Update_URL"]=extupdateurl
                if args.showpermissions == "True":
                    od["Permissions"]=extpermissions
                extlist.append(od)

    except:
        err = { 'error' : "There was an error on %s." % (code) }
        extlist.append(err)

# Output to nicely readable JSON blob
#print(json.dumps(extlist))
print(json.dumps(extlist, indent=4))

