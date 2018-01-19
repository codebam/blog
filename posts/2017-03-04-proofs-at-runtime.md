---
title: Proofs at Runtime
date: 2017-03-04
author: Alex Beal
type: post
permalink: proofs-at-runtime
---

One misconception I used to have about dependent types: In order to prove anything useful about a value, that value must be known at compile time. If this were true, it would really limit the usefulness of dependently typed languages. For example, in order to make e ∈ L a statically guaranteed precondition of removing e from the list L, I would have to know e and the contents of L when writing the program.

Fortunately, this isn’t true. Instead I can define a function that removes e from L, and make a proof that e ∈ L an argument to this function. This effectively asserts that the caller must have a proof of e ∈ L in order to call the function at all.

I can then write a function that constructs this proof at runtime for an arbitrary list. It will of course only construct the proof if it’s actually true. Further, I can use the `Dec` type to enforce decidability, meaning that this function will always return either a proof that e ∈ L or e ∉ L.

I now have all the machinery I need to safely remove elements from vectors that I know nothing about. The compiler won’t let me write a program that removes e from L unless I can, at runtime, successfully construct a proof that e ∈ L. Further, the type checker ensures that I cannot write a function that constructs a proof of something that is not true.[^1]

[^1]: Chapter 9 of ‘Type-Driven Development with Idris’ by Edwin Brady explains the mechanics of all this in detail.