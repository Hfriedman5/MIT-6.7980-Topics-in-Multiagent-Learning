// Port of Lectures/content/perfection.tex; authoritative Fall 2025 source.
#import "../meta/gabri_notes_bk.typ": *
#show: gabri_notes.with(lec_num: "S4", date: [Fall 2026], title: [Sequential irrationality and perfect equilibria], instructor: [Prof. Gabriele Farina (#raw("gfarina@mit.edu"))])

As we discussed on multiple occasions, Nash equilibrium strategies encode the idea of playing optimally against the strongest possible opponent. Even when the opponent is only close to optimal (for example, in the poker competitions where the opponent were top professional poker players), playing a Nash equilibrium is often the safe choice, as professional players are very quick at exploiting suboptimal strategies, making opponent modeling risky. However, as we reveal today, not all Nash equilibria are equally strong in extensive-form games when playing against players that might make mistakes.

= Sequential irrationality

Nash equilibrium strategies are only optimized for the strongest possible opponent. Because of that, they are completely indifferent to what happens in parts of the game tree that are reached only if a player makes a mistake.

#example[
To make the discussion more concrete, consider the #emph[Guess-the-Ace] game, introduced by~#citet(label("Miltersen06:Computing")).

#align(center)[
    #image("../figures/L12/guess-the-ace.svg", width: 100.0%)
  ]
]#label("ex:guess-the-ace")

In Guess-the-Ace, at the start a standard 52-card deck is perfectly shuffled, face down, by a dealer. Then, Player~$1$ can decide whether to immediately end the game, at which point no money is transferred between the players, or offer \$1000 to Player~$2$ if they can correctly guess whether the top card of the shuffled deck is the ace of spaces or not. If Player~$2$ guesses correctly, the \$1000 get transferred from Player~$1$ to Player~$2$; if not, no money is transferred. The game tree is summarized in #ref(label("ex:guess-the-ace")).

Clearly, the only Nash equilibrium strategy for Player~$1$ is to quit immediately, or they are guaranteed to #emph[lose] money. Since Player~$2$ does not get to play, any strategy for Player~$2$ is a Nash equilibrium strategy.

In particular, both highlighted equilibria in #ref(label("ex:guess-the-ace")) are Nash equilibria. However, the two equilibria are significantly different from a practical point of view. Imagine that Player~$2$ is a bot playing against opponents in the real world, blindly following the Nash equilibrium strategy it has precomputed. If Player~$1$ makes a mistake and decides to offer the \$1000 instead of immediately quitting, the Nash equilibrium that bets that the top card is #emph[not] the ace of space has an expected utility of $>$ \$980 whereas the Nash equilibrium that bets that the top card is the ace of spade only has an expected utility of $<$ \$20.

So, while both strategy profiles in #ref(label("ex:guess-the-ace")) are Nash equilibria, only one of the two is #emph[“sensible”].

Formalizing this subtle notion of rationality within the set of Nash equilibria has been a major endeavor for the game-theoretic literature in the 70s and 80s. Today, we say that the equilibrium in #ref(label("ex:guess-the-ace")) (Left) is #emph[sequentially irrational], while the one on the right is #emph[sequentially rational].  The takeaway lesson is:

#remark[
Not all Nash equilibria are equally “good” when the agents can make mistakes. Specifically, sequentially-irrational Nash equilibria might leave value on the table, by being incapable of capitalizing on opponents' mistakes.
]

The goal of this lecture is to investigate how one can rule out sequential irrationality and compute a sequentially-rational Nash equilibrium in a two-player zero-sum imperfect-information game.

= Undomination is not the solution
#label("sec:une")

One might believe that the problem of sequential irrationality is that of picking dominated strategies. So, one might be inclined to look into the problem of finding a Nash equilibrium whose support does not include any (weakly) dominated strategy (the concept is not immediately well defined, but for the purposes of this discussion let's restrict ourselves to Nash equilibria in deterministic strategies).

Unfortunately, domination of strategies is not the root cause of sequential irrationality, and therefore undomination is not its solution. Indeed, as much as undomination #emph[does] get rid of the undesirable behavior of #ref(label("ex:guess-the-ace")) (Right), since action \`A$suit.spade.filled$' is strictly dominated by action \`$not$A$suit.spade.filled$', it does not prevent sequential irrationality in more complex settings, such as #ref(label("ex:guess-the-ace-x")).

#example[
#wrapped-figure(
  [
Undomination does #emph[not] prevent a player from playing risky actions, hoping for an opponent's mistake. In this example, again due to #citet(label("Miltersen06:Computing")), the Guess-the-Ace game is slightly modified in that, when Player~$2$ guesses wrong, Player~$1$ can decide whether they still want to give \$1000 to Player~$2$ out of the kindness of their heart or not. By introducing that possibility, action \`$not$A$suit.spade.filled$' is not strictly dominating anymore, because Player~$2$ might still hope that the second gift of \$1000 is given only when the insensible guess \`A$suit.spade.filled$' is made.
  ],
  [#image("../figures/L12/guess-the-ace-x.svg", width: 200pt)],
  side: right,
  text-width: 65%,
)
]#label("ex:guess-the-ace-x")

= Trembling-hand refinements

The issue of sequential irrationality stems from the fact that some parts of the game tree are unreachable at equilibrium. For those excluded parts of the game tree, any strategy can be picked without affecting the equilibrium.  The idea behind trembling-hand refinements is simple: to avoid sequential irrationality, it forces all players to explore the whole game tree. It does so by forcing the players to #emph[tremble], that is, by constraining them to play all actions at all decision points with a strictly positive lower bound probability that grows as a function of a hyperparameter $epsilon.alt > 0$. For each $epsilon.alt > 0$, a Nash equilibrium subject to the trembling constraints is found. A trembling-hand refinements is then any limit points of such Nash equilibria as $epsilon.alt arrow.r 0^(+)$.

Different equilibrium notions differ as to how the lower bounds are set as a function of $epsilon.alt$. We will see two, which are the two best known: extensive-form perfect equilibrium and quasi-perfect equilibrium.

== Extensive-form perfect equilibrium (EFPE)

#emph[Extensive-form perfect equilibrium (EFPE)], due to #citet(label("Selten75:Reexamination")), is conceptually the simplest of the two. In an EFPE, the trembles are #emph[behavioral]: given $epsilon.alt > 0$, the perturbed game simply mandates that every action at every decision point must be picked with probability at least $epsilon.alt$.

Since our game solving formalism is based around the sequence-form representation of strategies, it is important to check that those behavioral trembling constraints can be expressed in the sequence form. That is the case: asking that action $a$ at decision point $j$ of Player~$1$ be selected with probability at least $epsilon.alt$ corresponds to the sequence-form constraint

#math.equation(block: true, numbering: "(1)", $x_(j a) gt.eq cases(delim: "{", epsilon.alt & upright("if ") p_j = ∅, epsilon.alt dot.op x_(p_j) & upright("otherwise") .)$.body)#label("eq:efpe constraint")

Collecting all sequence-form trembling constraints (#ref(label("eq:efpe constraint"))) constraints across all decision points $j in J$ and actions $a in A_j$ of Player~$1$, we can express the whole set of trembling constraints in matrix form as $M_1 \( epsilon.alt \) x gt.eq m_1 \( epsilon.alt \)$. (An analogous statement holds for Player~$2$). So, given any $epsilon.alt > 0$, and indicating with $F_1 x = f_1 \, x gt.eq 0$ and $F_2 y = f_2 \, y gt.eq 0$ the polytope of sequence form strategies of Player 1 and Player 2 respectively, a Nash equilibrium strategy for Player~$1$ under the trembling constraints can be expressed as the saddle point problem

#math.equation(block: true, numbering: "(1)", $cases(max_x min_y x^top U_1 y, upright("s.t.") upright("①") thin F_2 y = f_2, upright("") upright("②") thin M_2 \( epsilon.alt \) y gt.eq m_2 \( epsilon.alt \), upright("") upright("③") thin F_1 y = f_1, upright("") upright("④") thin M_1 \( epsilon.alt \) x gt.eq m_1 \( epsilon.alt \) .)$.body)#label("eq:efpe")

We will look into how to compute a limit point of solutions to #ref(label("eq:efpe")) as $epsilon.alt arrow.r 0^(+)$ in #ref(label("sec:trembling-lp")).

== Quasi-perfect equilibrium (QPE)

#emph[Quasi-perfected equilibrium (QPE)], introduced by #citet(label("vanDamme84:relation")), is a bit more intricate than EFPE.  Specifically, while in an EFPE each trembling constraints mandates a lower bound of $epsilon.alt$ on the probability of playing each #emph[action], in the case of a QPE the lower bounds are given on the probability of each #emph[sequence] of actions.  More precisely, for any $epsilon.alt > 0$ and player $i in { 1 \, 2 }$, let $ell_i : bb(R)_(> 0) arrow.r bb(R)_(> 0)^(Sigma_i)$ denote the vector parametrized on $epsilon.alt$ and indexed on the sequences $Sigma_i$ of Player~$i$, whose entries are defined as

#math.equation(block: true, numbering: "(1)", $ell_(i \, sigma) \( epsilon.alt \) = epsilon.alt^(\| sigma \|) #h(2em) forall sigma in Sigma_i \,$.body)#label("eq:ms-ell")

where $\| sigma \|$ denotes the number of actions for Player~$i$ in the sequence $sigma$. #citet(label("Miltersen10:Computing")) proved that any limit point of the solution to the perturbed optimization problem

#math.equation(block: true, numbering: "(1)", $cases(max_x min_y x^top U_1 y, upright("s.t.") upright("①") thin F_2 y = f_2, upright("") upright("②") thin y gt.eq ell_2 \( epsilon.alt \), upright("") upright("③") thin F_1 y = f_1, upright("") upright("④") thin x gt.eq ell_1 \( epsilon.alt \))$.body)#label("eq:qpe")

is a QPE. (Recently, #citet(label("Gatti20:Characterization")) took this construction further, and showed that #emph[any] QPE can be expressed as a limit point of solutions to #ref(label("eq:qpe")), as long as more general vectors of polynomials $ell_1 \, ell_2$ are used than in (#ref(label("eq:ms-ell"))). In this paper we will focus on Miltersen-Sørensen-style perturbation as defined in (#ref(label("eq:ms-ell"))).)

Once again, we will discuss how to compute a limit point of solutions to #ref(label("eq:qpe")) as $epsilon.alt arrow.r 0^(+)$ in #ref(label("sec:trembling-lp")).

== Relationships between the equilibria

We already know from #ref(label("sec:une")) that undomination does not imply sequential rationality. Interestingly, the converse also is not true in general. So, undomination and sequential rationality are actually incomparable concepts, in the sense that neither implies the other.

At this point, one might naturally wonder whether a refinement that is both undominated and sequentially-rational can be devised. The answer is yes: a nice property of QPE is that not only it is sequentially rational, but it is also undominated! The same cannot be said of EFPE. So, as #citet(label("Mertens95:Two")) noted, a #emph[quasi-perfect equilibrium] is nowadays considered superior to EFCE.

#quote(block: true)[
  « Observe that the “quasi-perfect” equilibria $\[$..$\]$ are still sequential---and sequential equilibria have all backward-induction properties (#emph[e.g.], Kohlberg and Mertens, 1986)---but are at the same time normal form perfect---which can be viewed as the strong version of undominated. (And every proper equilibrium is quasi-perfect.) Thus, by some irony of terminology, the “quasi”-concept seems in fact far superior to the original unqualified perfection itself. »

   (from #citet(label("Mertens95:Two")))
]

The relationships among the different refinements is summarized in the Venn diagram of #ref(label("fig:refinements")).

#figure(caption: [Relationships between the different Nash equilibrium refinements])[
#image("../figures/L12/venn.svg", width: 60.0%)
]#label("fig:refinements")

== Computational complexity

Perhaps surprisingly, finding an EFPE or a QPE in a two-player game is not harder than finding a Nash equilibrium. In particular, in zero-sum games, an EFPE and a QPE can be found in polynomial time in the size of the input game. #ref(label("tab:complexity")) summarizes the computational complexity of computing the Nash equilibrium refinements mentioned so far in two-player games.

#figure(kind: table, supplement: [Table], caption: [Complexity of computing different Nash equilibrium refinements in two-player games.])[

#table(stroke: none, columns: 3, align: left+top, inset: .7em,
table.header([#strong[Solution concept]], [#strong[General-sum]], [#strong[Zero-sum]]),
[Nash equilibrium (NE)],
[PPAD-complete #citep(label("Daskalakis09:Complexity"))],
[FP #citep(label("Romanovskii62:Reduction"), label("Stengel96:Efficient"))],
[Subgame perfect equilibrium (SPE)],
[PPAD-complete],
[FP],
[Quasi perfect equilibrium (QPE)],
[PPAD-complete #citep(label("Miltersen10:Computing"))],
[FP #citep(label("Miltersen10:Computing"))],
[Extensive-form perfect equilibrium (EFPE)],
[PPAD-complete #citep(label("Farina17:Extensive"))],
[FP #citep(label("Farina17:Extensive"))]
)
]#label("tab:complexity")

= Trembling linear programs and computation of QPE and EFPE

#label("sec:trembling-lp")

We can compute a limit point of solutions to #ref(label("eq:efpe")) and #ref(label("eq:qpe")) using the same machinery. As a first step, just like what we did for the Nash equilibrium, we convert the bilinear saddle-point formulations #ref(label("eq:efpe")), #ref(label("eq:qpe")) into linear programs by dualizing the internal minimization problems. This gives us a linear program where the constraints matrix and the objective function depend polynomially on $epsilon.alt$. In particular, for both QPE and EFPE we end up with a linear program of the form

$ P \( epsilon.alt \) : {max_x &  & c \( epsilon.alt \)^top x\
upright("s.t.") &  & A \( epsilon.alt \) x = b \( epsilon.alt \)\
upright("") &  & x gt.eq 0 . $

where $c \, A$ and $b$ are #emph[polynomial] functions of $epsilon.alt$ with rational coefficients.  We will call an object of that form a #emph[trembling linear program (TLP)], and a limit point of solutions to $P \( epsilon.alt \)$ as $epsilon.alt arrow.r 0^(+)$ a #emph[limit solution] of the TLP.  With this formalism, we can reframe the computation of an EFPE or a QPE as the problem of finding a limit solution to their corresponding TLPs.

We will now discuss the complexity of solving a TLP, and two different computational approaches. Both of them are based on the concept of #emph[basis stability] (Recall that a #emph[basis] of an LP is a subset of the program's variables such that when only those columns of matrix $A$ that correspond to those variables are included in a new matrix $A$, the new matrix $A$ is invertible #citep(label("Bertsimas97:Introduction") , [page 55]).

#definition[Stable basis][
Let $P \( epsilon.alt \)$ be a TLP. The LP basis $B$ is said to be #emph[stable] if there exists $macron(epsilon.alt) > 0$ such that $B$ is optimal for $P \( epsilon.alt \)$ for all $epsilon.alt : 0 < epsilon.alt lt.eq macron(epsilon.alt)$.
]#label("def:stable-basis")

If a stable basis were to be found, from there a limit solution of $P \( epsilon.alt \)$ could be computed in polynomial time. As it turns out, a stable basis always exists, and can be computed in polynomial time.

== Negligible Positive Perturbations (NPP)

#label("sec:npp")

#citet(label("Farina18:Practical")), extending prior work by #citet(label("Miltersen10:Computing")) and #citet(label("Farina17:Extensive")), showed the following.

#theorem[#citet(label("Farina18:Practical"))][
Given as input a TLP $P \( epsilon.alt \)$, there exists $epsilon.alt^(*) > 0$---called a #emph[negligible positive perturnation (NPP)]---such that for all $0 < macron(epsilon.alt) lt.eq epsilon.alt^(*)$, any optimal basis for the numerical LP $P (macron(epsilon.alt))$ is stable. Furthermore, such a value $epsilon.alt^(*)$ can be computed in polynomial time in the input size, assuming that a polynomial of degree $d$ requires $Omega \( d \)$ space in the input.#footnote[If this were not the case, evaluating a polynomial in an integer $n$ would not be an efficient operation, since it requires $Omega (d log n)$ bits to represent the output.]
]#label("thm:npp")

So, at least in principle, a solution to a TLP $P \( epsilon.alt \)$ could be computed as follows: 

#list(
[
First, compute the value of the NPP $epsilon.alt^(*)$ using the constructive proof of #ref(label("thm:npp")).
],
[
Then, solve the numerical linear program $P (epsilon.alt^(*))$ to optimality. Since the bit complexity of $epsilon.alt^(*)$ is polynomial in the size of the TLP, the numerical LP can be solved to optimality in polynomial time, and a basis $B$ can be extracted. From #ref(label("thm:npp")), such a basis is stable (#ref(label("def:stable-basis"))).
],
[
Finally, extract the limit solution to the TLP from the stable basis.
]
)

The algorithm just described has polynomial complexity in the TLP size. In the case of the TLP arising form QPE and EFPE, that translates into a polynomial-time algorithm to find an exact EFPE and QPE in a two-player zero-sum game (see also #ref(label("tab:complexity"))).

== A significantly more scalable approach

While technically polynomial, the NPP-based algorithm described in the previous subsection is mostly of conceptual interest. In practice, because the value of the NPP is so small, any linear programming solver that wants to have a chance at solving the numerical linear program $P (epsilon.alt^(*))$ must---as a minimum---use rational arithmetic, rendering the algorithm extremely slow.

A significantly more scalable algorithm for solving TLPs, due to~#citet(label("Farina18:Practical")), avoids the pessimistically small numerical NPP $epsilon.alt^(*)$ of #ref(label("thm:npp")) by using an efficient stability-checking oracle for checking if a basis is stable or not.

The iterative algorithm repeatedly picks a numerical perturbation $macron(epsilon.alt)$, computes an optimal basis for the perturbed LP $P (macron(epsilon.alt))$, and queries the basis-stability oracle. If the basis is not stable, the algorithm concludes that the perturbation value $macron(epsilon.alt)$ was too optimistic, and a new iteration is performed with a smaller perturbation reduced by a multiplicative constant (for example, divide it by $upright("1000")$). On the other hand, if the basis is stable, the algorithm takes the limit of the LP solution and returns it as the limit solution of the TLP. Correctness and termination are guaranteed by the following observation.

#remark[
Any value of $macron(epsilon.alt)$ in the range $lr((0 \, epsilon.alt^(*)])$ guarantees termination of the algorithm. Indeed, by #ref(label("thm:npp")), any optimal basis for $P (macron(epsilon.alt))$ is stable and makes our iterative algorithm terminate. Furthermore, if after every negative stability test the value of $macron(epsilon.alt)$ is reduced by a constant multiplicative factor (#emph[e.g.], halved), then since $epsilon.alt^(*)$ only has a polynomial number of bits, the algorithm terminates after trying at most a polynomial number of different values for $macron(epsilon.alt)$.
]

The practical algorithm is 3-4 orders of magnitude faster than the conceptual algorithm described in #ref(label("sec:npp")), and is the current state-of-the-art algorithm for computing QPE and EFPE.

= Bibliography for this lecture

#lec_bibliography("../meta/refs.bib", title: none)

#appendix[
= Why not uniform lower bounds in QPE?

Not all vanishing perturbations $ell_1 \( epsilon.alt \) \, ell_2 \( epsilon.alt \)$ in the QPE
formulation #ref(label("eq:qpe")) lead to a sequentially-rational
equilibrium.
For example, it is natural to wonder whether it is #emph[really] necessary
to consider lower bounds of the form $epsilon.alt^sigma$ instead of,
for example, the uniform lower bound $epsilon.alt$ for all sequences.
After all, 

surely a
uniform lower bound of $epsilon.alt$ would still force the whole game to be
explored, wouldn't it?
While appealing on the surface, such a uniform lower
bound might result in a solution that is not even subgame perfect, much less
sequentially rational!

We illustrate this point with an example.

#example[
Consider the following simple game, and the strategy specified on the right, which is parameteric in $epsilon.alt gt.eq 0$.

#align(center)[
    #image("../figures/L12/uniform.svg", width: 100.0%)
  ]
]

For any choice of $epsilon.alt in \[ 0 \, 1 \/ 4 \]$, we now argue that the only Nash equilibrium of the perturbed
game assigns probability $1 - epsilon.alt$ to action #raw("r") of Player~$2$, and
probability $1 \/ 2$ to actions #raw("c") and #raw("d") of Player~$1$.
Indeed, action #raw("a") strictly dominates #raw("b"), since all payoffs for the black player (Player~$1$) are strictly lower in the subtree rooted at #raw("b"). Hence, the black player must minimize the probability mass put on the sequences that contain action #raw("b"), compatibly with lower bounds. Because we are using uniform lower bounds $epsilon.alt$ on the probability of each sequence, the black player will need to put at least probability $epsilon.alt$ on the four sequences #raw("bc"), #raw("bd"), #raw("bp"), #raw("bq"). This can be achieved when #raw("c"), #raw("d"), #raw("p"), #raw("q") are each selected with probability $1 \/ 2$ and action #raw("b") with probability $4 epsilon.alt$. From the point of view of the white player (Player 2), information set #raw("C") guarantees an expected utility of $- 1 dot.op 1 \/ 2 + 2 dot.op 1 \/ 2 = 1 \/ 2$, while information set #raw("D") guarantees and expected utility of $0$. So, it is rational for the white player to put as much probability mass as allowed by the lower bounds to action #raw("r"). This is achieved when action #raw("r") is selected with probability $1 - epsilon.alt$, and action $s$ with probability $epsilon.alt$.

So, as $epsilon.alt arrow.r 0^(+)$, any limit point sees Player~$2$ pick
action #raw("r") with probability $1$ and Player~$1$ randomizing uniformly
between actions #raw("c") and #raw("d"), despite action #raw("d") being strictly
dominated.
Thus, both players will act irrationally (with Player~$1$ not even playing a
best response in the subtree rooted at #raw("C")) should Player~$1$ make
the mistake of picking action #raw("b") instead of #raw("a") at the root
#raw("A").
The resulting equilibrium is not sequentially rational. (In fact, it's not even subgame perfect, which is even stronger #citep(label("Kreps82:Sequential")).)
]
