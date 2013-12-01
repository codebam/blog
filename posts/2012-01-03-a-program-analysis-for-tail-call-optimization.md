---
title: A Program Analysis For Tail Call Optimization
author: Alex Beal
date: 01-03-2012
type: post
permalink: A-Program-Analysis-For-Tail-Call-Optimization
---

In this post I will outline a method [Josh Wepman](http://jwepman.com) and I have developed for detecting tail calls in programs constructed from a subset of Python. Its original purpose was a Python to x86 compiler we worked on together for a compiler construction course at CU.<sup>1</sup> The approach probably isn't new, but it is straightforward and understandable, and might help other novice compiler writers understand a fundamental optimization.

##1. What is a tail call?##
A tail call occurs when a function (the caller) calls another function (the callee) and then immediately returns the callee's value. Here is a simple example where `f()` is the caller, and `g()` is the callee:

``` python
    # Example 1.1

	def f():
		return g()
```

So, a function call is in *tail call position* when its return value is immediately returned. In the above example, it is `g()` that is in tail call position. Contrast this with the following example, where `g()` is not in tail call position:

``` python
    # Example 1.2

	def f():
		return g() * 2
```

Here, `g()` falls within the return statement of `f()`, but is not in tail call position because `g()`'s return value is used in the multiplication before it is returned by `f()`.<sup>2</sup>
 
Also consider the following example where `g()` is not in tail call position, but could easily be transformed into a program that is:

``` python
    # Example 1.3

	def f():
		x = g()
		y = x
		return y
```

Since the only thing that happens to `g()`'s value is that it is copied and then returned, the assignments could be removed, and `g()`'s value could be immediately returned without modifying the semantics of the program. Also notice that `x` and `y` are local variables, so it's guaranteed that their values are not used elsewhere in the program, and so they can be safely removed. The semantically equivalent tail calling program would look like the original example (1.1):

``` python
    # Example 1.1

	def f():
		return g()
```

##2. Why bother detecting them?##
Why are tail calls interesting? I want this post to be mainly about the analysis, so I won't delve too deeply into the mechanics of the machine code, but essentially tail calls allow for a compiler optimization where the callee can hand its return value straight to the caller of the caller. This will make more sense when you consider this extended version of example 1.1:

``` python
    # Example 2.1

	def g():
		return 1
		
	def f():
		return g()
		
	print f()
```

Here, `g()` will return 1 to `f()` and `f()` will return 1 to `print`, but, since all `f()` does is immediately return `g()`'s value to `print`, why not skip that step entirely? That is, why not simply have `g()` give its return value directly to `print`? That's how tail call optimization works. In the optimized version, `g()` returns its value directly to `print` rather than forcing `f()` to be the middleman. This is implemented on the machine code level by having the call to `g()` reuse `f()`'s stack frame. The result is that when `g()` returns, it hands its value directly to `print`.<sup>3</sup> The advantage is that since each call doesn't result in the allocation of a new stack frame, the compiled code will be slightly faster, and the recursion depth will be practically unlimited (or at least not limited by the size of the call stack).
 
Notice, though, that the actual optimization occurs at the machine code level, in the instruction selection phase of the compiler, which isn't the subject of this post. Instead, the subject is detecting when this optimization can be performed, and, additionally, transforming programs into ones that are eligible for this optimization. More on that in the next section.

##3. Goals of the Analysis##
One of the design goals of the analysis is for it to detect both of the situations outlined in section 1. That is, it should:

1. Detect obvious cases of tail calls, where a function call is directly nested within a `return` statement and
2. Detect less obvious cases where a program isn't tail calling, but could be transformed into one that is.

To elaborate on the second goal, *we want to detect instances where a return value is assigned to a variable, copied through a series of assignments, and then immediately returned without any intervening code.* This situation occurs in example 1.3, and is the reason it could be transformed into a tail calling program. Here is another example:

``` python
    # Example 3.1

	def f():
		if input():
			x = g()
		else:
			x = 1
		return x
```

If `input()` evaluates to true, then the value of `g()` gets assigned to `x`, and is immediately returned. Transforming this into a semantically equivalent tail calling program is as simple as pushing the `return` statement up into the `if` branch:

``` python
    # Example 3.2
	def f():
		if input():
			return g()
		else:
			x = 1
		return x
```

Now `g()` is in tail call position, but the semantics of the program haven't changed.
 
Contrast that with this example that can't be optimized (at least not by this analysis):

``` python
    # Example 3.3

	def f():
		x = g()
		print "About to return"
		return x
```

This example doesn't meet the last requirement that the copied return value is "immediately returned without any intervening code." Since our transformation pushes the `return` statement up to the function call to `g()`, we get the following program:

``` python
    # Example 3.4

	def f():
		return g()
		print "About to return"
```
	
Now the `print` statement is never reached. A more nuanced analysis might handle a case like this, but ours won't.

##4. Complications: The naive analysis, dispatch code, and flattening.##
Now that we understand the parameters of the analysis--what we will detect, and what we won't--how do we implement it? The first requirement is to detect obvious cases where function calls are nested within `return` statements. This seems simple. Just traverse the AST<sup>4</sup> and look for that precise situation: where function calls are nested within `return` statements. The trouble with this technique, and the reason that I call it the "naive analysis," is that, through the course of compilation, every function call gets turned into a set of nested `if` statements. Returning to example 1.1:

``` python
    # Example 1.1

	def f():
		return g()
```

This might get transformed into something like:

``` python
    # Example 4.1
	def f():
		if ...:
			tmp0 = g()
		else:
			if ...:
				tmp1 = h()
			else:
				tmp1 = throw_error()
			tmp0 = tmp1
		return tmp0
```

Why the additional complexity? Remember that Python is a dynamic language. One consequence of this is that at compile time, the compiler doesn't know the type of each variable. Is `g` an `int`? A `float`? A class? In many cases, the program needs this information. In the example above, `g()` will compile to different code if `g` is the name of a class, versus if `g` is the name of a function. Because this can't always be detected at compile time, the executable must be able to detect the types of variables, and be ready for every case.<sup>5</sup> Returning to the example, the first `if` might be testing if `g` is the name of a class. If it is, instead of calling a function named `g`, it needs to execute `g`'s `__init__()` method. If `g` isn't a class, then it needs to make sure `g` is a function. If it isn't, then the program needs to throw a runtime error. This is one reason why dynamic languages can be slow.
 
In any case, what matters to us is how this affects our analysis, but thankfully it doesn't. Although our compiler has effectively eliminated instances of "obvious" tail calls, the example above is still eligible for transformation into a program that contains tail calls. Since the return values of the function calls are assigned to temporary variables, then returned, the transformation is the same as in the simpler examples: push the `return` statement up to the function calls:

``` python
    # Example 4.2

	def f():
		if ...:
			return g()
		else:
			if ...:
				return h()
			else:
				return throw_error()
			tmp0 = tmp1
		return tmp0
```

The `return` statements have now been pushed up into the branches of the `if` statement, and `g()`, `h()`, and `throw_error()` are now in tail call position. Nice. Notice that this transformation leaves behind *dead code*. The assignment `tmp0 = tmp1` and `return tmp0` are considered "dead" because they will never be reached. Many compilers have a separate phase that removes the dead code that gets created from optimizations like this, but that's beyond the scope of this article.<sup>6</sup>
 
Aside from the addition of dispatch code, there's another important transformation to the code before it reaches the analysis phase. Happily, this transformation actually make detecting tail calls easier. This transformation is called *flattening*, which means that deeply nested expressions get broken down into simpler statements. Consider this:

``` python
    # Example 4.3
	x = input() + 1 + g()
```

That would get flattened into:

``` python
    # Example 4.4
	tmp0 = input()
	tmp1 = tmp0 + 1
	tmp2 = g()
	tmp3 = tmp1 + tmp2
	x = tmp3
```

Notice that the semantics of the program haven't changed, but the nested expression `input() + 1 + g()` gets broken down, or flattened, into a simple series of assignments.<sup>7</sup> Although this appears to add additional complexity, it actually reduces the number of possible cases our analysis will encounter, and shrinks the depth of the AST. Notice that the examples above have already been flattened.
 
So now that we have a fuller description of what we're up against, what does the not-so-naive analysis look like?

##5. The Not-So-Naive Analysis##
The not-so-naive analysis is a *flow sensitive static analysis*. The analysis follows the control flow of the program and, at each program point, records information about the contents of the variables based on certain rules. A *program point* is roughly every place in a program where the state of the program could change. In a flattened program, this roughly corresponds to the point before and after every line or statement of code. In the example below, each program point is numbered. The numbers correspond to the order in which each program point will be visited:

``` python
    # Example 5.1
	{0}
	tmp0 = input()
	{1}
	if tmp0:
		{2}
		tmp1 = f()
		{3}
	else:
		{4}
		tmp1 = g()
		{5}
	{6}
	return tmp1
```

So, there is a program point before and after each assignment, and a program point before and after the entire `if` statement. The order in which the two branches of the `if` statement are visited doesn't matter, but both branches should be visited before leaving the `if` statement.
 
Stepping through the program in this order is easy. Each line of code is an item in a list. Traverse the list in order. If you get to an `if` statement, do a postorder traversal. First visit the `if` branch and then the `else`. Once the value of these branches is determined, the value after the entire `if` statement can be determined. In other words, in order to determine the value at program point 6, the values at 3 and 5 must be evaluated first.
 
What do I mean by "the value at program point 6?" As hinted at above, each program point is associated with a set of variables. Roughly, this set corresponds to the set of variables that contain return values. The specifics of how variables get added and removed from the set is the subject of a set of rules. Formally, each rule is a function that takes in the set at a program point (usually the one above the current statement) and the statement itself, and outputs a new set that corresponds to the program point after that statement. So, for example, the value at program point 5 is determined by looking at program point 4 and the statement on line 10 (`tmp1 = g()`). Because that statement stores a return value to `tmp1`, `tmp1` gets added to the set at point 5. This is one of the rules. Below are the rules in full. As a shorthand, the program point before a statement is called R<sub>before</sub> and the point after is called R<sub>after</sub>.

1. If the statement is an assignment between variable `v` and a function call (`v = g()`), then *R<sub>after</sub> = {v}*.
2. If the statement is an assignment from variable `t` to variable `v` (`v = t`), and `t` is in R<sub>before</sub>, then *R<sub>after</sub> = {v}*.
3. At the start of a program, the beginning of a new code block (e.g. the beginning of a branch in an `if` statement), or the beginning and end of a new scope *R<sub>before</sub> = {}*.
4. If the statement is an `if` statement, then *R<sub>after</sub> = R<sub>after-if</sub> ∪ R<sub>after-else</sub>*. In other words, it is the union of the R<sub>after</sub>s of each branch.
5. If the statement is a `return` statement, and variable `v` is being returned (`return v`), and `v` is in R<sub>before</sub>, then the `return` statement can be pushed up to wherever `v`'s value was originally created. In other words, there's some function call above that can be put into tail call position (the function that created the value held by `v`).
6. In all other cases, *R<sub>after</sub> = {}*.
 
Some of these rules are intuitive. Some aren't. I'll go through them one by one and explain them. Keep in mind the goal of the analysis: we're trying to detect when return values are copied through a series of assignments and then returned without any intervening code. 
 
This makes the first rule the most intuitive. If a variable gets assigned a return value, add that variable to the set. This would be the first step in detecting something like example 1.3, reproduced below with the sets at each program point. Notice rule 1 in action on lines 4 and 5:

``` python
# Example 1.3/5.2

{}
def f():
	{}
	x = g()
	{x}
	y = x
	{y}
	return y
```

The second rule keeps track of return values that get copied between variables, and is the reason the set contains `y` after the 6<sup>th</sup> line. The value of `x` gets copied to `y`, and `x` happens to be in R<sub>before</sub>, so, by rule 2, `y` is now in R<sub>after</sub>.
 
The third rules initializes the analysis, and starts the program with an empty set. This rule should also be applied to new code blocks. The two branches of an `if` statement should begin with empty sets as shown below in a new example:

``` python
# Example 5.3

{}
y = g()
{y}
if input():
	{}
	y = f()
	{y}
else:
	{}
	y = h()
	{y}
	print "Called h()"
	{}
{y}
return y
```

Although `y` is in the set before the `if` statement, both branches of the `if` statement begin with an empty set. 
 
Example 5.3 also demonstrates rule four. The set after an `if` statement contains the union of the two branches, in this case just `y`.
 
The fifth rule comes into play on line 15. `y` is returned, and it also happens to be in R<sub>before</sub>. This means that the function call that gave `y` its value can be put in tail call position. This is done by pushing the `return` statement up to the call to `f()` on line 6:

``` python
# Example 5.4
{}
x = g()
{x}
if input():
	{}
	return f() # Optimized to tail call position.
	{y}
else:
	{}
	y = h()
	{y}
	print "Called h()"
	{}
{y}
return y
```

The program has now been transformed into a tail calling program. The analysis has detected that a return value was assigned to a variable, and then returned without any intervening code. Notice, though, that the call to `h()` on line 10 wasn't optimized. It was almost eligible for transformation, but the intervening `print` statement on line 12 trigged the last rule, and, correctly, prevented the `return` statement from being pushed up to the call  to `h()`. This is the purpose of the last rule--to prevent intervening code from becoming dead code.

There is one last bit of housekeeping. In order for rule 5 to be executed, it needs to know where a variable's value was originally created. Consider, once again, example 1.3:

``` python
# Example 1.3/5.2

{}
def f():
	{}
	x = g()
	{x}
	y = x
	{y}
	return y
```

The analysis will detect that `y` is being returned, and recognize that `y` is in R<sub>before</sub>. This will trigger rule 5, and the analysis will need to know where `y`'s value was originally created. How will it determine this? The algorithm is simple:

1. When `g()` is first assigned to `x` and `x` gets added to R<sub>after</sub>, the analysis will record that `x` is associated with that line (or AST node).
2. When `x` gets copied to `y`, the analysis looks up whichever node/line `x` was associated with, and then records that `y` is associated with that same node/line.
3. When the analysis gets to the last line, it knows that `y` is associated with line 4 (`x = g()`), and knows that it can push the `return` statement up to that position.

We are left with the optimized version:

``` python
    # Example 5.5

    def f():
		return g()
		# Dead code
		y = x
		return y
```

##6. Conclusion##
Congratulations if you've gotten this far. We've covered a lot of ground. I've touched on several parts of the compiler, and described, in detail, a program analysis for detecting tail calls. Notice, though, that this analysis only covers a very small subset of Python. The rules assume that all `if` statements also have an `else` branch. How could this be fixed? I also haven't addressed other control flow structures. Adding a rule for `while` loops would be an important addition. All of these issues would be good exercises to think about, and will, perhaps be the subjects of followup posts.

##Footnotes###
1. I'm currently in the early stages of forking the project, which I've redubbed [bullfrog](http://github.com/beala/bullfrog).
2. [http://en.wikipedia.org/wiki/Tail_call#Syntactic_form](http://en.wikipedia.org/wiki/Tail_call#Syntactic_form)
3. [http://en.wikipedia.org/wiki/Tail_call#In_assembler](http://en.wikipedia.org/wiki/Tail_call#In_assembler)
4. AST: Abstract Syntax Tree. A tree representation of the structure (syntax) of a program. [Wiki](http://en.wikipedia.org/wiki/Abstract_syntax_tree).
5. This is one reason dynamic languages can be slow, but most compilers perform additional optimizations to cut down on so called "dispatch code" by detecting variables types at compile time. This is possible when, for example, an integer is explicitly assigned to a variable: `x = 1`. In that case, it's guaranteed that `x` contains an integer.
6. Dead code elimination. (2011, October 20). In Wikipedia, The Free Encyclopedia. Retrieved 16:56, December 24, 2011, from [http://en.wikipedia.org/w/index.php?title=Dead_code_elimination&oldid=456578651](http://en.wikipedia.org/w/index.php?title=Dead_code_elimination&oldid=456578651)
7. At first blush, this doesn't look nested, but it is: `x = (((input()) + 1) + g())`. The infix notation is deceptive, but, as demonstrated by the parenthesized version, there are actually 2 levels of addition that roughly correspond to the structure of the flattened code.
