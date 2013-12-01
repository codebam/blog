---
title: Picking Random Items From a File
author: Alex Beal
date: 01-11-2012
type: post
permalink: Picking-Random-Items-From-a-File
---

Here's a deceptively simple programming puzzle: Develop an algorithm for randomly selecting *n* words from a dictionary file. This is essentially the puzzle I had to solve in order to write my [xkcd-style password generator](https://github.com/beala/xkcd-password), which implements the [xkcd password spec](http://xkcd.com/936/).<sup>1</sup>

The simplest solution is to parse the dictionary into individual words (easy to do in Python) and put those words into a list. Selecting four random words is then as easy as selecting four random items from the list. This is fast, easy to implement, and simple to understand, but it is also very memory inefficient. I have to load 50,000+ words into memory in order to select four of them.<sup>2</sup> Can we do better? Yes.

##A Memory Efficient Algorithm##
The key insight into developing a better algorithm is realizing that it should be possible to select the words as the dictionary file is being parsed, rather than loading the entire thing into memory. The difficulty is making sure that each word has an equal chance of being chosen, and that at least *n* words are chosen. If, for example, we simply give each word a 1 in 10 chance of being chosen, we'll end up with way more words than we need (assuming *n* is small). If we give each a 1 in 50,000 chance, there's the possibility that we won't choose enough words. Bryce Boe has [a clever solution](http://www.bryceboe.com/2009/03/23/random-lines-from-a-file/) to this problem where he chooses exactly *n* words, but the proof that it works is non-trivial, and he doesn't provide it. This is why I came up with my algorithm.
 
In order to explain my algorithm, it's best to think of it in terms of rolling dice. Consider the following procedure for randomly selecting 4 dice from 10.

1. Roll all 10 dice.
2. Select the 4 with the highest values.
	1. If, suppose, 5 of the dice all end up with a value of 6, randomly choose 4 from those 5 (perhaps by repeating the procedure with those 5).
	2. If, suppose 2 dice get a value of 6, and 3 get a value of 5, select the 2 with the value of 6, and then randomly select 2 of the 3 with a value of 5.

How can we adapt this procedure to select random words from a file, rather than dice? Here's how: as we're parsing the dictionary file, we give each word a random value, and then select the *n* words with the highest values. The issue is, the naive implementation of this procedure doesn't really solve our memory problem. If every word gets a random value, don't we now have to store every word in memory, along with its value? The key here is to observe that only the words with the *n* highest values need to be kept in memory, and all the others can be immediately discarded. Think about this in terms of the dice example. I want to select 1 die from 10:

1. I roll the first die. I get a value of 1. I keep this die.
2. I roll the second. I get a value of 3. I keep this die, and discard the other.
3. I roll the third. I get a value of 3. I keep both dice.
4. Fourth: I get a value of 6. I keep this die and discard the other 2.

By the end of the procedure, I might end up with 3 dice that all got a value of 6. I would then randomly select 1 from those 3.

How can we adapt this procedure for selecting random words? We use a priority queue:

1. Read a word from the dictionary.
2. Give it a random value.
3. Insert the value-word pair (as a tuple) into the priority queue.
4. If the queue has more than *n* items, pop an item.
5. Repeat until every word has been read.

Remember that popping from a priority queue removes the item with the lowest value. So, we insert a word, and if we have too many words, we pop the one with the lowest value. At the end of this procedure there will be exactly *n* words in the queue. These are our *n* random words. Neat.
 
There is one issue, though. What if two words have the same random value? Well, one solution is to keep both words, and then break the tie at the end like we did in the dice example, but that breaks the elegance of the priority queue implementation. Another is to break ties randomly as soon as they occur, and discard the losing word, but I'm not sure how to do this in a statistically safe way. The easiest solution is to just pray that collisions don't occur. In Python, each call to `random()` produces 53-bits of precision, so it's very unlikely that two values will collide. If 53-bits isn't enough (yeah right), you can use multiple random numbers. So, rather than a tuple of `(value, word)`, you can use `(value_1, value_2, value_3, word)`.<sup>3</sup> Python's priority queue implementation will automatically know how to sort that.
 
Without further ado, here's the proof of concept:

``` python
#!/usr/bin/python -O

import random
import heapq

DICT_PATH = "/usr/share/dict/words"
WORD_COUNT = 4

dict_file = open(DICT_PATH)
wordq = []
for line in dict_file:
    word = line.strip()
    rand_val = random.random()
    heapq.heappush(wordq, (rand_val, word) )
    if len(wordq) > WORD_COUNT:
        heapq.heappop(wordq)

print wordq
```


##Endnotes##
1.  Summary: a good password is composed of four random words.
2. A slight improvement on this would be to store only the word's position in the file, rather than the word itself. Then the word could be retrieved by seeking to that position. [http://www.bryceboe.com/2009/03/23/random-lines-from-a-file](http://www.bryceboe.com/2009/03/23/random-lines-from-a-file)
2. <del>If you're only using one random value, and your dictionary file has 50,000 words, the chance of a collision is 50,000/2^53 , which is roughly 3 in 562 trillion. I'll take those odds.</del> Whoops! This is actually a version of the [birthday problem](http://en.wikipedia.org/wiki/Birthday_problem). The actual probability of a collision is: 1.39e-7. Still quite good.
