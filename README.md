## GitHub Pages for `r0bsec.github.io/thm-writeups`

This is is the source for [https://r0bsec.github.io/thm-writeups](https://r0bsec.github.io/thm-writeups). This uses Github Pages and Jekyll.

[![pages-build-deployment](https://github.com/r0bsec/thm-writeups/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/r0bsec/thm-writeups/actions/workflows/pages/pages-build-deployment)

## Scripts

If you clone or fork this repository as a template to do your own write-ups, there are few scripts that make things a little easier to work with.

### Script: `newroom.sh`

When you start a new CTF room, you typically want a new folder for the files that you will work on. This script:

1) Creates the directory relative to the path of this script.
2) Adds a `$ROOM` environment variable to your `~/.zsch` file which is the absolute path of this new directory. This means you can do things like `cd $ROOM` and `some-cmd 2>&1 $ROOM/some-cmd.log`
3) Copies a default `index.md` and `_booty.txt` file into your room. The index file will be the Markdown file of your write-up. The Booty file is a text file that will not be checked-into git (it's excluded in the `../.gitignore` file). This is just a free-form text file, like a workbench area where you can paste-in found credentials, interesting items, notes, usersnames, etc. Just a place to capture raw information as you are processing a room.
4) In your `index.md` sets the default room information to the same name as this new folder.
5) Changes you into the new directory.

> *NOTE: You will need to run `source ~/.zshrc` to pick up the new `$ROOM` environment variable. When you pop open a new terminal, that new session will pick it up too, so that you can quickly `cd $ROOM` for example.*

Example output:

```bash
[*] STEP 1: Create the directory if it doesn't exist: /home/r0bsec/gitlocal/r0bsec/thm-writeups/zzTest/
[*] STEP 2: Setting ROOM environment variable
[+] ROOM export statement updated in: /home/r0bsec/.zshrc
[*] Reloading .zshrc environment (/home/r0bsec/.zshrc)
[*] STEP 3: Copy files from _TemplateRoom to: /home/r0bsec/gitlocal/r0bsec/thm-writeups/zzTest/
[*] STEP 4: Search and replace %ROOM% in files
[*] STEP 5: Changing directory to /home/r0bsec/gitlocal/r0bsec/thm-writeups/zzTest/
[+] All steps completed successfully
```

### Script: `chroom.sh`

Assuming you are using this directory structure, `chroom.sh` just changes you into the specified, existing room:

```bash
./chroom.sh picklerick
```

This too, most notably, will set the `$ROOM` environment variable in your `~/.zshrc` and where you will need to `source ~/.zshrc` to pick up the new value. New terminals WILL pick up the new value automatically.

Example output:

```bash
[+] ROOM export statement added to: /home/r0bsec/.zshrc
[+] ROOM environment variable changed to picklerick

[*] Please run the following command to reload your environment:

  source /home/r0bsec/.zshrc

```


### Script: `set-target.sh`

When doing a Capture The Flag (CTF) event, you likely keep forgetting the IP address of your target. If you pass the IP address to this script, it will put it in an environment variable. That way you can just use `$TARGET` at the command line, any time you want to reference that IP address. Note: you do need to `source ~/.zshrc` for the new `$TARGET` to take effect. Example output:

```bash
[+] TARGET export statement added to: /home/r0bsec/.zshrc
[+] TARGET environment variable changed to localhost

[*] Please run the following command to reload your environment:

  source /home/r0bsec/.zshrc
    
```

You can then do things like: `nmap -sCV $TARGET`.

### Script: `start-recon.sh`

There are some common things you'd want to do when tackling a new CTF room. Well, in this suite of scripts, your `$ROOM` environment variable will be set to the directory of your room. Also, `$TARGET` (set from `set-target.sh`) will be the IP or hostname of your target machine.

Putting that together, you can set up more or less commands that you'd want to run. For example:

```bash
tasks["nmap"]="nmap \$1 | tee \"$ROOM/nmap.log\" &"
tasks["gobuster"]="gobuster dir -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u http://\$1 2> /dev/null | tee \"$ROOM/gobuster.log\" &"
tasks["nikto"]="nikto -h \$1 2>&1 | tee \"$ROOM/nikto.log\" &"
```

Then, this kicks off these commands, running as background tasks, and waits for them to complete. You can run `jobs` and `fg` in a terminal to watch them, or you can just go into VS Code and click on the log files to see real-time updates.

> *NOTE: This uses `espeak` to let you know when it's done, so that you don't need to visually monitor this process.*

You can run this with `./start-recon.sh $TARGET`.

### Script: `killbyname.sh`

It's often difficult to remember the syntax for looking up a running process by name, get that Process ID (PID), and then kill that:

```bash
NAME="mousepad"
kill $(sudo ps -A | grep ${NAME} | cut -d " " -f 1)
```

So, this script does exactly that. Just pass it the name of a process.


### Script: `linpeas.sh`

This is simply a local copy of the real linpeas.sh privilege escalation tool [available here](https://github.com/carlospolop/PEASS-ng). A CTF will rarely have access to the internet, but they can download from your workstation, so it's helpful to have a copy. Use `linpeas-getlatest.sh` to get the very latest.

### Script: `linpeas-getlatest.sh`

This script goes out a gets the very latest version of the script from github. Example output:

```bash
[*] Fetching the latest release URL...
[!] linpeas.sh already exists. Removing...
[*] Downloading the latest version of linpeas.sh...
[+] linpeas.sh has been downloaded successfully.
[*] linpeas.sh has been made executable.
```
