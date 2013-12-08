---
title: Language Idiosyncrasies and Thin Interfaces
author: Alex Beal
date: 12-04-2013
type: post
permalink: language-idiosyncrasies-and-thin-interfaces
---

>The student’s attention is almost entirely absorbed by becoming fully familiar with the ideosyncrasies of the various languages and is made to believe that the more of these ideosyncrasies he understands, the better a programmer he will be.^[[http://www.cs.utexas.edu/users/EWD/transcriptions/EWD04xx/EWD473.html](http://www.cs.utexas.edu/users/EWD/transcriptions/EWD04xx/EWD473.html)]

I see this especially in languages like JavaScript, where developers are praised for knowing about some weird corner of ECMA's incredibly convoluted spec.

The article also talks about the advantages of modularized code and thin interfaces. It's worth pointing out that pure languages like Haskell really encourage this style. A pure function's interface is merely its parameters, and lack of an implicit state means the function is modularized from the rest of the world.
