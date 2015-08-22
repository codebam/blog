---
title: Secure Versioned Remote Backups with Rdiff-Backup
author: Alex Beal
date: 08-13-2011
type: post
permalink: Secure-Versioned-Remote-Backups-with-Rdiff-Backup
---


When putting together a backup solution for this web server, I was looking for a few things:

1. **Simplicity:** The less new software, the better. Rsync is both powerful and complex, and I wanted to avoid it. Other things being equal, simple solutions are also more reliable.
2. **Security:** I needed to prevent an attacker who gained access to my web server from also gaining access to my backup server. Backing up over an encrypted connection was also a necessity.
3. **Versioning:** I needed my solution to keep several versions of all my files. A solution that only keeps the most recent version of a file is useless, if that version turns out to be corrupted.
4. **Incrementing:** An efficient backup solution should only update the files that have changed. This ruled out simply tar-ing and ssh-ing my entire webroot over to my backup server.
5. **Automation:** This solution should automatically run as a cron job.

As you can see, some of these goals conflict. Wanting versioned incremental backups, while also ruling out rsync just made my life harder. Automation and security also butt heads. If my web server can access my backup server without a password, how can I prevent an attacker who's taken over my web server from trashing my backups? As I'll show, I managed to piece this together with only one new software package: rdiff-backup. This took care of versioning and incrementing in a simpler way than rsync would have. The rest was achieved with tools installed on every web server: ssh and cron.

##Backing up with rdiff-backup##
Let's start with rdiff-backup. This is dead simple. On Ubuntu, installing is only an apt-get away. This needs to be done on the web server and backup server:

    sudo apt-get install rdiff-backup
    
Backing up to a remote directory over ssh isn't much harder:

    rdiff-backup /var/www backups@example.com::/var/backups

That will backup the local directory `/var/www` to `/var/backups` on `example.com` using the ssh user `backups`. It's that simple. rdiff-backup handles the versioning and incrementing automatically. Also, since it's done over ssh, everything is encrypted.
Restoring is just as easy:

    rdiff-backup -r 3D backups@example.com::/var/backups/www /var/www.old
    
That will copy whatever you backed up to `/var/backups/www` three days prior to `/var/www.old` on the local machine. Hopefully by now you see why I love this utility. It's basically rsync, but stripped down and rebuilt specifically for backups. Best of all, there are no config files or servers to maintain.

##Automation with cron##
So, those are the basics of rdiff-backup. How do we automate this? Here's the backup script that I use on this web server:

``` sh
    #!/bin/bash

    RDIFF="/usr/bin/rdiff-backup"
    REMOTE="backups@example.com::/home/backups/newest/"
    CONF="/etc/backups"

    cat $CONF | while read DIR; do
            $RDIFF $DIR $REMOTE$(basename $DIR)
            if [ $? != 0 ]; then
                    echo "Exited with errors. Backup process stopped at $DIR"
                    exit 1;
            fi
    done
```

What this does is read the paths I've listed in the text file `/etc/backups`, and backs those up to `/home/backups/newest` on the machine `example.com` with the user `backups`. So if `/etc/backups` looks like this:

    /etc/
    /home/alex/
    /var/www/
    
Then all those directories get backed up to the remote machine. The first time it's run, it simply mirrors the directories to the remote machine. Each consecutive execution only copies the changed files over. Versioning is, of course, handled automatically by rdiff-backup.
 
I wrote the script to be easily customizable. Change `$REMOTE` to modify which machine, user, and directory the files are backed up to. Change `$CONF` to modify which file contains all the paths to be backed up. `$RDIFF` simply points to wherever the rdiff-backup binary is (well, python script, actually). As it's currently set, `$RDIFF` should work on Ubuntu 10.04 machines.
 
To automate this, simply set it as a cron job on the web server, and run it hourly or daily. Make sure the user running the job has high enough privileges to access the files you want to back up (unless you want to set up some complex permissions, simply running this as root is an unfortunate necessity).
 
Finally, on the remote machine, you may want some sort of script that manages the backup directory. One idea would be to have the backup directory tar-ed and compressed, then saved somewhere safe. Once that's done, the directory could be cleared out, so the next time the backup script runs, a fresh copy of all the files would be copied over. Set this to run once a week and you'll have weekly full backups, with nightly (or hourly) incremental backups. The following script will do that for you:

``` sh
    #!/bin/bash

    NEW="/home/backups/newest"
    OLD="/home/backups/archive"

    # Tar and compress the old files
    (
        cd `dirname $NEW`
        tar -zcf "$OLD/`date "+%F-%H%M"`.tar.gz" "`basename "$NEW"`"
    )

    # Clear out the backup directory
    if [ $? == 0 ]; then
        rm -rf "$NEW"
        mkdir "$NEW"
    else
        echo "Exited with errors. Nothing was deleted, but the files may not have been rotated."
        exit 1
    fi
```

`$NEW` is the location of your newest backups. `$OLD` is where you want the tar-ed and compressed copies stored.

##Security with ssh##
We're almost there. Rdiff-backup is installed, and the scripts are automatically backing up and rotating our backup files. The only problem is that every time the script connects to the backup server, it's asked for a password (the remote user's ssh password). We can't be there to type it in, so how do we deal with this? The solution is to create a public/private key pair that the script can log in with. There are lots of places on the web that have detailed instructions on how to do this, but I'll run through it quickly.
 
First we decide which user is running the backup script on our web server. If it's root, then we log in as root and run `ssh-keygen`. When prompted for a password, leave it blank. After this is done, we need to copy the public key located under `/root/.ssh/id_rsa.pub` to the remote machine. If we're logging in as backups on the remote machine, then we copy the public key into the `/home/backups/.ssh` directory (create the `.ssh` directory if it doesn't already exist) and rename the file `authorized_keys`. Now when root connects over ssh to the backup server, he won't be prompted for a password, and neither will the backup script being run as a root cron job. Ahhh the magic of public key cryptography.
 
The obvious problem here is that if an attacker gets root on the web server, he has access to the backup server. Lucky for us, ssh has a built in way of restricting a remote user to only one command. We do this by prefixing the public key with `command="RESTRICTED_COMMAND"`. So, for example, we can restrict a remote user to rdiff-backup by modifying the `authorized_keys` file to look something like this:

    command="rdiff-backup --server --restrict-update-only /home/backups/newest/" ssh-rsa AAB3NzaC1 [...]
 
That allows a remote user to only execute rdiff-backup in server mode. But notice the second flag `--restrict-update-only`. That restricts the user to the backup directory, and only allows her to update the backups, and not delete or otherwise trash them. Pretty cool. The worst an attacker could do is fill the backup server's hard drive by pushing a huge amount of data to it, but since rdiff-backup is versioned, no old versions of the files will be lost.
 
Also, there are additional options you can prefix to the public key to lock down the server even more. Check out the `ssh-keygen` man pages, and look under the `-O` flag.

##Conclusion##
So, that's my custom built backup solution. I realize I glazed over a lot of small details, and this isn't really a step by step how-to (e.g., I never explained how to set up a cron job). I leave it as an exercise to the reader to put it all together. To help you, I've included the scripts at the bottom of this post. I also check the comments obsessively, so please don't hesitate to ask if you have any questions.

[Download the scripts.](http://media.usrsb.in/rdiff-backup/backup.zip)
