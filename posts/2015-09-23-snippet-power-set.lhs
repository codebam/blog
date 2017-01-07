---
title: "Snippet: Power Set"
author: Alex Beal
date: 2015-09-23
type: post
permalink: snippet-power-set
---

*Below is an explanation of the intuition behind Olaf Klinke's [power set function](https://mail.haskell.org/pipermail/haskell-cafe/2015-September/121402.html) posted to the haskell-cafe. See his [explanation here](https://mail.haskell.org/pipermail/haskell-cafe/2015-September/121422.html).*

One way of viewing the monad instance for list is as a container. We can gather elements into the container and apply functions to these elements that themselves produce containers of elements.

Another interpretation is to view the list monad as a way of encoding ambiguity or nondeterminism. A function of type `a -> b` must produce a single `b` for each `a`. A function of type `a -> m b` can produce a `b` lifted into an effect `m`. If that effect is ambiguity, then the function can produce multiple `b`s for each `a`--it doesn't need to choose. The result is a sort of superposition.

> type Amb a = [a]
> -- An ambiguous Boolean that is both True and False.
> ambiguousBool :: Amb Bool
> ambiguousBool = [True, False]

Like all monadic effects, if a computation depends on ambiguity, it too becomes ambiguous. `filterM`, for example, allows filtering to happen ambiguously, where the result is an ambiguous list. If `ambiguousBool` is used to filter elements, the result is an ambiguous list where each elements has been both removed and kept, in other words, the power set.^[Assuming the input list forms a set.]

> import Control.Monad
> -- filterM :: Monad m => [a] -> (a -> m Bool) -> m [a]
> filterM (\_ -> ambiguousBool) [1,2,3] :: Amb [a]
> -- Result: [[1,2,3],[1,2],[1,3],[1],[2,3],[2],[3],[]]
>
> powerSet :: [a] -> [[a]]
> powerSet = filterM (\_ -> ambiguousBool)
