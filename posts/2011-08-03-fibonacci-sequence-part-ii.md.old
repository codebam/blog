---
title: Fibonacci Sequence, Part II
author: Alex Beal
date: 08-03-2011
type: post
permalink: Fibonacci-Sequence--Part-II
---

The matrix equation in the last post can actually be whittled down a bit further to produce another equation that, in some ways, is easier to work with. The result is as follows:

![fib](http://media.usrsb.in/fib2/fib.png)

F<sub>k</sub> is, of course, the k<sup>th</sup> Fibonacci number. Now, before I go on, I want to point out that I stumbled upon these two equations and the proofs for these equations in [Gilbert Strang's](http://www-math.mit.edu/~gs/) excellent [Linear Algebra and Its Applications](http://www.amazon.com/Linear-Algebra-Applications-Gilbert-Strang/dp/0030105676/ref=sr_1_2?s=books&ie=UTF8&qid=1312385275&sr=1-2). All credit goes to him for coming up with this, and I recommend his book for an even more in depth explanation.
 
Anyway, back to the equation, which I found interesting for a few reasons:

1. This equation allows you to easily find the kth term using only a pocket calculator. The last equation requires something that can deal with matrices.
2. This also makes it easier to use in programming applications. There's no need to write functions or import libraries to deal with matrices. It's also probably faster than writing some sort of recursive function to compute the kth Fibonacci number.
3. As Strang points out, that equation, amazingly, produces an integer, despite all the fractions and square roots.
4. We can simplify that equation further for a very good approximation (so good that it's not really an approximation).

To see how we get that equation from the equation in the last post, let's begin with the way Mr. Strang has it written in his book (it's the same as mine, but flipped upside down).
 
![title](http://media.usrsb.in/fib2/fibmat.png)
 
Where F<sub>0</sub>=0, F<sub>1</sub>=1, F<sub>2</sub>=1, etc. Let's now make some substitutions:
 
![title](http://media.usrsb.in/fib2/subs.png)
 
We now have:
 
![title](http://media.usrsb.in/fib2/matform.png)
 
This hasn't changed the content of the equation at all. We've just substituted in new symbols to represent the different terms.
 
The next step is to diagonalize the matrix A. Remember that diagonalizing A produces A = SΛS<sup>-1</sup> where S contains A's eigenvectors and Λ contains A's eigenvalues. Substituting A = SΛS<sup>-1</sup> into the previous equation yields:
 
![title](http://media.usrsb.in/fib2/diag.png)
 
Notice how everything but the first and last S and S<sup>-1</sup> cancel, giving the final form: SΛ<sup>k</sup>S<sup>-1</sup>u<sub>0</sub>. This is important, because Λ is a diagonal matrix, making Λ<sup>k</sup> very simple:
 
![title](http://media.usrsb.in/fib2/lampow.png)
 
λ<sub>1</sub> and λ<sub>2</sub> are, of course, the eigenvalues of A. Let's now make one last substitution and put all this diagonalization stuff together. First we define c as
 
![title](http://media.usrsb.in/fib2/csub.png)
 
Then we substitute it into the equation:
 
![title](http://media.usrsb.in/fib2/diag2.png)
 
That might need some explaining. The first bit is simply the equation with c substituted in. Following that, the first matrix is S, but written to show that it contains x<sub>1</sub> and x<sub>2</sub>, which are the eigenvectors of A placed vertically in the two columns. The middle matrix is Λ<sup>k</sup> and the last is simply the matrix c. Finally, the matrices are multiplied out, yielding the final c<sub>1</sub>λ<sup>k</sup><sub>1</sub>x<sub>1</sub>+c<sub>2</sub>λ<sup>k</sup><sub>2</sub>x<sub>2</sub>
 
The final steps are simply to compute c, and A's eigenvalues and eigenvectors. I'll spare you the tedious algebra and simply tell you that:
 
![title](http://media.usrsb.in/fib2/eigenvals.png)
 
![title](http://media.usrsb.in/fib2/eigenvec.png)
 
This can be computed the standard way, by solving: det(A-λI)=0.
 
All the variables are then plugged into the equation for u<sub>k</sub>.
 
![title](http://media.usrsb.in/fib2/almost-there.png)
 
We want F<sub>k</sub>, so we multiply, factor, and take the bottom row, giving the equation we want:
 
![title](http://media.usrsb.in/fib2/approx.png)
 
That's the full equation, but now notice that the second term is always less than 1/2. This mean we can simply drop it, yielding:

In fact, since the second term is always less than 1/2 and the full equation always gives us an integer, we can take this a step further: **Rounding the approximation to the nearest integer will always give you the exact value for F<sub>k</sub>.** Cool.
