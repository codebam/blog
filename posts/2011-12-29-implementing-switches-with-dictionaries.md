---
title: Implementing Switches With Dictionaries (Python)
author: Alex Beal
date: 12-29-2011
type: post
permalink: Implementing-Switches-With-Dictionaries--Python-
---

One thing I like about Python is that it lets you do just about anything. Classes can be modified at runtime, lists can contain a mix of types, and functions are first-class. The built in dictionaries are especially powerful. They are fast, and can hash and contain just about any immutable datatype, including functions. This allows for a novel use: fast `switch` statements. Consider the following bit of C, which adds, subtracts, or multiplies two numbers based on the value of `op`:

``` c
/* A C Calculator */
switch(op) {
	case '+':
		c = a + b;
		break;
	case '-':
		c = a - b;
		break;
	default:
		c = a * b;
		break;
}
```
	
This behavior could be duplicated in Python using an `if ... elif ... elif ...` sequence,<sup>1</sup> or we could use the following dictionary:

``` python
# A Python Calculator

def add():
	return a + b
def sub():
	return a - b
def mult():
	return a * b
	
switch_substitute = {
	'+' : add,
	'-' : sub }
	
c = switch_substitute.get(op, mult)()
```

There, the three operations are wrapped in functions, and added as values to the dictionary. The `get()` method looks for the function associated with the value of `op` and returns the `mult` function if the key is not in the dictionary, mimicking the action of the `default` case.<sup>2</sup> Once one of the functions is retrieved, it's immediately called, and the appropriate value gets assigned to `c`.
 
The advantage of this method is that it's fast. Dictionaries are implemented as hash tables, so the lookup happens in constant time.<sup>3</sup> `elif`s and `switch`es probably take linear time, but would depend on the implementation.
 
It's also worth thinking about how something similar could be built using a class and Python's [getattr](http://docs.python.org/library/functions.html#getattr) function.

##Footnotes:###
1. [http://docs.python.org/tutorial/controlflow.html#if-statements](http://docs.python.org/tutorial/controlflow.html#if-statements)
2. [http://docs.python.org/library/stdtypes.html#dict.get](http://docs.python.org/library/stdtypes.html#dict.get)
3. [http://docs.python.org/library/stdtypes.html#mapping-types-dict](http://docs.python.org/library/stdtypes.html#mapping-types-dict)
