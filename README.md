# Upgrade_Teams
Set of scripts to be used with GPO to upgrade from Microsoft Teams (Legacy)

## Machine.ps1
- Uninstalls Teams (Legacy) Machine-Wide installer
- De-Provisions Teams (Home) AppX if applicable
- Provisions Teams (New) plus depencies
  - Microsoft.UI.Xaml (Latest)
  - Microsoft.VCLibs (14.00)
  - Desktop App Installer (WinGet, Latest)
- Installs Edge WebView2

## User.ps1
- Uninstalls Teams (Home)
- Uninstalls Teams (Legacy)
- Installs Teams (New) plus dependencies
  - Microsoft.UI.Xaml (Latest)
  - Microsoft.VCLibs (14.00)
  - Desktop App Installer (WinGet, Latest)


If it is not obvious, `Machine.ps1` needs to run in the Machine Scope (Administrator perms or above), and `User.ps1` needs to be running as the end-user (No admin rights required)

The provisioning of UWP apps does not apply to existing profiles, as they are installed during first logon ("We're getting things ready for you"). Hence the need for `User.ps1` to correct existing profiles. 


### **This is not guaranteed to work if you do not deploy both scripts.**
