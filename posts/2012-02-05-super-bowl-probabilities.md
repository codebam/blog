---
title: Super Bowl Probabilities: The Coin Toss
author: Alex Beal
date: 02-05-2012
type: post
permalink: Super-Bowl-Probabilities--The-Coin-Toss
---

Browsing through my Twitter stream, I came across a blog post discussing an allegedly 3.8-sigma event: [Apparently the last 14 Super Bowl coin tosses have been won by the NFC](http://blogs.discovermagazine.com/cosmicvariance/2012/02/04/a-3-8-sigma-anomaly/). What are the chances of this? The blog linked to above claims a probability of (1/2)<sup>13</sup>. Another [blog](http://www.outsidethebeltway.com/super-bowl-coin-flip/) claims (1/2)<sup>14</sup>. Which is correct? Before I get into the mathematics, I'll try to disentangle three different questions:

1. Out of 14 tosses, what's the probability that they all come up heads?
2. Out of 14 tosses, what's the probability that one team wins all of them?
3. Out of 45 tosses (one for each Super Bowl), what's the probability that one team wins a string of 14 of them?<sup>1</sup>

**(1/2)<sup>14</sup>** is the correct answer to question (1). There's a 1 in 2 chance of getting heads. The probability of getting heads 14 times out of 14 tosses is therefore (1/2)<sup>14</sup>.

**(1/2)<sup>13</sup>** is the correct answer to question (2). If you call a coin in the air, there's 1 in 2 chance you'll win the toss. Out of 14 tosses, the chance that *either* the NFC will win the toss 14 times *or* the AFC will win the toss 14 times is: (1/2)<sup>14</sup> + (1/2)<sup>14</sup> = (1/2)<sup>13</sup>.

The last situation is much more difficult to calculate, and similar questions are often the cause for much surprise. For example, if you toss a coin 20 times, do you think it's likely or unlikely that you'll get a string of 5 heads in a row? It seems like this should be unlikely. After all, the probability of tossing a coin 5 times, and ending up with heads every time is quite small: (1/2)<sup>5</sup> = 1/32  (approx. 3%). Believe it or not, the actual probability is around 25%.<sup>2</sup>

How are these probabilities found? One solution is a rather nasty recursive formula.
>	A similar recursion can be given to calculate the probability that in *n* fair coin tosses a run of *r* heads or *r* tails occurs. In this case, we say that the tossing process is in state *(i, k)* when there are *k* tosses still to go and the last *i* tosses all showed the same outcome but so far no run of *r* heads or *r* tails has occurred. The probability *v<sub>k</sub>(i)* is defined as
>
>	v<sub>k</sub>(i) = the probability of getting a run of *r* heads or *r* tails during *n* tosses when the current state of the tossing process is *(i, k)*.
>
> The probability *v<sub>n-1</sub>(1)* is being sought (why?). Verify for yourself that the following recursion applies for k = 1,2,...,*n*.
>
>	v<sub>k</sub> = 0.5\*v<sub>k-1</sub>(i + 1) + 0.5*v<sub>k-1</sub>(1) for i =,...,r - 1.
>
> The boundary conditions are *v<sub>0</sub>(i) = 0* for *1 <= i <= r -1* and *v<sub>j</sub>(r) = 1* for *0 <= j <= n - 1*.<sup>3</sup>

I'm actually not sure why we're looking for *v<sub>n-1</sub>(1)* as opposed to *v<sub>n</sub>(0)*. I tested it for a few values, and those expressions seem to be equal.<sup>4</sup> In any case, the formula is dense, but you can see the logic behind it. If you're in the midst of a streak of heads, and your next flip comes up heads, your state is now *(i+1, k-1)*. That is, your streak has increased, but your tosses to go has decreased. This explains the first half of the formula: *0.5\*v<sub>k-1</sub>(i + 1)*. The other case is that you're in the midst of a streak of heads, but then you get a tail, so your state becomes *(1, k-1)*. That is, you now have a streak of 1 tail, and your total number of tosses to go decrements by one. This explains the last half of the equation. The equation then branches out like a tree, solving for each possibility along the way. Here's a bit of Scheme that implements this:

``` scheme
(define (coin-streak n r)
    (define (cs-helper k i)
      (cond ((and (<= 1 i) (<= i (- r 1)) (= k 0)) 0)
            ((and (<= 0 k) (<= k (- n 1)) (= i r)) 1)
            (else (+
                   (* (/ 1 2) (ct-string r n (- k 1) (+ i 1)))
                   (* (/ 1 2) (ct-string r n (- k 1) 1 ))))
            ))
    (cs-helper (- n 1) 1))
```

Notice that this problem quickly becomes intractable for large values of *n*. Each call branches into two different calls, giving an exponential growth (props to the first person who posts a tail recursive memoization). This is why I prefer solving this by simulation. What we need to do is simulate 45 coin flips, and check if we've encountered a string of 14 heads or 14 tails. Do this, say, 100,000 times and see how often this event occurs.

``` python
#!/usr/bin/python -O

import random
import sys

STREAK_LEN  = int(sys.argv[1])
TOSSES      = int(sys.argv[2])
TRIALS      = int(sys.argv[3])

def simulation(trials, tosses, streak):
    ''' Simulates *trials* trials of *tosses* tosses and returns the
        fraction of trials that contained at least one streak
        of *streak* or higher.
    '''

    def run_trial():
        ''' Flips a coin *tosses* times and returns True if a streak of
            *streak* length is encountered.
        '''
        cur_streak = 1      # Length of the current streak.
        prev_outcome = None # Outcome of a previous toss.
        # Simulate the tosses.
        for toss in range(tosses):
            outcome = random.randint(0,1)
            # If the last toss is the same as the current toss,
            # increment the length of the current streak.
            if outcome == prev_outcome:
                cur_streak += 1
            else:
                cur_streak = 1

            # If the current streak is equal to the target
            # length, return True
            if cur_streak == streak:
                return True

            prev_outcome = outcome

        return False

    streak_count = 0
    # Simulate all the trials, and keep track of how many had
    # a streak.
    for trial in range(trials):
        had_a_streak = run_trial()
        if had_a_streak:
            streak_count += 1

    return streak_count / float(trials)

if __name__ == "__main__":
    print simulation(TRIALS, TOSSES, STREAK_LEN)
``` 

We can now simulate the Super Bowl situation by looking for a streak of 14 wins out of 45 tosses with 100,000 simulations.

``` bash
% ./ctsim.py 14 45 100000
0.00202
```

So, the probability of this happening is **0.00202** or around **0.2%**. This is still tiny, but not as small as (1/2)<sup>13</sup> (approx. 0.00012 or 0.012%).



##Notes:##
1. Even this is slightly ambiguous. The exact question that we'll be looking at is: What is the probability that one team will have at least one winning streak of at least 14 tosses.
2. Tijms, H. (2010). Understanding probability: Chance rules in everyday life. (2 ed.). Cambridge, UK: Cambridge University Press.
3. Ibid.
4. Perhaps the equation *v<sub>n</sub>(0)* is technically undefined. That is, *i* cannot equal 0 because you must have a streak of at least 1 head or 1 tail. Nevertheless, it looks like the formula still works for this technically undefined state.
