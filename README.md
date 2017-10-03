RealGo
------

RealGo is a generalization of the board game Go.
While in Go the stones are placed on a grid, in RealGo they can be placed anywhere on the board.
Since the goal of the game is to surround more territory than the opponent, RealGo is only possible on a computer.
The exact area calculation would not be possible on a real Go board.

The name RealGo is ironic in two ways, the first of which I just explained.
Additionally, RealGo does not actually work with real numbers or floating point numbers, but also works on a (finer) grid and with (big) integer numbers.
This is since real numbers in a computer are finite anyway.
So RealGo is not real, neither in an actual nor in a mathematical sense.

However, there is a RealGo in an idealized mathematical sense that works with circles (as 2d discs with a 1d border), circumferences (1d curves) and 0d points.
To simulate this on a computer you would have to solve equations, like intersections of circles to get points, etc.
But as soon as you store the coordinates of such points you are effectively on a grid again, and you would have to think of methods to avoid this.
Although not impossible this seemed too difficult after a while and I thought of a way to put everything on a grid.

My line of thought was as follows:
For every concept in Go we have to find an analogue, so the analogue of a grid is the entire board. One. Ok, great, got that. So far so good!
Next.
The analogue of a stone would be...... a disc! Of course, what else. This is going surprisingly well!
Oh oh, but now we're in trouble. What is a liberty and how to kill stones?
Hm. Well, let's make a cup of black tea first...

So in Go a single stone has four liberties and to kill it, you place four other stones around it.
Wouldn't it be great if this was the same in RealGo? What would the concept of liberties have to be like, so that this comes out?
What happens with four surrounding stones that doesn't happen with three or five?
If you imagine it graphically, you can place six stones touching around the one stone in the middle.
If you take every other of these six away, three remain in such a way that the removed ones would fit exactly back in.
But if you roll them slightly closer together around the middle stone, one gap remains that is a little bit bigger than a stone,
while the other two gaps are slightly smaller and "close it off".

With three you can do that, but with four not anymore.
Four stones can easily be placed in a way that everything is closed off around the middle stone.
So we could define a circular curve around the middle stone, that gets covered by the surrounding stones.
And if no part of the remaining curve is longer than a stone diameter, the stone is killed.
The curve is the analogue of the four liberties of Go.

But wait, there's something else with liberties:
You have to be able to place a stone on them.
Imagine following situation: we kill a stone by placing four other stones around it, such that they are touching.
No atom or even subatomic particle fits in between.
The circles are mathematically touching (which actually means they have one point on their circumference in common).
So now the stone in the middle is removed, but there has to remain a liberty from the surrounding four stones.
This libery is one mathematical 0d point and this leaves not much choice for the liberty curve:
It is exactly at two times the radius of the stone.
This way the situation is symmetrical for touching stones:
For every place on the liberties of stone 1 there is one place on the liberties of stone 2 and it is the center of stone 1.

The next concept we have to think about is connection. When are two stones considered connected?
In Go it is easy, either they are diagonal to each other, or a stone fits in between or it doesn't.
So the distance between two stones should be decisive here, for sure it means something when no stone fits between two stones anymore.
If we call this a connection, maybe imagine it with a line, then suddenly we realize that something else can happen in RealGo:
There can be two other stones with a connection line crossing the first one.
What to do now? Is this good or bad? Is this the analogue of cutting in Go?
So many questions, so much uncertainty. We need another cup of strong, hot, black tea (two bags).

Well in the end I decided that I couldn't decide: you can switch variations in RealGo.
In one variant the shorter of the two connections cuts the longer one, in an other it doesn't.
In a third variant both are cut.
But we are not done with distances and connections, there is a second decisive distance.

So if you wanted to avoid cutting in this manner, you would move the two stones closer together, right?
Now the question arises when is this cutting not possible anymore?
The answer is when the two stones are at a distance of sqaure root of two times the diameter apart.
All four stones are touching and at the corners of a square.
So now we have two connection distances, and we can call the first one weak connections and the second one strong connections.
Weak connections can be cut, strong connections can't (not because I say so, but for geometric reasons).

We are not done, we still have to explain what groups are, and what a territory is.
And then we have to say something about ladders, kos and eyes.
But first let's think a little bit more about liberties and our liberties curve.
If you imagine placing stones on the board with this curve around them, you see that you can't always place stones everywhere on these curves.
Do you see it? Do you SEE it? Tell me that you see it! OK.
This is not because these places are covered by stones themselves, but because you couldn't place a stone there without overlapping with an other stone.
So the liberties get killed already by something else, and this is what I would call the influence of a stone.
It turns out that this is exactly the region between the stone and its liberty curve.
If you think about it, it is clear. You simply cannot place a stone there, period. So this region has to kill liberties.
(Don't worry, all the good things about liberties are untouched by that.)

So what are groups now? Again it's hard to decide whether they should be connected by all connections or just the strong ones.
I made it switchable.
And how is territory defined? Only strong connections or both as borders? I made a switch.
But actually this is easier: territory in Go is defined by a closed area on a four connected grid, i.e. two diagonal stones also close it off.
A stone does not fit between two weakly connected stones in RealGo, so this would hint strongly at weak connections for the borders of territories.

This wraps it up for the basic concepts I think, but there are also some emergent phenomena in Go, so let's see how they translate.
Ladders for example.
Well I'm afraid they don't exist in RealGo anymore.
The reason why a ladder works in Go is that the guy in the middle needs two moves to crawl diagonally.
So his opponent can place one stone on either side.
In RealGo you can crawl "diagonally" and indeed in any direction with one move always.
The guy who wants to place stones to your left and then to your right is out of luck, you are faster.
Ladders are an artifact of the grid.

What about eyes? A group that has two eyes lives, one eye dies.
Same in RealGo. The other eye is where your group still has liberties (even if it's only a 0d mathematical point), when all other liberties are occupied. The eyes have to be at least a stone diameter apart however. Otherwise you could cover them both by setting in one of them and then your influence could cover the other one as well.
Suicide is not allowed (or counts as a pass).
A ko means that you can't replace a killed stone in the following move, you have to play elsewhere.
Well this should translate to: you can't play in the vicinity of one stone radius in the next move.
False eyes, bamboo joints, race to kill, etc. there's still much to explore.
I'm only a poor developer and a miserable Go player.
And now I'm getting a tea. You know.

compile with www.freebasic.net

How to play with a friend over the net
--------------------------------------

For the first method you need linux. If you're on PC you can run ubuntu in a VirtualBox.
Get the two programs sendemail and getmail.
Make two email accounts, and for getmail two maildirs and two rc files.
Put that in the source code and recompile (for now).
getmail should be configured to delete the mail on the server.

Method two works without linux.
All you need is a shared directory somewhere.
That can be in your local network at home with a PC and a laptop, say, or over the internet with a dropbox style service.
Just put the realgo.exe in there and start it from there on both computers.

The third method doesn't even need the internet.
Just tell your partner the coordinates of your move over the phone (or send an email or tweet).
He can put them in by pressing "i".

Now you only need a way to agree who's black and who's white. Have fun!


RealGo Day 2
------------

So the other day I thought about RealGo a little bit again and then I found a page where they describe variants of Go, among others also Go on a continuous board. One variant was with territory defined by stones that are touching each other. So I naturally wanted to include this in RealGo as an option. It turned out that this is not so easy as with the strong and weak connections. Because now we have to find out the distance where two other, cutting stones cannot connect anymore through. Geometrically, mathematically this is exactly at square root of 3 times the stone diameter. If two stones are a bit closer together, two other stones cannot connect by touching anymore. But how to implement this on our grid?

Well, after drinking a lot of black, hot, strong black tea (kind of normal at this point), I decided to implement the following method: we are not calculating distances of stones (by using sqr() and floating point numbers) anymore, but we are doing a test that answers a question positively or negatively, definitively. So instead of saying "two stones are weakly connected when they have a distance of two times the stone diameter" we say "these two stones placed at these relative positions to each other passed the weak connection test, so they count as weakly connected". The result of these tests is stored in an array with data points everywhere around the stone itself just like we already did it with influence and liberties. 

In fact, the liberties calculation was already the test for the touching distance. So how do these tests look like? Well, the liberties curve consists of a number of points and if we put a stone there one by the other, it is analogous to sliding a stone around the stone in the middle. Computationally this gives all the positions a stone can be in and touching. There are no other on our grid. The method for the weak distance would be to place a second stone a distance away and let stones slide along them and see if they can move through without getting stuck. The method for the strong distance would be to let two stones slide from either side until they can't go any further, and then compare the distances (or the squares so we don't have to use sqr()). And the method for the sqr(3) distance would be to let two stones slide until they can't go further and then determine if they are touching each other or not. The outcome of all these tests is stored at the position of the second stone.

So the only sqr() calculation that should ever be done is when the stone disc is formed. All the shapes of the influence area, the liberties curve, and the weak and strong connecting areas are determined by the tests. As it turnes out, these shapes are pretty much circular as well. Only a little bit fuzzy and jaggy around the edge. But only on the order of one or two pixels. Nobody needs to rely on the exact shape: we are simply going to show the result of the test in real time while placing the stone, so you can actually see what connection type you would get if you placed the stone where you are hovering it.

So far the technical side, now for a bit of philosophy: so now we have four different distances and connection types: touching, strong connections (where cutting is not possible anymore), sqr(3) connections (where touching stones going through are not possible anymore), and weak (where sliding through a stone is not possible anymore). Now we only have to decide what determines groups and what territory? That is a good question and here is where I propose the following: either you use touching and sqr(3) or weak and strong, never a mixture. But that is of course not definitive.

Note: while it is always possible to get a touching connection with one stone, it is not always possible to get a touching connection with two stones at the same time. This is because on a 4-connected grid the two liberties curves of two stones can intersect without sharing a pixel. The solution would be to use a 6-connected (hexagonal) or 8-connected (like now plus diagonals) gird as representation of the continuous board. So as long as this is not implemented, the touching connection is replaced with a "close" connection that is one pixel wider. This way the resulting curve is guaranteed to have overlapping pixels and you can always get "close" connections with two stones simultaneously. Of course the test for "near" is now carried out with tests for "close". (The board edges are still "touching".)

Keys
----

		ESC     quit
		LMB     place stone
		RMB     pan
		wheel   zoom
		p       show pixels
		i       input coordinates to place stone
		t       show territory
		f       fullscreen/windowed toggle
		s       save game to file
		l       load game from file
		k       kill stone near mouse
		m       increase move (change color, pass)
		1-5     show influence, liberties, numbers, connections
		7-0     setting type, connection cutting, groups and territory switches
		q	switch stone scoring
		w	switch captured stone scoring
		e	switch for innner territory scoring

