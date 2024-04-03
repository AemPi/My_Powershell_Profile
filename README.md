# Install

To get everything running you need to do the following things
- Open a Powershell in Admin Mode
- Clone this into ".config" (you need to create a folder named .config)
  ```Powershell
  mkdir "$env:userprofile\.config"
  ```
  ```
  git clone https://github.com/AemPi/My_Powershell_Profile.git ~/.config/PWSH
  ```
- cd into the ".config\PWSH" Directory and run the install Script
  - ```Powershell
    .\install.ps1
    ```


## For SSH functionality you need to install SSH. 

```Powershell
Add-WindowsCapability -Online -Name OpenSSH.Client*
```
In the .ssh folder you find a File "config" (Set ONLY you in the Security ACL with Full Access).
The File Structre is Linux based:
```bash
Host <alias>
    HostName <IP/FQDN>
    Port <PORT_NUMBER>
    User <USER> 
    IdentityFile <PATH_TO_YOUR_KEY>
```
After this you´re good to go and have fun!

## pss / new PS-Session
- pss (new PS-Session -> ssh like) <= With Tab Completion for Hosts in the config File in the "C:\Users\<YOURNAME>\.pss" Directory
- In the config File you need only the following syntax  
  ```Bash
  host testhost.domain
  or
  host testhost
  or
  host IP
  ```

# Now you have the following Functions in your Powershell
- ll (Linux like ls -lsah)
- ls-dirsize (for list folder size)
- df / df -h $true (for Disk Space listing)
- and much more in the Folder .config\misc\CustomModules

pss folder
  ```Powershell
    pss <FQDN/IP> -domain $true / $false #True for Domain Login via Kerberos. False with Username and Password
  ```
  - ctrl+d for Disconnect and remove session
- A History function (Linux like in your User Folder "C:\User\\\<USERNAME>\\\.pwsh_history.txt")
- Auto Tabcompletion
- Auto Complete for ([{"''"}])
- Logfile Function
  ```Powershell
    Write-LogFile -Status INFO -Message "INFO" -LogPath "C:\YOUR\PATH\TO\FILE.txt"
    #Output is just => 2022-08-12 21:30:56 [INFO] :  INFO
    Write-LogFile -Status OKAY -Message "OKAY" -LogPath "C:\YOUR\PATH\TO\FILE.txt"
    #Output is just => 2022-08-12 21:30:56 [OKAY] :  OKAY
    Write-LogFile -Status WARN -Message "WARN" -LogPath "C:\YOUR\PATH\TO\FILE.txt"
    #Output is just => 2022-08-12 21:30:56 [WARN] :  WARN
    Write-LogFile -Status FAIL -Message "FAIL" -LogPath "C:\YOUR\PATH\TO\FILE.txt"
    #Output is just => 2022-08-12 21:30:56 [FAIL] :  FAIL
    Write-LogFile -Status DEKO -Message "DEKO" -LogPath "C:\YOUR\PATH\TO\FILE.txt"
    #Output is just => =================================================
  ```
- If you have Git installed and you enterd a Git Folder your Prompt Looks like this
  ```Powershell
  [USER@HOST] (~\Path\to\git-folder) [git-master : A0|M1|D0|Ut0] # 
  
  # git-master = Your Branch
  # A0 = A for Added
  # M1 = M for Modifyed
  # D0 = D for Delted
  # Ut0= U for Untracked
  ```

  # Uninstall
- Open a Powershell in Admin Mode
- cd into the ".config\PWSH" Directory and run the install Script
  - ```Powershell
    .\uninstall.ps1
    ```