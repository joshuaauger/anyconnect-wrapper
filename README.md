# anyconnect-wrapper

### Information
This script can be used to create a Launch Agent and/or use the vpn wrapper to alleviate some of the headaches of the Cisco Anyconnect VPN.  

### Installation
There is an installation feature that will add the launch agent and binary/script.  

`./setup.sh --install`

### Uninstallation
There is an uninstall feature that will remove the launch agent and binary/script.  

`./setup.sh --uninstall`

### Updating
If you clone this repo from a github repository, there is an update feature that will update this repository and then update the relevant parts.  

`./setup.sh --update`

### Configuration Changes
If you want to change the configuration, you can use this to remove the current and prompt for a new configuration.

`vpn --config`

### Hidden Features

`vpn --agent disable` this will place a file so that the launch daemon will not prompt.  
`vpn --agent enable` this will remove the file so that the launch daemon will prompt.  
`vpn --status` can be useful to troubleshoot issues, or verify you're connected.

### Security
I'm not saying this is great but it basically just stores the password in the keychain, this is probably fine?  

### Notes
This installation is customized to how our Anyconnect is setup, you can modify the vpn.sh to change the group, two factor or passwords are handled.  

There is a GUI part to this, so if you don't like that I recommend disabling the Launch Agent and just using the wrapper such as:
`vpn --connect`, `vpn --disconnect` from the command line and/or your favorite launcher such as ***Raycast*** or ***Alfred***.