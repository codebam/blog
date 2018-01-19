---
title: Expanding Regular Expressions with LogicT
date: 2017-04-08
author: Alex Beal
permalink: logic-regex
---

Below is code from a [previous post](regex-language.html) on expanding regular expressions. The way it handles non-terminating regular expressions is not optimal. Can you spot the issue? (Hint: the issue is not that it doesn’t terminate.)

``` haskell
-- The regex AST
data Regex = Lit Char           -- Character literals
           | Empty              -- The empty string
           | Concat Regex Regex -- Concatenation of two regexs
           | Alt Regex Regex    -- Choice between two regexs
           | Kleene Regex       -- The Kleene star

produceAll :: Regex -> [String]
produceAll (Lit s) = return [s]
produceAll Empty = return ""
produceAll (Concat r1 r2) = do
  a <- produceAll r1
  b <- produceAll r2
  return (a ++ b)
produceAll (Alt r1 r2) = produceAll r1 ++ produceAll r2
produceAll (Kleene r) = do
  let concats = (fmap (\i -> foldr Concat Empty (replicate i r)) [0..])
  let expandedKleene = foldr Alt Empty concats
  produceAll expandedKleene
```

The issue is that expansion happens in an undesirable way when concatenation and alternatives are combined with non-terminating expressions. Here are two examples to illustrate:

* Alternatives are explored from left to right. If I have the regex `a*|b`, the `a*` alternative is expanded until exhaustion. Because `a*` is never exhausted, `b` is never expanded.[^1]
* Concatenations are explored by expanding the left branch until the first success and then exhausting the right branch. If I have regex `(a|b)c*`, `(a|b)` is expanded until the first success yielding `a`, then `c*` is expanded until exhaustion. Because `c*` is never exhausted, `b` is never explored.[^2]

We can observe this behavior by running `a*|b` and `(a|b)c*` against the interpreter:

```
-- a*|b
> take 10 $ produceAll (Alt (Kleene (Lit 'a')) (Lit 'b'))
["","a","aa","aaa","aaaa","aaaaa","aaaaaa","aaaaaaa","aaaaaaaa","aaaaaaaaa"]

-- (a|b)c*
> take 10 $ produceAll (Concat (Alt (Lit 'a') (Lit 'b')) (Kleene (Lit 'c')) )
["a","ac","acc","accc","acccc","accccc","acccccc","accccccc","acccccccc","accccccccc"]
```

So `a*|b` only expands `a*` and `(a|b)c*` only expands `ac*`.

A better implementation would alternate expanding each branch no matter if one was non-terminating.

To understand where this undesirable behavior comes from, let’s examine the the Alt and Concat cases in the interpreter, starting with the `Alt` case:

``` haskell
produceAll (Alt r1 r2) = produceAll r1 ++ produceAll r2
```

It’s straightforward to see that if `produceAll r1` doesn’t terminate, `produceAll r2` is never evaluated.[^3]

Now the `Concat` case:

``` haskell
produceAll (Concat r1 r2) =
  a <- produceAll r1
  b <- produceAll r2
  return (a ++ b)
```

This is harder to see. Essentially what happens is that the first result of `produceAll r1` is concatenated to all the results of `produceAll r2`, but because `r2` is never exhausted, the interpreter never proceeds past the first expansion of `r1`. It might be helpful to think of this as two nested loops, where the inner loop is never exhausted.[^4]

What’s the solution? `LogicT` was designed to address precisely this issue. Kiselyov, Shan, and Friedman write:

> Most existing backtracking monad transformers, including the ones presented by Hinze, suffer from three deficiencies in practical use: unfairness, confounding negation with pruning, and a limited ability to collect and operate on the final answers of a non-deterministic computation. First, the straightforward depth-first search performed by most implementations of MonadPlus is not fair: a non-deterministic choice between two alternatives tries every solution from the first alternative before any solution from the second alternative. When the first alternative offers an infinite number of solutions, the second alternative is never tried, making the search incomplete. […] Our contribution in this regard is to implement fair disjunctions and conjunctions in monad transformers and using control operators and continuations.[^5]

`Alt` corresponds to the disjunction case: `Alt r1 r2` produces either `r1` or `r2`. This case is unfair in the interpreter because it inherits the unfair semantics of the `(++)` operator. `Concat` corresponds to the conjunction case: `Concat r1 r2` produces `r1` and `r2`, conjoined as a single result. This case is unfair in the interpreter because it inherits the unfair semantics of the `(>>=)` operator on `List`.

`LogicT` provides fair disjunction and conjunction as interleave and `>>-`. Comparing this to their unfair counterparts `(++)` and `(>>=)` we see that the types line up precisely:

``` haskell
interleave :: Logic a -> Logic a -> Logic a
(++)       :: [a]     -> [a]     -> [a]

(>>-) :: Logic a -> (a -> Logic b) -> Logic b
(>>=) :: [a]     -> (a -> [b])     -> [b]
```

The similar type signatures are no coincidence. Swapping the fair operators in for the unfair gives us the semantics we want:

``` haskell
produceAllFair :: Regex -> Logic String
produceAllFair (Alt r1 r2) = produceAllFair r1 `interleave` produceAllFair r2
produceAllFair (Concat r1 r2) =
  produceAllFair r1 >>- \a ->
  produceAllFair r2 >>- \b ->
  return (a ++ b)
produceAllFair (Lit s) = return [s]
produceAllFair Empty = return ""
produceAllFair (Kleene r) = do
  let concats = (fmap (\i -> foldr Concat Empty (replicate i r)) [0..])
  let expandedKleene = foldr Alt Empty concats
  produceAllFair expandedKleene
```

Running our previous test cases against the new fair interpreter, where `observeMany` now takes the place of take, the results look much better:

``` haskell
-- a*|b
> observeMany 10 $ produceAllFair (Alt (Kleene (Lit 'a')) (Lit 'b'))
["","b","a","aa","aaa","aaaa","aaaaa","aaaaaa","aaaaaaa","aaaaaaaa"]

-- (a|b)c*
> observeMany 10 $ produceAllFair (Concat (Alt (Lit 'a') (Lit 'b')) (Kleene (Lit 'c')))
["a","b","ac","bc","acc","bcc","accc","bccc","acccc","bcccc"]
```

In `a*|b`, the `b` branch is no longer completely ignored in favor of the `a*` branch.

In `(a|b)c*`, the `b` branch is no longer completely ignored in favor of the `a` and `c*` branches.

Are there any lessons to be learned from this exercise, other than to remember `LogicT` when faced with non-deterministic logic programming? One thing I think this example illustrates is Haskell’s powerful facilities for abstraction. With only a couple changes, I was able to transform the naive solution into something much more powerful. I know of no mainstream language with such consistently ingenious and principled libraries. On the other hand, these opportunities for abstraction require careful thought. Mixing non-termination and laziness, I was able to express the original regex expander succinctly, but was bitten by the lack of fairness in the underlying operators. Teasing these issues out required peeking below the abstractions to figure out what was going on.

[^1]: Algebraically: `a|b = a`, if `a` is non-terminating.
[^2]: Algebraically: `ac = αc` if `c` is non-terminating and where `α` is the first expansion of `a`.
[^3]: Algebraically: `a ++ b = a`, if `a` is non-terminating.
[^4]: Algebraically: `(return a ++ b >>= f) = (return a >>= f)` if `f` is non-terminating.
[^5]: Kiselyov, Oleg, Chung-Chieh Shan, Daniel P. Friedman, and Amr Sabry. “Backtracking, interleaving, and terminating monad transformers.” ACM SIGPLAN Notices 40.9 (2005): 192. Web. [http://okmij.org/ftp/papers/LogicT.pdf](http://okmij.org/ftp/papers/LogicT.pdf).