---
title: Picking Random Items: Take Two (Hacking Python's Generators)
author: Alex Beal
date: 01-14-2012
type: post
permalink: Picking-Random-Items--Take-Two--Hacking-Python-s-Generators-
---

Earlier today I had my mind blown by David Beazley's [presentation on the power of Python's generators](http://www.dabeaz.com/generators/), and it inspired me to write this highly Pythonic version of [the random word selector](Picking-Random-Items-From-a-File.html), made almost entirely of generators:

``` python
import heapq
import random

lines       = (line for line in open("/usr/share/dict/words"))
word_pairs  = ((random.random(), word) for word in lines)
rand_pairs  = heapq.nlargest(4, word_pairs)

rand_words  = [word for rand, word in rand_pairs]
print rand_words
```

How does this work? First recall that a generator is an object that returns the next item in a sequence every time its `next()` method is called. There's an example of this on line 4 where a generator named `lines` is created, which returns the next line of the file every time `lines.next()` is called. What's so handy about a generator is that it can be automatically consumed by a `for` loop. That is, put a generator in a `for` loop, and the loop will automatically call the generator's `next()` method on every iteration. There's an example of this on line 5 where another generator is created that uses a `for` loop to consume the `lines` generator. This outputs a tuple containing a random number and the line returned by `lines.next()`. So, the result is that each time `word_pairs.next()` is called, you get the next line of the file paired with a random value (e.g., `(0.12345, 'fire\n')`). Finally, we use `heapq.nlargest(n, iter)` to grab the `n` largest elements from `iter`. In this case, it repeatedly calls `word_pairs.next()` and outputs a list of the 4 words with the highest random values.<sup>1</sup> These are our 4 random words. This is all done in around 3 lines (excluding `import`s and `print`ing). Wowza.

As Beazley points out, one advantage of this technique is that it resembles the way simple commands are chained together in the shell to create a pipeline. And, just like in the shell, the pipeline is highly modular, so different filters and stages can be easily inserted at different points. Below, I've added two stages to the pipeline that strip the words of their newline characters, and skip words that aren't exactly 13 characters long:

``` python
import heapq
import random

def isValid(word):
    return len(word) == 13

lines       = (line for line in open("/usr/share/dict/words"))
words       = (line.strip() for line in lines)
valid_words = (word for word in words if isValid(word))
word_pairs  = ((random.random(), word) for word in valid_words)
rand_pairs  = heapq.nlargest(4, word_pairs)

rand_words  = [word for rand, word in rand_pairs]
print rand_words
```

The `words` generator calls `strip()` on each `line` which removes the newline character. The `valid_words` generator only returns words that pass the `isValid` test. In this case, `isValid` returns `True` only if the word is exactly 13 characters long. The end result is 4 random words that are 13 characters long.

One other advantage is that each generator creates its output only when requested. This translates into minimal memory use. The dictionary file being consumed might be gigabytes in size, but only one word will be loaded into memory at a time (excluding buffering done by the `file` class, etc). It's definitely a neat way of parsing large files.
 
If you enjoyed this, definitely check out [Beazley's presentation](http://www.dabeaz.com/generators/), and venture further down the rabbit hole.

##Notes##
1. You could even use the built-in function `max()` if you only need one word.
