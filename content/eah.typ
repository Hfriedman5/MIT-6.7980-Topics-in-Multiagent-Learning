// Port of Lectures/content/eah.tex; Fall 2025 source.
#import "meta/gabri_notes.typ": *
#show: gabri_notes.with(lec_num: "S1", date: [Fall 2026], title: "A second look at the minimax theorem", instructor: [Prof. Gabriele Farina])

In Lecture 3, we introduced the notion of coarse correlated equilibria. As we discussed, coarse correlated equilibria sidestep various difficulties (including topological and related to use of irrational numbers) that come with Nash equilibria. In this lecture, we show a powerful centralized algorithm for computing coarse correlated equilibria. (Soon in this course, we will also see that coarse correlated equilibria can also be #emph[learned] efficiently in a multi-agent setting, in a distributed fashion.)

We have seen at the end of Lecture 3 that a coarse correlated equilibrium can be computed by solving a linear program, in which the variables correspond to the probabilities $mu_(a_1 \, dots.h \, a_n)$ of the joint actions, and the constraints correspond to the incentive constraints of the players. While this is a perfectly valid way to compute a coarse correlated equilibrium, it has the drawback that the linear program has a number of variables that is exponential in the number of players. This becomes an issue quickly, if we want to consider games with many players. It also is a problem for those games in which the payoff tensor has a succinct representation (for example, a sparse factorization that we can exploit); there, we would ideally want an algorithm that runs in polynomial time in the size of such a succinct representation. The latter is often the case in structured games, which we will see later in this course.

In this lecture, we will see a different algorithm for computing coarse correlated equilibria, which does not suffer from the above issues and requires a number of variables that scales with the #emph[sum] (rather than #emph[product]!) of the number of actions of the players. The algorithm is called Ellipsoid-Against-Hope, and was introduced by #citet(label("papadimitriou2008computing")), with later extensions by other authors #citep(label("jiang2011polynomial"), label("huang2008computing"), label("farina2024polynomial")).

The algorithm is based on a constructive proof of the minimax theorem, which we will also present in this lecture.

= Revisiting the existence of coarse correlated equilibria

In order to understand why there is hope to compute coarse correlated equilibria more efficiently, it is useful to understand better how we can prove that these equilibria exist in the first place. We will then turn such an existence proof into a computational algorithm.

So far, we have justified the existence of coarse correlated and correlated equilibria through the existence of Nash equilibria. However, one might wonder if there is a more direct way to prove the existence of CEs and CCEs, which does not rely on the existence of a much harder notion. The answer is yes, and the idea comes from a very neat proof by #citet(label("Hart89")), which includes some ideas that will set the stage for the Ellipsoid-Against-Hope algorithm.

While the original proof of #citet(label("Hart89")) is for CE, I will present here a version of the proof simplified for the case of CCEs.

As a reminder, by definition a coarse correlated equilibrium is a distribution $mu in Delta (A_1 times dots.h times A_n)$ such that

$ bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i))] lt.eq bb(E)_(a tilde.op mu) [u_i (a_i \, a_(- i))] #h(2em) forall i in \[ n \] \, a'_i in A_i \, $

or equivalently,

$ max_(i in \[ n \]\
a'_i in A_i) bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))] lt.eq 0 . $

A CCE then exists if and only if

$ min_mu max_(i in \[ n \]\
a'_i in A_i) bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))] lt.eq 0 . $

How can we prove the above inequality without resorting to the existence of Nash equilibria? #emph[The rescue comes from the minimax theorem.]

Before we can use the minimax theorem, we have to “convexify” the inner problem however, since the maximum is currently on a discrete set. To convexity the problem, we will simply allow the possibility for the internal maximumization problem to propose a #emph[distribution] $nu$ over deviations $(i \, a_i)$, and we will rewrite the problem as

$ min_mu max_nu bb(E)_(a tilde.op mu) bb(E)_(\( i \, a'_i \) tilde.op nu) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))] lt.eq 0 . $

By the minimax theorem and swapping the order of the expectations, the above min-max value is equal to

$ max_nu min_mu bb(E)_(\( i \, a'_i \) tilde.op nu) bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))] . $

Can we show that this value is $lt.eq 0$? The answer is yes, and constructive: given any $nu$, we can find a $mu$ in closed form---in fact, a #emph[product] distribution---such that the value is $lt.eq 0$.

#theorem[#citet(label("Hart89"))][
Given any distribution $nu$ over pairs $(i \, a'_i) : i in \[ n \] \, a'_i in A'_i$, we can explicitly and efficiently construct a product distribution $mu in Delta \( A_1 \) ⊗ dots.h ⊗ Delta \( A_n \)$ such that

$ bb(E)_(\( i \, a'_i \) tilde.op nu) bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))] lt.eq 0 . $
]#label("thm:hart schmeidler")

The above theorem immediately implies that

$ max_nu min_mu bb(E)_(\( i \, a'_i \) tilde.op nu) bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))] lt.eq 0 \, $

and using the minimax theorem, we conclude the existence of coarse correlated equilibria.

= Turning the minimax theorem into an efficient algorithm

Like what we did for the Nash equilibrium in Lecture 2, it is worth inspecting where the “magic” happens in the above proof. If we squint our eyes a bit, the argument of the proof looked like this:

#enum(numbering: "1.", 
[
We want to prove that $min_mu max_nu g \( mu \, nu \) lt.eq 0$, for an appropriate $g$ that is linear in both $mu$ and $nu$. That is, we want to show that there #emph[exists] a $mu$ such that #emph[for all] $nu$, $g \( mu \, nu \) lt.eq 0$.
],
[
To do that, we instead show that #emph[for all] $nu$, there #emph[exists] a $mu$ (dependent on $nu$) such that $g \( mu \, nu \) lt.eq 0$. This shows that $max_nu min_mu g \( mu \, nu \) lt.eq 0$.
],
[
Then, we use the minimax theorem to swap the order of the quantifiers, and conclude that $min_mu max_nu g \( mu \, nu \) lt.eq 0$. The use of the minimax theorem in our case was justified because $g \( mu \, nu \)$ is linear in both $mu$ and $nu$.
]
)

It is easy to brush away swapping the order of the quantifiers as just one of the many results in mathematics that are concerned with swapping orders of operators. But let us stop to consider how powerful this is. The original problem was to find a single $mu^(*)$ that works for all $nu$ (Step 1). However, the minimax theorem (Step 3) tells us that as long as for any specific $nu$ we can construct a $mu \( nu \)$ that works #emph[for that $nu$ specifically], then a $mu^(*)$ that works for any $nu$ (not for one specific) must exist (Step 2). It feels way less simple than it looks at first sight, right?

The Ellipsoid-Against-Hope algorithm can then be seen as a way to convert the minimax theorem from a tool guaranteeing existence into a computational algorithm. In particular, the idea is the following:

#list(
[
We will query a few “well-chosen” distributions $nu_t$, and for each of them, construct the corresponding $mu \( nu_t \)$ that works for that specific $nu_t$. The number of queries will be small, polynomial in the sum of the number of actions of the players and $log \( 1 \/ epsilon.alt \)$.
],
[
Then, we will combine all the $mu \( nu_t \)$ we have constructed into a single $mu^(*)$ that works for all $nu$. In particular, the $mu^(*)$ will be a convex combination of the $mu \( nu_t \)$ we have constructed, with coefficients that can be computed efficiently by solving a linear program with a number of variables that is again polynomial in the sum of the number of actions of the players and $log \( 1 \/ epsilon.alt \)$.
]
)

Combining the two steps above, we will have constructed a $mu^(*)$ that is an $epsilon.alt$-coarse correlated equilibrium, and that can be represented as a convex combination of product distributions. In other words, we have shown the following corollary.

#corollary[
There exists an algorithm that computes an $epsilon.alt$-coarse correlated equilibrium in time polynomial in the sum of the number of actions of the players and $log \( 1 \/ epsilon.alt \)$. Such a coarse correlated equilibrium is represented as a convex combination of product distributions.
]

== Sketch of the Ellipsoid-Against-Hope algorithm

In more detail, what #ref(label("thm:hart schmeidler")) implies is that the following open polytope must be empty:

$ {nu in Delta {(i \, a'_i) : i in \[ n \] \, a_i in A_i} : bb(E)_(\( i \, a'_i \) tilde.op nu) bb(E)_(a tilde.op mu) [u_i (a_i \, a_(- i)) - u_i (a_i \, a_(- i))] > 0\
forall mu in Delta (A_1 times dots.h times A_n)} . $

Furthermore, for any $nu$, we know how to prove that at least one of the constraints is violated. The key idea is then to use the ellipsoid method to #emph[certify] the emptiness of the polytope. Normally, the ellipsoid method is used to find a point in a set, but in our case, the point does not exist and we want to use the ellipsoid method to isolate constraints that prove the emptiness of the set. For this reason, the algorithm was called Ellipsoid-Against-Hope by #citet(label("papadimitriou2008computing")).

The ellipsoid will maintain a search space which can be thought of as a suitable subset of the deviator's set. At every iteration $t$, the algorithm will compute the center point $nu_t$ of the set. Then, it will find a violated constraint using the distribution $mu_t colon.eq mu \( nu_t \)$ in the proof of #ref(label("thm:hart schmeidler")). The violated constraint implies that the deviator set must be curtailed, and the ellipsoid will be updated accordingly reducing the size of the search space by a constant. The algorithm will continue until the search space is small enough to guarantee that the set is empty. In the process, it takes $O (log (1 \/ epsilon.alt))$ iterations for the search space to shrink to size $epsilon.alt$. By the last iteration $T$, the algorithm will have produced several violated constraints, each of which is associated with a mediator strategy $mu_t$. The set

$ {nu in Delta {(i \, a_i) : i in \[ n \] \, a_i in A_i} : bb(E)_(\( i \, a'_i \) tilde.op nu) bb(E)_(a tilde.op mu_1) [u_i (a_i \, a_(- i)) - u_i (a_i \, a_(- i))] > 0\
dots.v\
bb(E)_(\( i \, a'_i \) tilde.op nu) bb(E)_(a tilde.op mu_T) [u_i (a_i \, a_(- i)) - u_i (a_i \, a_(- i))] > 0} . $

The constraints of the set are all linear in $nu$, and the set is empty. By Farkas' lemma, there must exist a convex combination of the constraints the makes all the coefficients on the left-hand size non-positive. In other words, there must exist $alpha_1 \, dots.h \, alpha_T gt.eq 0$ such that

$ sum_(t = 1)^T alpha_t bb(E)_(a tilde.op mu_t) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))] lt.eq 0 \, #h(2em) forall i in \[ n \] \, a'_i in A_i . $

Letting $macron(mu) := sum_(t = 1)^T alpha_t mu_t$, we can then write

$ bb(E)_(a tilde.op macron(mu)) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))] lt.eq 0 \, #h(2em) forall i in \[ n \] \, a'_i in A_i \, $

and hence $macron(mu)$ is a coarse correlated equilibrium. The only question is whether this combination ${ alpha_t }$ can computed efficiently. This is indeed the case, as we can use linear programming directly to find such a combination, by solving the feasibility program

$ upright("find") & alpha_1 \, dots.h \, alpha_T gt.eq 0\
upright("s.t.") & sum_(t = 1)^T alpha_t bb(E)_(a tilde.op mu_t) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))] lt.eq 0 #h(2em) forall i in \[ n \] \, a'_i in A_i\
 & alpha_1 + dots.h + alpha_T = 1 . $

This completes the sketch of the proof of the correctness of the Ellipsoid-Against-Hope algorithm.

== Applications beyond normal-form games

The above argument mostly uses ideas from convex optimization. In particular, it generalizes verbatim to any #emph[convex game], that is, any setting with the following properties:

#list(
[
Player $i$'s strategy set is a convex set of some dimension $d_i$. For normal-form games, a strategy is an element of $Delta \( A_i \)$, that is, a distribution over the player's strategies. We assume we have oracle access to the set, which runs in time polynomial in $d_i$.
],
[
The utility function $u_i \( x_1 \, dots.h \, x_n \)$ is linear in each player's strategy. For normal-form games, this is true since the utility is just an expectation.
],
[
The utility function $u_i \( x_1 \, dots.h \, x_n \)$ can be evaluated efficiently, let's say in time $R$.
]
)

The Ellipsoid-Against-Hope algorithm can then be applied and runs in time polynomial in $sum_i^n d_i$, $R$, and $log \( 1 \/ epsilon.alt \)$. Examples of games that satisfy the above properties include polymatrix games, congestion games, and sequential imperfect-information (extensive-form) games. We will see some of these games later in this course.

= Bibliographic remarks

If you are curious to read more, the following papers contains extensions and refinements of the idea of Ellipsoid-Against-Hope.

#lec_bibliography("meta/refs.bib", title: none)

#appendix[
= Appendix: Proof of Theorem~#ref(label("thm:hart schmeidler"), supplement: none)

The key here is to pick $mu$ in a way that depends on $nu$. In particular, we will pick $mu$ to be the #emph[product] distribution that outputs

$ (a_1 \, dots.h \, a_n) upright(" with probability proportional to ") nu_(1 \, a_1) dot.op dots.h dot.op nu_(n \, a_n) . $

With this choice and some simple manipulations,

$  & bb(E)_(\( i \, a'_i \) tilde.op nu) bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))]\
 & = sum_i sum_(a'_i in A_i) nu_(i \, a'_i) bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i)) - u_i (a_i \, a_(- i))]\
 & = sum_i sum_(a'_i in A_i) nu_(i \, a'_i) (bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i))] - bb(E)_(a tilde.op mu) [u_i (a_i \, a_(- i))])\
 & = sum_i (sum_(a'_i in A_i) nu_(i \, a'_i) bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i))] - sum_(a'_i in A_i) nu_(i \, a'_i) bb(E)_(a tilde.op mu) [u_i (a_i \, a_(- i))])\
 & = sum_i #scale(x: 300%, y: 300%)[\(] underbrace(sum_(a'_i in A_i) nu_(i \, a'_i) bb(E)_(a tilde.op mu) [u_i (a'_i \, a_(- i))], (suit.spade.filled)) - underbrace((sum_(a'_i in A_i) nu_(i \, a'_i)) bb(E)_(a tilde.op mu) [u_i (a_i \, a_(- i))], (suit.club.filled)) #scale(x: 300%, y: 300%)[\)] . $

We now expand $(suit.spade.filled)$, using the symbol $nu_(- i \, a_(- i))$ to mean the product of $nu_(1 \, a_1)$, $dots.h$, $nu_(i - 1 \, a_(i - 1))$, $nu_(i + 1 \, a_(i + 1))$, $dots.h$, $nu_(n \, a_n)$. Using the construction of $m u$ as a product distribution, we can write

$ (suit.spade.filled) & = sum_(a'_i in A_i) nu_(i \, a'_i) sum_(a_i in A_i) sum_(a_(- i) in A_(- i)) nu_(i \, a_i) nu_(- i \, a_(- i)) u_i (a_i \, a_(- i))\
 & = sum_(a'_i in A_i) nu_(i \, a'_i) ((sum_(a_(- i) in A_(- i)) nu_(- i \, a_(- i)) u_i (a_i \, a_(- i))) (sum_(a_i in A_i) nu_(i \, a_i)))\
 & = (sum_(a'_i in A_i) nu_(i \, a'_i) sum_(a_(- i) in A_(- i)) nu_(- i \, a_(- i)) u_i (a_i \, a_(- i))) (sum_(a_i in A_i) nu_(i \, a_i))\
 & = (sum_(a'_i in A_i) sum_(a_(- i) in A_(- i)) nu_(i \, a'_i) nu_(- i \, a_(- i)) u_i (a_i \, a_(- i))) (sum_(a_i in A_i) nu_(i \, a_i)) = (suit.club.filled) . $

Hence,

$ max_nu min_mu bb(E)_(\( i \, a'_i \) tilde.op nu) bb(E)_(a tilde.op mu) [u_i (a_i \, a_(- i)) - u_i (a_i \, a_(- i))] lt.eq max_nu 0 = 0 \, $

completing the proof.
]
