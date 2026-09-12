// Follows Farina's January 2026 SIGecom Exchanges article.
// The CCE motivation also draws on Fall 2024 Lectures/L15/L15.typ.
#import "meta/gabri_notes.typ": *

#show: gabri_notes.with(
  lec_num: "S7",
  date: [Fall 2026],
  title: "Fast computation via the minimax theorem",
  instructor: [Prof. Gabriele Farina],
)

The minimax theorem converts a response to each opponent strategy into a single strategy that works against every opponent. How many responses must we compute to carry out this conversion? This lecture follows #citet(<farina2026defense>), with particular attention to computing $Phi$-equilibria. The central tool is a generalization of Ellipsoid-Against-Hope: select a small collection of responses, then compute a suitable mixture of them.

The supplementary reading _A second look at the minimax theorem_ introduces the coarse correlated equilibrium application. Here we develop the precision guarantee and the fixed-point construction that extends the method to richer deviations. Familiarity with minimax, regret minimization, and linear programming duality is useful; _Phi-regret minimization_ provides complementary background.

= From responses to a uniform guarantee

Let $X subset.eq RR^d$ be a nonempty compact convex set. The opponent chooses $x in X$ and minimizes a payoff $f(x,y)$; we choose $y in Y$ and maximize it. Assume $Y$ is convex and $f$ is affine in each argument. For example, $f(x,y)=x^T A y$ is bilinear. Affine terms can be included by adding a constant coordinate. We assume that payoffs are bounded on the relevant domains.

#definition[Defense oracle][
  A defense oracle at level $v$ returns, for each $x in X$, a strategy $h(x) in Y$ satisfying
  $ f(x,h(x)) >= v. $
  A strategy $y^(*)$ provides an $epsilon.alt$-approximate uniform guarantee if
  $ f(x,y^(*)) >= v-epsilon.alt quad forall x in X. $
]

The oracle may be discontinuous, and it need not return a best response. It only has to reach the specified threshold. The algorithm needs the returned strategy and the coefficients of the affine function $f(dot,y)$, so that its separating hyperplane can be evaluated. It need not enumerate, separate over, or optimize over the full set $Y$.

Minimax says that a uniform guarantee exists when a defense oracle exists. The computational question is to construct it using few oracle calls. With fixed dimension and geometric parameters, we will obtain a number of calls proportional to $log(1/epsilon.alt)$. This measures dependence on precision; it does not assert a dimension-independent running time.

== A learning-based construction

Simulate an opponent with a regret bound for linear losses. At round $t$, let it choose $x_t$, return $y_t=h(x_t)$, and give it loss $f(dot,y_t)$. Its regret is
$ R_T=sum_(t=1)^T f(x_t,y_t)-min_(x in X) sum_(t=1)^T f(x,y_t). $
For $macron(y)=T^(-1) sum_t y_t$, affinity gives
$ min_(x in X) f(x,macron(y))
  =frac(1,T) sum_(t=1)^T f(x_t,y_t)-frac(R_T,T)
  >=v-frac(R_T,T). $
In particular, $R_T<=C sqrt(T)$ gives accuracy $epsilon.alt$ after $T>=C^2/epsilon.alt^2$ calls. This is a useful constructive argument, but each additional bit of accuracy multiplies the iteration budget. The fast construction changes both the queried opponent strategies and the final mixture weights.

= Collecting a finite certificate

Fix an accuracy parameter $eta>0$. After collecting responses $y_1,...,y_T$, define the opponent's remaining feasible set
$ P_T={x in X : f(x,y_t)<=v-eta/2 quad forall t=1,...,T}. $
Initially there are no response constraints, so $P_0=X$. Every point of $X$ fails at least one of the infinitely many possible constraints: its own defense response has payoff at least $v$. The ellipsoid method finds a small collection of constraints that is sufficient for our accuracy target.

#figure(kind: "algorithm", supplement: [Algorithm], caption: [Collecting defense responses. All separating cuts are represented in the affine hull of X.])[
  #pseudocode-list(booktabs: true, max-width: true, numbered-title: [Fast minimax construction])[
    + Start with an ellipsoid containing $X$ and an empty response list.
    + *While* its volume exceeds the threshold specified below:
      + Let $c_t$ be the current ellipsoid center.
      + If $c_t in.not X$, obtain a separating cut for $X$.
      + Otherwise, query $y_t=h(c_t)$ and save $y_t$ and $f(dot,y_t)$.
      + In this second case, use the central cut $f(x,y_t)<=f(c_t,y_t)$.
      + Replace the ellipsoid by the usual ellipsoid enclosing the retained half.
    + Compute weights $lambda in Delta(T)$ maximizing $min_(x in X) sum_t lambda_t f(x,y_t)$ to the required accuracy.
    + Return the mixture $y^(*)=sum_t lambda_t y_t$.
  ]
]

Here $T$ counts saved responses, which can be fewer than the ellipsoid iterations. The oracle is called only at centers belonging to $X$. Since $f(c_t,y_t)>=v$, the response cut retains all of $P_t$. Cuts separating $X$ also retain it. Thus, the final ellipsoid contains $P_T$. If $f(dot,y_t)$ is constant, this response already guarantees at least $v$ everywhere and we can stop immediately.

== Why small volume gives an accuracy guarantee

Small volume alone does not prove that a convex set is empty: a point has zero volume. We therefore prove a quantitative implication using the slack $eta/2$.

Work in the $d$-dimensional affine hull of $X$, and suppose known radii satisfy
$ B(c,r) subset.eq X subset.eq B(c,R), quad 0<r<=R. $
Suppose every response payoff $f(dot,y_t)$ is $L$-Lipschitz in these coordinates, with $L>0$, and $0<eta<=L R$. A zero-dimensional domain requires just one oracle call; a zero Lipschitz bound means that every response payoff is constant.

#lemma[Thickness from slack][
  If some $x^(*) in X$ satisfies $f(x^(*),y_t)<=v-eta$ for every saved response, then $P_T$ contains a ball of radius
  $ rho=frac(r eta,4L R). $
]
#proof[
  Set $delta=eta/(4L R)$ and $z=(1-delta)x^(*)+delta c$. Convexity and the inner ball imply $B(z,delta r) subset.eq X$. Every point $w$ of this ball satisfies
  $ norm(w-x^(*))<=delta norm(c-x^(*))+delta r<=2delta R. $
  Lipschitz continuity gives $f(w,y_t)<=f(x^(*),y_t)+2L delta R<=v-eta/2$ for every $t$, so the whole ball belongs to $P_T$.
]

A central-cut ellipsoid update reduces volume by a factor at most $exp(-1/(2(d+1)))$ for $d>=2$; in dimension one, bisect the interval. Starting with radius $R$, after
$ K=O(d^2 log(R/rho))=O(d^2 log(frac(4L R^2,r eta))) $
updates the containing ellipsoid has volume less than a ball of radius $rho$. The lemma rules out any $x^(*)$ satisfying all the stronger inequalities. Hence
$ min_(x in X) max_(t=1,...,T) f(x,y_t)>v-eta. $
The minimum is attained because $X$ is compact. This is the finite certificate we need. A rational implementation uses the standard finite-precision ellipsoid machinery and appropriate encoding bounds; the calculation above describes its geometric core.

== Recovering the mixture

Write $a=v-eta$ and consider the compact convex payoff image
$ C={ (f(x,y_1),...,f(x,y_T)) : x in X } subset.eq RR^T. $
The certificate says that $C$ is disjoint from $Q={q in RR^T:q_t<=a " for every " t}$. Strong separation gives a nonzero vector $lambda$ with
$ inf_(q in C) ip(lambda,q)>sup_(q in Q) ip(lambda,q). $
The right side is finite only if every $lambda_t>=0$, because $Q$ is unbounded in each negative coordinate direction. Normalize so that $sum_t lambda_t=1$. The supremum then equals $a$, proving
$ min_(x in X) sum_t lambda_t f(x,y_t)>v-eta. $
This argument uses separation in a finite-dimensional payoff space; it supplies the quantifier exchange rather than assuming the minimax theorem we are constructing.

Computationally, solve
$ max_(lambda in Delta(T),z in RR) z quad "subject to" quad
  z<=sum_t lambda_t f(x,y_t) quad forall x in X. $
A linear-optimization oracle for $X$ separates these constraints: minimize the right side and either return a violating $x$ or certify feasibility. For rational polytopes this is an LP with oracle access. More generally, standard well-bounded convex optimization gives approximate weights under the corresponding oracle and precision assumptions. Optimizing to additive error $eta$ yields a guarantee of at least $v-2eta$. Set $eta=epsilon.alt/2$.

Thus, the number of defense calls is at most $O(d^2 log(8L R^2/(r epsilon.alt)))$. Total running time also includes separation over $X$, recovery of the weights, encoding lengths, and oracle costs. The output is stored as a list of responses with weights. Uniform averaging has no such guarantee for the ellipsoid's responses.

= A mediator game for Phi-equilibria

Consider an $n$-player game with compact convex strategy sets $S_i$ and utilities $u_i$ that are affine in each player's strategy. Player $i$ has a family $Phi_i$ of allowed maps from $S_i$ to itself. A mediator draws a profile $s$ from a joint distribution $mu$ and privately recommends $s_i$ to player $i$.

#definition[Phi-equilibrium][
  The distribution $mu$ is an $epsilon.alt$-$Phi$-equilibrium if
  $ EE_(s tilde.op mu)[u_i (phi_i (s_i),s_(-i))-u_i (s)]<=epsilon.alt $
  for every player $i$ and every $phi_i in Phi_i$. Setting $epsilon.alt=0$ gives an exact $Phi$-equilibrium.
]

The opponent of the mediator selects a distribution $nu$ over pairs $(i,phi_i)$. Its payoff is the expected deviation gain
$ G(mu,nu)=EE_((i,phi_i) tilde.op nu) EE_(s tilde.op mu)
  [u_i (phi_i (s_i),s_(-i))-u_i (s)]. $
Use $f(nu,mu)=-G(mu,nu)$ in our minimax construction, with $v=0$. A uniform guarantee $f(nu,mu)>=-epsilon.alt$ is exactly the equilibrium condition, since the opponent can concentrate on any one deviation. The mediator's strategy space can be enormous. We will only construct responses to particular $nu$.

== A defense oracle from fixed points

Suppose each $Phi_i$ is a compact family of affine self-maps, and we can compute fixed points of their convex combinations. Let
$ w_i=Pr_((j,phi_j) tilde.op nu)[j=i]. $
If $w_i>0$, let $nu_i$ be the conditional distribution of deviations given player $i$, and define the mean transformation
$ macron(phi)_i=EE_(phi_i tilde.op nu_i)[phi_i]. $
It maps $S_i$ into itself by convexity. Choose $s_i$ satisfying $macron(phi)_i (s_i)=s_i$. If $w_i=0$, choose any $s_i in S_i$. Return the point distribution $mu=delta_s$ on the resulting profile.

#theorem[Fixed points give a defense response][
  This construction has $G(delta_s,nu)=0$.
]
#proof[
  By affinity in player $i$'s own strategy, each term with $w_i>0$ satisfies
  $ EE_(phi_i tilde.op nu_i)[u_i (phi_i (s_i),s_(-i))]
    =u_i (macron(phi)_i (s_i),s_(-i))=u_i (s). $
  Sum with weights $w_i$; zero-weight terms contribute nothing.
]

Notice what this proves: the weighted deviation chosen by this particular opponent has zero gain. Other deviations may still be profitable. The final mixture of defense responses is what enforces all deviations simultaneously.

For a rational polytope $S_i$ and an affine map $phi_i (s_i)=M_i s_i+b_i$, finding a fixed point is linear feasibility:
$ s_i in S_i, quad (I-M_i)s_i=b_i. $
Existence follows from the fixed-point theorem for continuous self-maps of compact convex sets. Computing this affine fixed point is an LP task. A general nonlinear map would require a separate computational argument.

== Coarse correlated equilibria

Take $Phi_i$ to be the constant maps $s_i mapsto a_i$ for $a_i in S_i$. The mean map is constant too, so its fixed point is simply
$ s_i=EE_(a_i tilde.op nu_i)[a_i] quad "when" quad w_i>0. $
For a finite normal-form game, write $nu_(i,a)$ for the mass of deviation to action $a$. The response is the product distribution with marginals
$ p_i (a)=frac(nu_(i,a),w_i), quad w_i=sum_a nu_(i,a). $
Choose any marginal when $w_i=0$. This is the normalized Hart--Schmeidler construction from the earlier supplement and the archived Fall 2024 Lecture 15. It avoids allocating a variable to every joint action. A final mixture of these product distributions is generally correlated.

== Correlated equilibria: stationary distributions

For normal-form player $i$ with $m_i$ actions, every deterministic deviation from a recommendation is a map on those actions. Its linear extension to $Delta(m_i)$ is a matrix with one unit-vector column per action. The convex hull of these maps is the set of column-stochastic matrices $Q_i$. For the conditional mean deviation, the fixed-point equation is
$ Q_i p_i=p_i, quad p_i>=0, quad sum_a p_i (a)=1. $
It is the stationary-distribution equation for a finite Markov chain. A solution exists even when the chain is reducible; uniqueness is unnecessary. Given opponents' marginals, set $v_i (a)=u_i (a,p_(-i))$. Then
$ sum_(a,b) p_i (a) (Q_i)_(b a) [v_i (b)-v_i (a)]
  =v_i^T (Q_i p_i-p_i)=0. $
Thus, stationary distributions supply a defense response without solving for a Nash equilibrium.

There are $m_i^(m_i)$ deterministic deviation maps, but the opponent does not need a coordinate for each one. Introduce $B_i=w_i Q_i$ and describe its domain by
$ B_i>=0, quad sum_b (B_i)_(b a)=w_i quad forall a,
  quad w_i>=0, quad sum_i w_i=1. $
These are linear constraints in at most $n+sum_i m_i^2$ coordinates. If $w_i=0$, nonnegativity forces $B_i=0$. For a product response $p$, the cut coefficients are explicitly
$ G(p,B)=sum_i sum_(a,b) (B_i)_(b a) p_i (a)[v_i (b)-v_i (a)]. $
The final distribution can be sampled by choosing a saved response index $t$ with probability $lambda_t$, then sampling the actions independently from its marginals $p_(i,t)$.

#example[Retaining the common mixture index][
  Consider two players choosing $A$ or $B$, with utility one when they match and zero otherwise. Let $p^1$ put probability one on $(A,A)$ and let $p^2$ put probability one on $(B,B)$. Every mixture $mu=lambda p^1+(1-lambda)p^2$ is a CE. But multiplying its marginals yields mismatch probability $2lambda(1-lambda)$; for $lambda=3/4$, a player recommended $B$ strictly prefers switching to $A$. A mixture of product distributions must therefore retain its common mixture index. Its marginals alone do not encode its incentive guarantees.
]

= Polyhedral games and exact computation

For general affine deviation families, the same compact opponent representation uses the player masses $w_i$ and weighted map coefficients. Its dimension depends on the description of the transformations, not on the number of pure joint profiles. To apply the algorithm efficiently, verify:

- Each $S_i$ has an efficient separation oracle and known rational encoding or geometric bounds.
- The compact convex deviation domain has an efficient separation oracle in its coefficient representation, including the player weights.
- Fixed points of the mean deviations are efficiently computable.
- Given a response profile, all coefficients of its deviation-gain function are efficiently computable, with controlled encoding length. Multilinear utility gradients provide these coefficients for affine maps.

These are substantive assumptions. A compact game description by itself does not provide the required payoff or deviation oracles.

The exact result of #citet(<farina2024polynomial>) applies to rational polyhedral games with the polynomial utility-gradient property and a well-described, efficiently separable polytope of valid linear deviations. Under these assumptions, an exact $Phi$-equilibrium is computable in polynomial time. Their framework supplies the rational feasibility and certificate machinery beyond the approximate geometric argument above.

In a finite perfect-recall extensive-form game, sequence-form polytopes give compact strategy coordinates, and tree traversal computes utility gradients. With an appropriate efficiently represented family of linear deviations, this yields exact linear-deviation correlated equilibria. The family of deviations is part of the theorem's input: one must establish its oracle before claiming tractability for a particular equilibrium concept. A distribution over sequence-form profiles can be implemented by selecting a profile with the shared mixture index and then realizing each player's sequence-form strategy.

The approximate algorithm does not become exact by setting $epsilon.alt=0$, and rounding an arbitrary approximate equilibrium need not preserve incentives. Exact polynomial-time computation uses rational descriptions, bounds on certificate encoding lengths, and exact LP recovery. For nonpolyhedral domains the statement established here is an approximation guarantee under the stated geometry and oracle assumptions.

= Further reading

#citet(<farina2026defense>) also discusses expected variational inequalities and expected fixed points.

The classical Ellipsoid-Against-Hope algorithm and its refinements establish efficient CE computation in compact games #citep(<papadimitriou2008computing>, <jiang2011polynomial>).

The equilibrium existence argument goes back to #citet(<Hart89>). The present lecture combines that response viewpoint with explicit accuracy bookkeeping and the affine fixed-point reduction.

#lec_bibliography("meta/refs.bib", title: none)
