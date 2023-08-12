---
title: "THM:%ROOM%"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/%ROOM%"
category: "CTF"
tags: ctf,nmap,gobuster,dirbuster,session,broken-authentication,javascript,apache,ubuntu,john,gpg2john,linpeas,privesc,cron
---
# THM:%ROOM%

URL: [https://tryhackme.com/room/%ROOM%](https://tryhackme.com/room/%ROOM%) [Easy]

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

> TBD

## Scanning

### Running: `nmap`

Ran the following:

> `nmap -sCV x.x.x.x`

Interesting ports found to be open:

```python
PORT   STATE SERVICE REASON
TBD
```

Also see: [nmap.log](nmap.log)

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u http://x.x.x.x`

Interesting folders found:

```python
/TBD                  (Status: 301) [Size: 0] [--> img/]
```

Also see: [gobuster.log](gobuster.log)

### Running: `nikto`

Ran the following:

> `nikto -h x.x.x.x`

Interesting info found:

```python
TBD                                   
```

Also see: [nikto.log](nikto.log)

## Gaining Access

### Unprivileged Access

TBD


## Maintaining Access

TBD

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

Completed: [<kbd>CTRL</kbd>+<kbd>SHFT</kbd>+<kbd>I</kbd> (requires `jsynowiec.vscode-insertdatestring` VS Code Extension)]