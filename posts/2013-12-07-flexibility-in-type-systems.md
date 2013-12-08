---
title: Flexibility In Type Systems
author: Alex Beal
date: 12-07-2013
type: post
permalink: flexibility-in-type-systems
---

> So this is sort of a key question about the role of types versus logic where I think flexibility is more important than opinion. There’s a tension between whether types should be suits of armor that make all the guarantees that we might need to get through life, or if they’re just like clean underpants—something that makes us decent and comfortable as we go about our business […] I think the point though is that we want enough language to explain what we know and what we don’t know.^[Conor McBride at “Sexy Types - Are We Done Yet?” [https://research.microsoft.com/apps/video/dl.aspx?id=150045](https://research.microsoft.com/apps/video/dl.aspx?id=150045) 1:16:00]

This is a comment made by Conor McBride at a panel on types, and it’s a point that resonated with me, namely that “flexibility is more important than opinion.” Although I appreciate types there are times where I’m happy to admit that a suit of armor isn’t necessary.^[See the Quark browser’s judicious application of verification to only the core of the browser. [http://goto.ucsd.edu/quark/](http://goto.ucsd.edu/quark/)] The issue is, this is sometimes mistaken as an argument for a crippled type system (or no type system at all). Instead, I think this is an argument for a flexible system that can accommodate both. Languages with no type system, like Python, will allow me to duck type and program in a freer more dangerous style, but if I at some point decide that I need types, I’m out of luck. This is not true of more flexible type systems like Haskell’s, where I can turn up the types knob when I need the compiler’s help, or turn it down when I don’t.^[See this implementation of duck typing in Haskell: [http://hackage.haskell.org/package/dynamic-object](http://hackage.haskell.org/package/dynamic-object)] The point is, a flexible system allows the language designer to punt on the question of whether a certain type feature is necessary, and instead let the developer decide, whereas in a language like Python, that decision is made for me.
