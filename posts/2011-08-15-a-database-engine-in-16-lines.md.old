---
title: A Database Engine in 16 Lines
author: Alex Beal
date: 08-15-2011
type: post
permalink: A-Database-Engine-in-16-Lines
---


Recently I've been playing around with a neat command line utility called netcat. It makes it incredibly easy to add networking functionality to your scripts. What it does is allow you to open a port on your machine and listen for incoming connections. Should a connection occur, anything the remote machine sends is dumped to stdout, and anything written to stdin is sent out to the remote machine. As a demo, I decided to write a database engine with it, and I managed to do it in 16 lines.  

``` sh
	#!/bin/bash
	
	PORT=1234
	DATA_FILE="/full/path/to/data"

	listen () {
		TIMEOUT=10
		echo "$2" | nc -l -p $1 -w $TIMEOUT -q 0 
	}

	while :; do
		ANSWER_PORT=$((RANDOM % 1000 + 1028))
		QUERY="$(echo $ANSWER_PORT | nc -l -p $PORT -q 2)"
		ANSWER="$(grep "^$QUERY," "$DATA_FILE" | sed "s/ $QUERY, //")"
		listen "$ANSWER_PORT" "$ANSWER" &
	done
```

The database itself is simply a text file full of key-value pairs. So, a remote machine can send over a key, and the database responds with that key's corresponding value. If, for example, the database was full of names (keys) and phone numbers (values), a remote machine could send over someone's name, and the database would respond with that person's phone number. Not bad for 16 lines.  

Before I step through the code, I'll explain its overall functionality. When first executed, the script opens up port 1234 and listens. When a remote machine wants to query it, the remote machine connects to port 1234 and sends over its query (a key). The script receives this and, over the same connection, sends back a random number between 1028 and 2028. Suppose the random number is 1050. The database will then open up port 1050, and when the remote machine connect to that port, the database will send its answer over that connection (the value corresponding to the key), and the transaction is finished. Let's look at the code now.

##Analysis##
The script starts off with two variables. The first is the port that the script listens on for incoming queries. The second points to the text file containing the key-value pairs. The file would look something like this:

	alex beal, 555-555-5555
	bob, 111-111-1111
	joe, 222-222-2222

Where, "alex beal", "bob", and "joe" are the keys, and the values corresponding to those keys are listed after the comma. Let's skip over the listen function for now and examine the while loop below it.

	while :; do
		ANSWER_PORT=$((RANDOM % 1000 + 1028))
		QUERY="$(echo $ANSWER_PORT | nc -l -p $PORT -q 2)"
		ANSWER="$(grep "^$QUERY," "$DATA_FILE" | sed "s/^$QUERY, //")" 
		listen "$ANSWER_PORT" "$ANSWER" &
	done
	
The first line is a while loop that continues forever until the script receives an interrupt. The second two lines get a random number between 1028 and 2028 and store it to `$ANSWER_PORT`. That value is piped into the netcat instance on the third line, which listens for connections (`-l`) on port 1234 (`-p $PORT`). Once a connection is established, and the random port number is sent, the remote host has 2 seconds to send over a query (`-q 2`), which gets stored to `$QUERY`. This means that after the first two lines have executed, the query is received, and the random answer port is sent.  

The next lines search through the database file for the key-value pair. Searching the database is as simple as `grep`-ing the data file for the line beginning with the key, and stripping that key from the output with sed.

Finally we call the `listen` function defined above. This is passed the port that the client must connect to to receive the answer (`$ANSWER_PORT`), and the answer itself (`$ANSWER`).

	listen () {
		TIMEOUT=10
		echo "$2" | nc -l -p $1 -w $TIMEOUT -q 0 
	}
	
The answer, which is the second argument (`$2`), is piped into netcat (`nc`). The flags tell it to listen (`-l`) on the port passed to it as the first argument (`-p $1`). The netcat instance will stop listening after `$TIMEOUT` seconds, and after the answer is sent, it will close immediately (`-q 0`). As you can see, the listen function is called as a background process, so the loop can continue back to the top, allowing other requests to be handled while the answer is sent to the client in the background.

##The Client's Script##
You can query it remotely with this script:

	#!/bin/bash
	ANSWERPORT=$(echo "$2" | nc $1 1234)
	sleep 1s
	nc $1 $ANSWERPORT
	
The first line both receives the answer port, and sends over the query. The script then sleeps for 1 second, while the database handles the request. Finally, it connects a second time to retrieve its answer. The script is used as follows:

	query.sh REMOTE_IP QUERY_STRING
	
##Conclusion##
Although this was a fun exercise, the script itself isn't very practical. It's slow (at least compared to MySQL), and probably insecure, but there might be a use for it on a private network with trusted users. The take away points here are the different netcat constructs that you could apply to your own programs, such as sending and receiving at the same time, and setting up a client-server model. Definitely let me know in the comments if you end up making something cool!

[Download the scripts.](http://media.usrsb.in/db/db-scripts.zip)
