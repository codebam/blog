---
title: Look, Ma! No Loops: Reversing Word Order
author: Alex Beal
date: 04-07-2012
type: post
permalink: Look--Ma--No-Loops--Reversing-Word-Order
---

Here's a classic interview question:

> Write a function that takes a string and reverses its word order. So, "Reverse this string" results in "string this Reverse".

Notice that the task isn't to reverse the string, but rather to reverse the order of the string's words. So the first word becomes the last. The second word becomes the second to last, and so on.

Whenever I come across puzzles like this, I shudder when I start to think about the nested loops and pointer arithmetic. Unfortunately, that describes the classic solution pretty well. The common wisdom is that first you should reverse the entire string. Then you should go back and reverse each word. So:

1. "Reverse this"
2. "siht esreveR"
3. "this Reverse"

The first step isn't bad, but reversing each word will require at least one nested loop, and some careful thinking about how to deal with the spaces. Instead, let's think through a functional solution that doesn't involve any loops. It will necessarily be recursive, so the first step will be to come up with each of the cases we'll encouter as we walk the string.

- Recursive Case 1: We're in the midst of a word. Add the current letter to the end of some word accumulator.
- Recursive Case 2: We're at the end of a word (a space). Add the current word accumulator to the beginning of some string accumulator, then clear the word accumulator.
- Base Case: The string is empty. Return the word accumulator prepended to the string accumulator.

So, there are two accumulators. One grabs the letters of each word as we walk the string and keeps the letters *in order* (the word accumulator). Then, once an entire word has been read into the word accumulator, it's prepended to the string accumulator. Prepending, reverses the word order. Once it's prepended, the word accumulator is cleared in preparation for the next word. Let's translate this case by case.

The base case is the easiest. Let's start there:

```python
if len(s) == 0:
    return word_acc + str_acc
```

Start by testing if the input string, `s`, is empty. If it is, then we've reached the end of the string, so we return the contents of the `word_acc`, prepended to the `str_acc`. `word_acc` contains the last word in the string, and we're prepending it to the rest of the string that has already been reversed.

Now let's deal with the second recursive case:

```python
elif s[0] == " ":
    return helper(s[1:], "", " " + word_acc + str_acc)
```

If we've gotten this far, the input string must have some length, so we check if the first character is a space. If it is, we've reached the end of a word, so we need to prepend `str_acc` with the word that's just been read in (`word_acc`). We then clear out the `word_acc` in preparation for the next word, and recursively call the function with the rest of the input string, `s`. The recursive call is to `helper` because this will be nested inside a convenience wrapper that only takes one argument.

Finally, the last case:

```python
else:
    return helper(s[1:], word_acc + s[0], str_acc)
```

If we've gotten this far, we're in the midst of a word (the string isn't empty, and the current character isn't a space). In this case, we add the current character onto the `word_acc` and then recurse with the rest of the string. Remember, the `word_acc` is building up each word character by character as we walk the input string.

Finally, we can simply throw these cases into a function, and it should just work. Ahh, the magic of recursion.


```python
def rev_words(s):
    '''Returns the string `s` with its words in the reverse order.
       Example: rev_words("Reverse this!") #"this! Reverse"
    '''
    def helper(s, word_acc, str_acc):
        # Base case: Return word accumulator plus whatever words
        # you have in the string acc
        if len(s) == 0:
            return word_acc + str_acc
        # This is the end of a word. Clear `word_acc`, and start with
        # the next word.
        elif s[0] == " ":
            return helper(s[1:], "", " " + word_acc + str_acc)
        # In the middle of a word. Add the letter to `word_acc`, and continue
        else:
            return helper(s[1:], word_acc + s[0], str_acc)
    return helper(s, "", "")
```

As much as I like this solution, it's not without its drawbacks. The most significant is that Python's string methods are very slow. Each concatenation causes both strings to be copied, and at least one concat is happening for each character in the string. Possible solutions include turning the string into a list of characters (list methods are much faster), or using a language that better supports the functional paradigm.<sup>1</sup> But really, if speed is your highest priority, the imperative solution of swapping characters in place is your best bet, warts and all.

If you'd like to play with this code yourself, I've posted [a gist here](https://gist.github.com/2331327), along with some tests.

###Notes###
1. If Python had a constant time prepend function ('cons' in the functional world), I suspect a better solution would be possible.
