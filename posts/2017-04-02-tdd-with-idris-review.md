---
title: "Review: Type-Driven Development with Idris"
date: 2017-04-02
author: Alex Beal
permalink: tdd-with-idris-review
---

*Type-Driven Development with Idris* has been [released](https://www.manning.com/books/type-driven-development-with-idris). I’ve been watching its development through Manning’s early access program, and it’s shaped up to be one of my favorite books on programming in recent memory. What makes this book special is that rather than being just an Idris tutorial, it instead uses Idris as a medium for demonstrating what programming could look like if developers were willing to embrace powerful type systems. In this way, it’s similar to *Functional Programming in Scala* (another favorite of mine), where Scala is used as a medium for introducing a certain style of functional programming. Yes, you’ll learn Scala if you read it, but that’s perhaps not the point. Similarly, *TDD with Idris* will certainly teach you Idris, but the biggest insight for me was not learning the language itself, but instead seeing how leveraging dependent types can improve the development process. Best of all, Edwin Brady demonstrates this in a no nonsense way, explaining concepts clearly with realistic examples, and skipping the academic jargon.

So what are dependent types? I’ll let the book speak for itself[^1]:

> In Idris, types are a first-class language construct. Types can be manipulated, used, passed as arguments to functions and returned from functions just like any other value such as numbers, strings, or lists. This is a simple but powerful idea, which allows:
>
> * relationships to be expressed between values, for example that two lists have the same length
> * assumptions to be made explicit and checkable by the compiler, for example if we assume that a list is non-empty then Idris can ensure this assumption always holds before the program is run
> * if desired, program behaviour to be formally stated and proven correct

If you’re already familiar with Haskell, what you’ll find is a language that lets you breathe. What do I mean by that? Idris will let you express the same concepts (and more) at the type level without the acrobatics. Conor McBride said it best in his article *Epigram: Practical Programming with Dependent Types*. After a convoluted Haskell example, McBride writes[^2]:

> Programming with these ‘fake’ dependent types is an entertaining challenge, but let’s be clear: these techniques are cleverly dreadful, rather than dreadfully clever. Hideously complex dependent types certainly exist, but they express basic properties like size in a straightforward way—why should the length of a list be anything less ordinary than a number?

In other words, concepts that require contortions to express in Haskell melt away when types become first class. It’s much easier to express the length of a list at the type level, if types are allowed to contain natural numbers.

So who should read this book? Anyone with an interest in typed functional programming, but some experience with a language like Haskell is recommended. Despite Brady’s best efforts, I think those without some background in Haskell, ML, or Scala (using libraries like Cats or Scalaz) will find this book challenging. On the other hand, experienced Haskellers will find this book to be a breath of fresh air. It has certainly gotten me excited about the future of programming.

[^1]: Type-Driven Development with Idris by Edwin Brady. MEAP v12. p 2.
[^2]: Type-Driven Development with Idris by Conor McBride. p 3. http://cs.ru.nl/~freek/courses/tt-2010/tvftl/epigram-notes.pdf