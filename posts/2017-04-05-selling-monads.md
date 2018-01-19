---
title: Selling Monads
date: 2017-04-05
author: Alex Beal
permalink: sellings-monads
---

Below is a comment I posted to Hacker News. It answers the questions of “why monads?” in a way that I hope is persuasive to those who are not already persuaded.

> Monad, like any interface, is useful because we can abstract over it. Let’s take an example from Java: both `ArrayList` and `LinkedList` implement `List`. This means I can write code that is agnostic to the implementation of `List`, and later I can drop in any implementation I want. Seen from the other direction: if I write something that resembles a list and I implement the `List` interface, all of the code that’s compatible with `List` will also be compatible with my new implementation.
>
> Similarly, if I define a new data type, and realize that it can implement `Monad`, then I’ll be rewarded with a wealth of functions that are already compatible with my new data type [1]. `Monad` is an especially interesting interface because (1) it turns out many things conform to it [2] and (2) it comes with a set of algebraic laws. There is some controversy over how strict we need to be about the algebraic laws, but in some sense the algebraic laws are part of why such a general interface can be meaningful at all. So yes, it’s true that `Monad` allows us to sequence effects in a lazy pure language, and that’s important, but I think a more down to earth reason to be interested is that it allows for more code reuse [3].
>
> [1] Some of the functions defined in the standard library: [https://hackage.haskell.org/package/base-4.9.1.0/docs/Control-Monad.html#g:4](https://hackage.haskell.org/package/base-4.9.1.0/docs/Control-Monad.html#g:4)
>
> [2] See the ‘instances’ section here: [https://hackage.haskell.org/package/base-4.9.1.0/docs/Control-Monad.html#t:Monad](https://hackage.haskell.org/package/base-4.9.1.0/docs/Control-Monad.html#t:Monad). These are just the instances in the standard library. Other packages provide more.
>
> [3] It’s also worth mentioning that Monad gets all the attention, but Haskell if flush with other mathematically inspired interfaces that are just as general.

I think the explanation does a few things right:

* It doesn’t refer to specific Monad instances, which require time to explain well.
* It avoids jargon that only those already drinking the Kool-Aid understand.
* It appeals to something most programmers already think is a good thing: code reuse.
* It doesn’t appeal to things only Haskellers care about: sequencing effects in a pure lazy language.

Unfortunately, I think many of the ideas coming out of the typed FP community aren’t pitched in a way that does them justice because one or all of the rules above are violated. The benefits of these ideas are often straightforward, but we still fail to be persuasive.

Returning to the third point, I think the code reuse justification is greatly undersold, and it’s been undersold to such an extent that many languages that adopt abstractions like Monad often don’t do it in a way that allows for code reuse. Scala is an example of this, where many classes have a `flatMap` method, but this method is not implemented as part of any interface. This loses an important benefit of general interfaces like `Monad` and only leads to further confusion:

“Why are these different functions all named `flatMap`? Isn’t this just mathematical wankery at the expense of clarity?”

“Well gather ’round friends and I’ll tell you the story of Haskell.”