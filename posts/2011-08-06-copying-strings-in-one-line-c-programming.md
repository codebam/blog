---
title: Copying Strings in One Line (C Programming)
author: Alex Beal
date: 08-06-2011
type: post
permalink: Copying-Strings-in-One-Line--C-Programming-
---

Here's a quickie for your Saturday afternoon:

    strcpy(s, t)    /* copy t to s; pointer version 3 */
    char *s, *t;
    {
        while(*s++ = *t++)
            ;
    }

That's a classic one from the [K&R text](http://en.wikipedia.org/wiki/The_c_programming_language) (page 101). You can tell how old it is by the style of the function declaration. There's no return type (so it defaults to `int`, even though nothing is actually returned), and the types of the arguments are declared on a separate line. Although it's far from obvious, what the function does is copy the string `t` to the string `s`.
 
Anyway, as you can see, order of operations is key. Dereferencing precedes assignment, assignment precedes evaluation, and evaluation precedes increment. Here's what happens:

1. The current position of `s` and `t` are dereferenced, and the character at that position is fetched.
2. That character is copied from `t` to `s`
3. The character just copied gets evaluated. The loop terminates if it's the null character, '\0'.
4. The pointers are incremented to the next character in the string.
5. The loop repeats, copying the consecutive characters, including the null character.

It's definitely a cool academic exercise, but it's so obfuscated, that even the order of operations table in the K&R book is of no help. It lists `++` and `*` as having the same precedence. To see what's going on here, we need to go to the C99 spec:

>The result of the postfix `++` operator is the value of the operand. After the result is obtained, the value of the operand is incremented. (page 75)

It's definitely a bit of black magic. Use this code wisely.
