---
title: Regular Expressions Are A Declarative Language for Generating Strings
date: 2017-04-04
author: Alex Beal
permalink: regex-language
type: post
---

Regular expressions can be used to both match strings and generate strings. Most utilities do the former, but I’ve written one that does the latter. Below is an example:

```
> regexpand '(a|b)*'

a
b
aa
ab
ba
bb
aaa
aab
aba
abb
baa
bab
bba
bbb
```

I wrote this generator in order to help me write matchers, and in that respect it has already paid back the investment. After feeding one of my own regexs in, the utility made it obvious I forgot to escape a period. Errors like these are hard to catch with unit tests.

The kernel of the utility is very compact. Once the regex is parsed the AST is explored:

``` haskell
-- The regex AST
data Regex = Lit Char           -- Character literals
     	   | Empty              -- The empty string
	   | Concat Regex Regex -- Concatenation of two regexs
	   | Alt Regex Regex    -- Choice between two regexs
	   | Kleene Regex       -- The Kleene star
	   | Any                -- Any character

produceAll :: Regex -> [String]
produceAll (Lit s) = return [s]
produceAll Empty = return ""
produceAll Any = fmap return ['a'..'z']
produceAll (Concat r1 r2) = do
  a <- produceAll r1
  b <- produceAll r2
  return $ a ++ b
produceAll (Alt r1 r2) = produceAll r1 ++ produceAll r2
produceAll (Kleene r) = do
  let concats = (fmap (\i -> foldr Concat Empty (replicate i r)) [0..])
  let expandedKleene = foldr Alt Empty concats
  produceAll expandedKleene
```

Each case in the `produceAll` interpreter is straightforward:

* Lit: return the character literal as a string.
* Empty: return an empty string.
* Any: return the strings “a”, “b”, “c”, etc.
* Concat: produce the strings described by each subtree and append them together.
* Alt: produce the strings described by each subtree and return all of them.
* Kleene: produce the strings described by “`"" | r | rr | rrr | …`” where r is the subtree.

Through the magic of the List monad, all execution paths are explored even though the code is written as if only one execution path is explored (this is because the List monad allows each step of the interpreter to return multiple results). Through the magic of laziness, the Kleene case can be nonterminating, as long as we only ask for a finite prefix of the result.

```
> take 10 $ produceAll (Kleene (Lit 'a'))
["","a","aa","aaa","aaaa","aaaaa","aaaaaa","aaaaaaa","aaaaaaaa","aaaaaaaaa"]
```

We can get cute and even write a regex matcher using produceAll:

```
> elem "abba" (produceAll (Kleene (Alt (Lit 'a') (Lit 'b'))))
True
```

Of course, the function might not terminate if a match isn’t found.

You can the find the utility on my [Github](https://github.com/beala/regexpand).