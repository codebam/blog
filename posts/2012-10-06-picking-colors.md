---
title: Picking Colors Optimally
author: Alex Beal
date: 10-07-2012
type: post
permalink: picking-colors
desc: Optimally picking colors.
---

Lately I've been thinking about how to optimally pick colors. What I mean by that, is how can I algorithmically pick colors that seems "far away" from each other, or that contrast maximally with each other. A solution to this problem would have many uses. For example, suppose that you're writing a graphing library, that takes in a set of lines, and displays them on the screen. Ideally, each line should be assigned a color that contrasts well with the other lines, so that it's easy to tell the lines apart. Having a way of algorithmically picking these colors would be handy.

The first issue is that the problem itself is vague. What does it mean for two colors to be distinct or "far away" from each other? And, given a definition of distinctness, what sort of algorithm would be need to generate these colors?

## Color Contrast
One way of quantifying the contrast between colors is to look at a color's hexadecimal representation, which is a set of three values, one value for each color channel. The first two digits of a hex color represent its red value, the next two represent its green, and the last represent its blue. The color `#FF0000`, for example, is red, because the red channel is at its maximum value (`0xFF` or 255), and the other channels are both `0x00`, and thus turned off. 

This is useful because a color can now be represented as a 3D coordinate, with each channel representing a dimension. `#FF0000`, for example, can be translated into the coordinate `(255,0,0)`. If every possible color is translated into a coordinate, and graphed, the graph will be of a cube of colors, stretching from `(0,0,0)` to `(255,255,255)`. Every color inside the cube is a valid RGB color. Below is a depiction of this cube. ^[This image was created by [SharkD](http://commons.wikimedia.org/wiki/User:SharkD) and has been released under the CC Attribution-Share Alike 3.0 Unported license.]

<img src="http://media.usrsb.in/picking-colors/rgb-cube.png" width="480px" height="480px">

The concept of contrast between colors now seems obvious. Colors seem to contrast if they are located at distant points on this RGB color cube. We can now quantify contrast as the euclidean distance between two RGB color coordinates.

$$d=\sqrt{(r_1-r_2)^2+(g_1-g_2)^2+(b_1-b_2)^2}$$

Looking at it this way, picking contrasting colors boils down to maximizing the distance between two colors represented as coordinates.

## Algorithm
Now that I have a working definition of color contrast, the next step is to work out the algorithm for maximizing it. First, it would be helpful to specify what exactly this function should do. The idea is that it should take in a set of colors, represented by their RGB values, and return a color that is as far away as possible from the other colors. When looked at this way, it seems an awful lot like an optimization problem, which could be tackled with the hill climbing algorithm. For those who are unfamiliar, the idea behind the hill climbing algorithm is to optimize for some property by choosing a starting point and greedily move to the next best neighboring point, until there are no better neighboring points left.

Returning to the cube analogy, the algorithm could be conceptualized as follows: Given a cube full of points (each representing a color), pick another point in that cube that maximizes its distance from the other points. The pseudocode would look something like this:

1. Start at an arbitrary coordinate. For example: `(0,0,0)`.
2. Repeat:
    1. Get all of the neighboring points that you could legally move to.
    2. If none of the points are better than your current point, return the current point.
    3. Otherwise, move to the best of the neighboring points.

Implementing this requires two components. First, I need a function that takes as a parameter my current coordinate and returns a list of neighboring coordinates. I'll call this function `getSuccessors` because it gets a list of coordinates that are successors to my current coordinate. The second is a function that tells me if moving to that coordinate would improve my position at all. I'll call this function `evalSuccessor`, because it evaluates a successor relative to my current location.

Intuitively, `getSucessors` is simple. Given the current location, you can either increment the coordinate's x-value, decrement it, or keep it the same. The same can be done to the y or z-values. You can either hard code these possibilities by hand (26 total), ^[Each coordinate can be incremented, decremented, or left alone, so there are 3 possibilities for 3 coordinates, or 3^3. We then remove the "empty" move, where all coordinates stay the same.] or generate them using something like [my permutation function](Permutations--An-Interview-Question.html). Below is my implementation of `getSuccessors`:

``` python
def getSuccessors(color):
    def perm(l, n, str_a, perm_a):
        """Generate every permutation of length `n`, selecting from the
           possible values in `l`.
        """
        if len(str_a) == n:
            return (str_a,) + perm_a
        else:
            new_perm_a = perm_a
            for c in l:
                new_perm_a = perm(l, n, str_a + (c,), new_perm_a)
            return new_perm_a

    def applyMove(color, move):
        """Given a "move" of the form (x,y,z) apply that move to `color`.
           Eg, applyMove( (255,1,255), (0,1,0) ) => (255,2,255)
           If the move isn't legal, return None.
        """
        if move == (0,0,0):
            return None

        r,g,b = color
        dr,dg,db = move
        if 0 <= r+dr <= 255:
            r = r+dr
        else :
            return None

        if 0 <= g+dg <= 255:
            g = g+dg
        else :
            return None

        if 0 <= b+db <= 255:
            b = b+db
        else :
            return None

        return (r,g,b)

    successors = []
    # It would be better to pregenerate this, but for clarity, I regenerate
    # it every time.
    movements = perm([1,-1,0], 3, (),())
    for move in movements:
        succ = applyMove(color, move)
        if succ is not None:
            successors.append(succ)
    return successors
```

So, `getSuccessors` generates every possible move using `perm`, attempts to apply each move using `applyMove`, and only returns the resulting coordinates that are legal.

The next component, `evalSuccessor` needs to take in the current point and the possible successor point, and return how much better (or worse) it is than the current point. This raises an interesting problem. Up until now, I've been vague about what it means to be "as far away as possible from the other points." There are a couple possibilities. I could maximize the average distance from the other points. Or I could maximize the distance from the closest point (maximize the minimum distance). ^[Minimizing the maximum distance might also be interesting if you want to solve the opposite problem: Finding the color that's closest to a set of other colors.] Both of these strategies are probably useful, but I chose the second, as the first might end up selecting a color that is very near another color, but *on average* far away from the other colors. This would be undesirable in a lot of cases, such as with my imaginary graphing library. Without further ado, below is my implementation of `evalSuccessor` along with a couple helper functions:

``` python
def euclideanDist(cur, succ):
    r,g,b = cur
    nr,ng,nb = succ
    return math.sqrt(math.pow(r-nr,2) + math.pow(g-ng,2) + math.pow(b-nb,2))

def closestPoint(cur, point_list):
    """Find the point in the `point_list` that is closest to `cur`."""
    return min(point_list, key=lambda point: euclideanDist(cur, point))

def distClosestPoint(cur, point_list):
    """Find the distance to the point in `point_list` that is closest to `cur`.
    """
    return euclideanDist(closestPoint(cur, point_list), cur)

def evalSuccessor(cur, succ, point_list):
    """Find the distance to the point closest to `cur`.
       Find the distance to the point closest to `succ`.
       Return the difference. This tells us whether cur or succ is better.
    """
    cur_closest_dist = distClosestPoint(cur, point_list)
    succ_closest_dist = distClosestPoint(succ, point_list)
    return succ_closest_dist - cur_closest_dist
```

So, `evalSuccessor` finds the distance to the point nearest the current point and then does the same for the possible successor point. ^[Notice that finding the actual euclidean distance isn't necessary. Maximizing the sum of the squares would be just as effective as maximizing the euclidean distance, but I've left it as the actual euclidean distance for clarity.] It then returns the difference between the two. If the difference is positive, the successor is better than the current, and vice versa if the difference is negative.

Now that I have the basic building blocks of the hill climbing algorithm, it's straightforward to implement:

``` python
def hillClimbColor(color_list, start):
    cur_color = start
    while True:
        maximizing_moves = []
        for succ in getSuccessors(cur_color):
            next_maxi_min = evalSuccessor(cur_color, succ, color_list)
            if next_maxi_min > 0:
                # Only get the successors that are better than the current.
                maximizing_moves.append( (succ, next_maxi_min) )
        if len(maximizing_moves) == 0:
            # If maximizing_moves is empty, there are no better successors.
            return cur_color
        else:
            # Move to the best successor.
            cur_color = max(maximizing_moves, key=lambda pair: pair[1])[0]
```

Each iteration of the `while` loop gets all the successors of the current point, and evaluates them. If they are better than the current point, they are saved to a list. If the list is empty, then that means there are no better successors, so the current point is returned. If there are maximizing successors, then it moves to the best of the maximizing successors.

Testing this out with a few simple cases seems to work:

```
>>> hillClimbColor([(0,0,0)], (0,0,0))
(255,255,255)
>>> hillClimbColor([(0,0,0),(255,255,255)], (0,0,0))
(0,128,255)
```

`(255,255,255)` is of course the point farthest from `(0,0,0)`, and `(0,128,255)` is the farthest from `(0,0,0)` and `(255,255,255)` (perhaps not as obvious). The trouble begins when I start to introduce local maxima:

```
>>> hillClimbColor(
        [(0,0,0),(5,5,5),(0,0,5),(0,5,0),(0,5,5),(5,0,0),(5,5,0),(5,0,5)],
        (0,0,0) )
(2,2,2)
```

What I've done here is essentially wall the `(0,0,0)` corner in with a bunch of points approximately 5 units away. The hill climbing function starts at `(0,0,0)` and starts moving away, but can never move past the wall since it only checks its immediate neighbors. It essentially get stuck on a local maximum without seeing the global maximum at `(255,255,255)`. This can be fixed by picking a better starting point, slightly beyond the wall:

```
# Start at (6,6,6)
>>> hillClimbColor(
        [(0,0,0),(5,5,5),(0,0,5),(0,5,0),(0,5,5),(5,0,0),(5,5,0),(5,0,5)],
        (6,6,6) )
(255,255,255)
```

The function is now able to climb to `(255,255,255)`. This also hints at a possible solution to the issue. Rather than always starting at `(0,0,0)`, the hill climbing could start at a random point. Or better yet, the hill climbing could be run multiple times, with each iteration starting from a random point, and then select the best point from the set of returned points. The more iterations of this, the more likely it is to find the global maximum. This is known as **random-restart hill climbing**. ^[Russell, Stuart, and Peter Norvig. Artificial Intelligence: A Modern Approach. 3rd ed. Upper Saddle River, New Jersey: Pearson Education, Inc., 2010. 124. Print.] Implementing random-restart is easy now that the hill climbing function has already been written:

``` python
def randomRestartHillClimbColor(color_list, restarts):
    """Pick a color that contrasts well with all the colors in `color_list`
       using the random-restart hill climbing algorithm. Restart `restart`
       times.
    """
    best_color = None
    for i in xrange(restarts):
        start = (
                random.randint(0,255),
                random.randint(0,255),
                random.randint(0,255),
                )
        color = hillClimbColor(color_list, start)
        if best_color is None:
            # On the first iteration, best_color will be None, so `color` is
            # trivially better.
            best_color = color
        else :
            # Compare the color found by hillClimbColor to the current best
            # color.
            margin = evalSuccessor(best_color, color, color_list)
            if margin > 0:
                # Replace the current best color, if the new color is better.
                best_color = color
    return best_color
```

This function runs `hillClimbColor` multiple times (specified by `restarts`), and with a different random starting location. The result of each iteration is compared to the current best result, as evaluated by `evalSuccessor`, and the best result is returned. Essentially, it finds a bunch of maxima, and returns the maximum maximum, in the hope that it's the global maximum. This easily deals with the previous local maximum case:

```
>>> randomRestartHillClimbColor(
        [(0,0,0),(5,5,5),(0,0,5),(0,5,0),(0,5,5),(5,0,0),(5,5,0),(5,0,5)],
        10)
(255,255,255)
```

Excellent.

## Colors

You've gotten this far. The least I could do is give you some colors:

<font color='#FFFFFF'>#FFFFFF</font> <- white<br>
<font color='#000000'>#000000</font><br>
<font color='#80FF00'>#80FF00</font><br>
<font color='#7F00FF'>#7F00FF</font><br>
<font color='#FF1F20'>#FF1F20</font><br>
<font color='#00E0DF'>#00E0DF</font><br>
<font color='#616F6F'>#616F6F</font><br>
<font color='#FF5FC0'>#FF5FC0</font><br>
<font color='#0000A3'>#0000A3</font><br>
<font color='#00A400'>#00A400</font><br>
<font color='#FFBA3F'>#FFBA3F</font><br>

This was generated by running `randomRestartHillClimbColor` 10 times, with `#FFFFFF` as the only color in the set to start with. Every time a color was found, it was added to the set, and the hill climber was run again. The result is a set of 11 colors that are nice and contrasty.

One question I have about this last procedure is whether or not it maximizes the overall contrast between all the colors. At each iteration, the contrast between the set of colors, and the new color is maximized, but is this sufficient for maximizing the overall contrast? I'm not sure, but I suspect not. I'll leave solving this one as an exercise to the reader.

The complete code can be found at this gist: [https://gist.github.com/3848987](https://gist.github.com/3848987)

## Notes

