---
title: Using 'trap' To Catch 'Ctrl + C's and Control How Your Script Exits
author: Alex Beal
date: 04-02-2011
type: post
permalink: Using--trap--To-Catch--Ctrl---C-s-and-Control-How-Your-Script-Exits
---

So you've written a script that creates all sorts of temporary files, and launches dozens of processes in the background, and, as is, the script runs indefinitely. The only way to quit is Ctrl + C, but once you fire off this hotkey combo, you're left with a mess of background processes and temp files. There are lots of reasons why your script might do this. For example, I'm currently writing a download manager that sends its wget processes to the background, and creates various temporary status files. It runs indefinitely because it polls a queue file, which contains the URLs of the files it's instructed to download. So, given all that, how is it that I get my script to clean up after itself once I deal it the fatal Ctrl + C blow (or more technically, a "signal interrupt" or "SIGINT" for short)? The trick here is to use the `trap` command along with some basic process manipulation. Here's the syntax:

    trap 'command' signal_to_trap

The above bit of code will cause the *command* (or string of commands between the quotes) to execute if the script is issued a *signal_to_trap*. As is implied by the syntax, you can trap more than one type of signal. To catch the Ctrl + C combo, you usually want to trap a SIGINT, which is done as follows:

    trap 'echo "Exiting"; exit 0' INT

That bit of code will cause your script to print the message "Exiting" and exit with status 0 once Ctrl + C is pressed (or gets issued a SIGINT some other way). One important caveat is **always remember the exit command.** For example, the following code will cause your program to print "Exiting" and then continue, effectively ignoring the SIGINT. What NOT to do if you want your program to actually quit:

    trap 'echo "Exiting"' INT

Of course, that construct isn't without its uses. Perhaps you want your script to immediately run some routine if Ctrl + C is entered, but you don't want it to quit. The above bit of code would be the way to do it, but that strikes me as a confusing break from convention. Most people expect Ctrl + C to stop the currently running process. A better way to do this would be to use a USR signal. Just substitute `INT` for `USR1` or `USR2`, and send the `USR` signal to the script using the kill command: `kill -USR1 pid`. In any case, back to the topic at hand: exiting a script cleanly.

##'Trapping' and Cleaning Up After Yourself##
The way I use 'trap' is something along these lines:

    exit_routine () {
        # TODO: Clean up stuff.
    }
    trap 'exit_routine' INT # Intercept SIGINT and call exit_routine

If it's short enough, you can, of course, cram your entire exit routine between the single quotes, but if it's nontrivial it's best to pull it out into its own function. Also remember that BASH executes a script's commands in the order it sees them, so this must be placed somewhere near the beginning of the script to set the `trap` early on. (Perhaps that's obvious, but I'd be the first to admit that that's just the sort of pitfall I'd waste an hour puzzling over.) Also remember that the function must be declared before the `trap` statement (or at least before the script receives a SIGINT and tries to call `exit_routine`).

##Cleaning Up Stuff (Processes)##
Now that we've declared the exit routine and set the trap, we need to do some actual housekeeping. I do this by keeping track of all the background processes' PIDs and temporary files' filenames in an array. Consider the following code:

    for i in $(seq 3); do
        wget "$URL[$i]" & 
        PIDS[$i]=$!
    done

Three `wget` instances are launched and sent to the background with the `&` operator. Their PIDs are accessed with the `$!` variable and stored to `$PIDS`. We can now kill off those processes with the following bit of code:

    exit_routine () {
        kill ${PIDS[*]}
        echo "Script exiting."
        exit 0
    }
    trap 'exit_routine' INT

Whenever Ctrl + C is pressed, the SIGINT is trapped and `exit_routine` is called. `kill` is then given all the PIDs, which are accessed using `${PIDS[*]}`. This kills the wget processes, an exit message is printed, and the script is exited. The neat thing about the `${ARRAY[*]}` way of accessing all an array's elements is that empty elements won't be returned. So if I do:

    PIDS[5]="5"
    PIDS[10]="10"
    echo ${PIDS[*]}

Then only "5 10" is printed.

##Dealing with Temp Files##
Erasing temp files is a bit more tricky. The possibility of white space characters in a file's name makes `rm ${FILES[*]}` troublesome. Enclosing the array in double quotes doesn't help either. Instead, we need to step through the array as follows:

    for i in $(seq 3); do
        rm "${FILES[$i]}"
    done
    
If we want to ignore the empty elements of `$FILES` like `${PIDS[*]}` automatically did for the PIDs, then we can test if an element is empty using an if statement. Alternatively, you can impress your friends with some BASH-fu and take advantage of BASH's short circuit functionality:

    for i in $(seq 3); do
        [ "${FILES[$i]}" != "" ] && rm "${FILES[$i]}"
    done

If `${FILES[$i]}` is empty, the statement short circuits, and does nothing. If it contains something, the `rm` command is executed.
 
So, that's how it's done. Now you have no excuse for leaving garbage behind (if only BASH had some way of automagically collecting this so called garbage!), and, as always, if you have any tips regarding this, please share your BASH-fu with us in the comments!
