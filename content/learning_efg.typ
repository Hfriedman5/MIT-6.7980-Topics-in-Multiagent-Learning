// Port of Lectures/content/learning_efg.tex; authoritative Fall 2025 source.
#import "meta/gabri_notes.typ": *
#let lecture = (
  lec_num: 8,
  date: [Thu, Oct 8, 2026],
  title: "Learning in extensive-form games",
  instructor: [Prof. Gabriele Farina (#raw("gfarina@mit.edu"))],
)
#show: gabri_notes.with(..lecture)

Several approaches for constructing no-regret algorithms for extensive-form games have been proposed. For one, extensive-form games are a particular instance of combinatorial games for which the multiplicative weights update algorithm can be implemented efficiently in the reduced normal form of the game, despite the exponential size. We will see more details about this in a later class.

As explained in Lecture 7, the natural representation of strategies to define learning in extensive-form games is the #emph[sequence-form representation]. Indeed, in that representation utility functions are linear and the strategy set of each player a convex polytope, aligning with the requirements of the regret minimization framework.

#wrapped-figure(
  [
Thanks to the sequence form representation of strategies, all the results about external regret minimization we have seen so far apply to extensive-form games as well, including for example the fact that a Nash equilibrium in a two-player zero-sum game can be found by letting two regret minimizers play against each other by exchanging sequence-form strategies at every iteration according to the canonical learning setup.
  ],
  [#image("figures/learning_intro/self_play.svg", width: 330pt)],
  side: right,
  text-width: 45%,
)

Another example is the computation of coarse correlated equilibria in any multiplayer extensive-form game via external regret minimization, or computation of best responses against static opponents.

To construct an external regret minimizer that outputs sequence-form strategies, several approaches can be followed. For one, we have seen that one can always use the online projected gradient ascent algorithm, which is a particular instantiation of the online mirror descent (OMD) algorithm. The drawback of such approach is that it requires projecting onto the polytope of sequence form strategies, which might be laborious. Alternative regularizers (#emph[i.e.], distance-generating functions) that render projection easier have been proposed. However, for today we focus on a different approach, which has been extremely popular in practice: the #emph[counterfactual regret minimization (CFR)] algorithm.

= The CFR algorithm

The idea of the CFR algorithm is simple: construct a regret minimizer for the whole tree-form problem starting from #emph[local] regret minimizers at each decision point, each learning what actions to play at that decision point.

#example[
#wrapped-figure(
  [
As an example, consider the TFDP faced by Player~1 in the game of Kuhn poker~#citep(label("Kuhn50:Simplified")), which we already introduced in Lecture 7. The black nodes are the #emph[decision points] of the player, and the white nodes are the #emph[observation points].

  Since the player has six decision points---denoted $j_1 \, dots.h \, j_6$ in the figure---the CFR algorithm will use six local regret minimizers, which we denote $R_1 \, dots.h \, R_6$. Each regret minimizer $R_j$ will be responsible for outputting a local strategy $b_j in Delta (A_j)$ for the decision point $j$.
  ],
  [#image("figures/learning_efg/kuhn_tfdp-transparent.png", width: 340pt)],
  side: right,
  text-width: 50%,
)
]#label("ex:cfr-kuhn")

The local distributions output by the different local regret minimizers is then combined to form a #emph[sequence-form strategy] that plays according to the local distributions at each decision point.

== Where the magic happens: Counterfactual utilities

What is the training signal that each local regret minimizer receives? In other words, what is the utility that the regret minimizer at decision point $j$ observes? The answer is the #emph[counterfactual utility].

Remember that in the sequence form representation, the dimensionality of the strategy vectors matches the number of actions controlled by the players. Hence, the gradient vector received by the regret minimizer has one entry per each action controlled by the player, intuitively representing whether the "probability flow" passing through that action scores well or poorly. The idea of counterfactual utilities is to use as training signal for every $R_j$ the vector of expected utilities in the subtrees rooted at each of the actions $a in A_j$.

It can be shown that the regret cumulated by the CFR algorithm satisfies the following bound.

#theorem[
Let $upright(R e g)_j^(\( T \))$, for $j in cal(J)$, denote the regret cumulated up to time $T$ by each of the regret minimizers $R_j$. Then, the regret $upright(R e g)^(\( T \))$ cumulated by #ref(label("algo:cfr")) up to time $T$ satisfies

$ upright(R e g)^(\( T \)) lt.eq sum_(j in cal(J)) max {0 \, upright(R e g)_j^(\( T \))} . $
]

It is then immediate to see that if each $upright(R e g)_j^(\( T \))$ grows sublinearly in $T$, then so does $upright(R e g)^(\( T \))$.

In order to formally introduce counterfactual utility, we recall a bit of notation to deal with tree-form decision processes.

#strong[Notation for tree-form decision processes]  We recall the following notation for dealing with tree-form decision processes (TFDPs), which we introduced in Lecture 7. The notation is also summarized in #ref(label("tab:notation")).

#list(
[
We denote the set of decision points in the TFDP as $cal(J)$, and the set of observation points as $cal(K)$. At each decision point $j in cal(J)$, the agent selects an action from the set $A_j$ of available actions. At each observation point $k in cal(K)$, the agent observes a signal $s_k$ from the environment out of a set of possible signals $S_k$.
],
[
We denote by $rho$ the transition function of the process. Picking action $a in A_j$ at decision point $j in cal(J)$ results in the process transitioning to $rho (j \, a) in cal(J) union cal(K) union {tack.t}$, where $tack.t$ denotes the end of the decision process. Similarly, the process transitions to $rho (k \, s) in cal(J) union cal(K) union {tack.t}$ after the agent observes signal $s in S_k$ at observation point $k in cal(K)$.
],
[
A pair $(j \, a)$ where $j in cal(J)$ and $a in A_j$ is called a #emph[sequence]. The set of all sequences is denoted as $Sigma colon.eq {(j \, a) : j in cal(J) \, a in A_j}$. For notational convenience, we will often denote an element $(j \, a)$ in $Sigma$ as $j a$ without using parentheses.
],
[
Given a decision point $j in cal(J)$, we denote by $p_j$ its #emph[parent sequence], defined as the last sequence (that is, decision point-action pair) encountered on the path from the root of the decision process to $j$. If the agent does not act before $j$ (that is, $j$ is the root of the process or only observation points are encountered on the path from the root to $j$), we let $p_j = ∅$.
]
)

#example[
As an example, consider again the TFDP faced by Player~1 in the game of Kuhn poker~#citep(label("Kuhn50:Simplified")), which was also recalled above in #ref(label("ex:cfr-kuhn")). We have that $J = {j_1 \, dots.h \, j_6}$ and $K = {k_1 \, dots.h \, k_4}$. We have:

$ A_(j_1) = S_(k_4) & = {sans(c h e c k) \, sans(r a i s e)} \, #h(2em) & A_(j_5) & = {sans(f o l d) \, sans(c a l l)} \, #h(2em) & S_(k_1) & = {sans(j a c k) \, sans(q u e e n) \, sans(k i n g)}\
p_(j_4) & = (j_1 \, sans(c h e c k)) \, #h(2em) & p_(j_6) & = (j_3 \, sans(c h e c k)) \, #h(2em) & p_(j_1) & = p_(j_2) = p_(j_3) = ∅ . $

  Furthermore,

$ rho (k_3 \, sans(c h e c k)) & = rho (j_2 \, sans(r a i s e)) = tack.t \, #h(2em) & rho (k_1 \, sans(k i n g)) & = j_3 \, #h(2em) rho (j_2 \, sans(c h e c k)) = k_3 . $
]

#strong[Notation for the components of vectors]  Any vector $x in bb(R)^Sigma$ has, by definition, as many components as sequences $Sigma$. The component corresponding to a specific sequence $j a in Sigma$ is denoted as $x [j a]$. Similarly, given any decision point $j in cal(J)$, any vector $x in bb(R)^(A_j)$ has as many components as the number of actions at $j$. The component corresponding to a specific action $a in A_j$ is denoted $x \[ a \]$.

#figure(kind: table, supplement: [Table], )[

#table(stroke: none, columns: (auto, 1fr), align: (col, row) => if col == 0 { center + top } else { left + top }, inset: .7em,
table.header([#strong[Symbol]], [#strong[Description]]),
[$cal(J)$],
[Set of decision points],
[$A_j$],
[Set of legal actions at decision point $j in cal(J)$],
[$cal(K)$],
[Set of observation points],
[$S_k$],
[Set of possible signals at observation point $k in cal(K)$],
[$rho$],
[Transition function:

#list(
[
given $j in cal(J)$ and $a in A_j$, $rho \( j \, a \)$ returns the next decision or observation point $v$ in $cal(J) union cal(K)$ in the decision tree that is reached after selecting legal action $a in j$, or $tack.t$ if the decision process ends;
],
[
given $k in cal(K)$ and $s in S_k$ , $rho \( k \, s \)$ returns the next decision or observation point $v in cal(J) union K$ in the decision tree that is reached after observing signal $s$ at $k$, or $tack.t$ if the decision process ends
]
)],
[$Sigma$],
[Set of sequences, defined as $Sigma := { \( j \, a \) : j in cal(J) \, a in A_j }$],
[$p_j$],
[Parent sequence of decision point $j in cal(J)$, defined as the last sequence (decision point-action
    pair) on the path from the root of the TFDP to decision point $j$; if the agent does not act
    before $j$, $p_j = ∅$.]
)
]#label("tab:notation")

== Pseudocode for CFR

Pseudocode for CFR is given in #ref(label("algo:cfr")). Note that the implementation is parametric on the regret minimization algorithms $R_j$ run locally at each decision point. Any regret minimizer $R_j$ for simplex domains can be used to solve the local regret minimization problems. Popular options are the regret matching algorithm, and the regret matching plus algorithm (Lecture 5).

#pseudocode-list(numbered-title: [CFR regret minimizer])[
  - *Data:* $R_j$, regret minimizer for $Delta(A_j)$; one for each decision point $j in cal(J)$ of the TFDP.
  + *function NextStrategy()*
    - _Step 1: ask each of the $R_j$ for their next strategy local at each decision point._
    + *for each* decision point $j in cal(J)$:
      + $b_j^((t)) in Delta(A_j) arrow.l R_j."NextStrategy"()$
    - _Step 2: we construct the sequence-form representation of the strategy that plays according to the distribution $b_j^((t))$ at each decision point $j in cal(J)$._
    + $x^((t)) = 0 in RR^Sigma$
    + *for each* decision point $j in cal(J)$ in _top-down traversal_ order in the TFDP:
      + *for each* action $a in A_j$:
        + *if* $p_j = emptyset$:
          + $x^((t))[j a] arrow.l b_j^((t))[a]$
        + *else*:
          + $x^((t))[j a] arrow.l x^((t))[p_j] dot b_j^((t))[a]$
    - _You should convince yourself that the vector $x^((t))$ we just filled in above is a valid sequence-form strategy, that is, it satisfies the required consistency constraints we saw in Lecture 7. In symbols, $x^((t)) in cal(Q)$._
    + *return* $x^((t))$
  + *function ObserveUtility($g^((t)) in RR^(abs(Sigma))$)*
    - _Step 1: we compute the expected utility for each subtree rooted at each node $v in cal(J) union cal(K)$._
    + $V^((t)) arrow.l$ empty dictionary. _Eventually, it will map keys $cal(J) union cal(K) union {bot}$ to real numbers._
    + $V^((t))[bot] arrow.l 0$
    + *for each* node in the tree $v in cal(J) union cal(K)$ in _bottom-up traversal_ order in the TFDP:
      + *if* $v in cal(J)$:
        + Let $j arrow.l v$.
        + $V^((t))[j] arrow.l sum_(a in A_j) b_j^((t))[a] dot (g^((t))[j a] + V^((t))[rho(j, a)])$
      + *else*:
        + Let $k arrow.l v$.
        + $V^((t))[k] arrow.l sum_(s in S_k) V^((t))[rho(k, s)]$
    - _Step 2: at each decision point $j in cal(J)$, we now construct a local utility vector $g_j^((t))$ called counterfactual utility._
    + *for each* decision point $j in cal(J)$:
      + $g_j^((t)) arrow.l 0 in RR^(A_j)$
      + *for each* action $a in A_j$:
        + $g_j^((t))[a] arrow.l g^((t))[j a] + V^((t))[rho(j, a)]$
      + $R_j."ObserveUtility"(g_j^((t)))$
] <algo:cfr>

== Learning using self-play

The CFR algorithm can be used to learn a Nash equilibrium in a two-player zero-sum game by letting two regret minimizers play against each other. The two regret minimizers exchange their sequence-form strategies at every iteration according to the canonical learning setup.

= Bibliography for this lecture

#lec_bibliography("meta/refs.bib", title: none)

#changelog[
  - 2025-10-09: Fixed typos (thanks Josh Rountree!).
]
