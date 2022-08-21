# My_Powershell_Profile

To get everything running you need to do the following things
- Open a Powershell in Admin Mode
- install the module "PSReadLine" Latest!
  - ```Powershell
    install-module psreadline -force
    ```
- Add a Folder named ".pss" in your User Directory
  - ```Powershell
    mkdir "$env:userprofile\.pss"
    ```
  - In the .pss Folder Create a file named "config"
    ```Powershell
    New-Item -Path "$env:userprofile\.pss" -Name "config" -ItemType File
    ```
    The Entrys in the "config" file are quite simple:
    ```Powershell
    host <FQDN/IP>
    ```
- Place the ".pwsh_profile.ps1" File in your User folder "C:\User\\\<USERNAME>"
- Add a File Named "profile.ps1" under "C:\Windows\System32\WindowsPowerShell\v1.0" (for Powershell 5.1). Open the File in a Editor with Admin mode and put the line ". $env:userprofile\\\.pwsh_profile.ps1" in and Save it.

For SSH functionality you need to install SSH. Then create a folder in "C:\User\\\<USERNAME>" named ".ssh". <= With Tab Completion for Hosts in the config File in the .ssh folder
In this Folder you need a File "config" with ONLY you in the Security ACL with Full Access.
The File Structre is Linux based:
```bash
Host <alias>
    HostName <IP/FQDN>
    Port <PORT_NUMBER>
    User <USER> 
    IdentityFile <PATH_TO_YOUR_KEY>
```
After this you´re good to go and have fun!


# Now you have the following Functions in your Powershell
- ll (Linux like ls -lsah)
- ls-dirsize (for list folder size)
- df / df -h $true (for Disk Space listing)
- pss (new PS-Session -> ssh like) <= With Tab Completion for Hosts in the config File in the .pss folder
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