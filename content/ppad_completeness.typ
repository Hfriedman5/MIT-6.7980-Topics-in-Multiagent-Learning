// Adapted from the Fall 2024 Lecture 18 notes.
#import "meta/gabri_notes.typ": *

#let eps = math.epsilon.alt

#show: gabri_notes.with(
  lec_num: 20,
  date: [Tue, Nov 24, 2026],
  title: "PPAD-hardness of Nash equilibrium",
  instructor: [Prof. Constantinos Daskalakis],
  extrathanks: [Some of the content of the lecture was adapted from material from Costis Daskalakis.],
)

We continue the discussion from the lecture on total search and TFNP by giving a glimpse of how the PPAD-hardness of finding $eps$-approximate Nash equilibria was shown by #citet(<dgp09>).

The proof can be broken down into two main steps:
- Reduction from the End-of-the-line problem to (approximate) Brouwer.
- Reduction from (approximate) Brouwer to (approximate) Nash equilibria.

The first step is relatively easy, and we will not cover it here. The second step is more involved and requires a careful construction of a reduction from Brouwer to Nash equilibria. This is the part we will focus on in this lecture.

The key idea is the following: in the reduction from #smallcaps[End-of-the-line] to Brouwer, we define a continuous function $f$ for which we need to find an approximate fixed point. We now need to construct a game such that a Nash equilibrium of the game is the same as a fixed point of $f$ (up to approximations). The issue is that it is not clear how we can have games "compute" functions. Can we construct games in such a way that their behavior at Nash equilibria can be seen as "computing something"? The answer is positive, as we see next.

= Arithmetic Circuit SAT

We show that given a function represented as an _arithmetic circuit_, it is possible to construct a game whose Nash equilibria correspond to computing a fixed point of the function. This is the key idea behind the reduction from Brouwer to Nash equilibria.

In particular, we will restrict our attention to functions constructed through circuits that are composed of the following:
- Variable nodes $v_1, ..., v_n$;
- Gate nodes $g_1, ..., g_m$ of six possible types:
  #table(
    columns: (2.65cm, 2.85cm, 1fr),
    inset: (x: 2mm, y: 2.5mm),
    stroke: .2mm,
    align: horizon,
    table.header[*Gate*][*Symbol*][*Input-output relationship*],
    [Assignment], [#image("figures/ppad_completeness/gate_assignment.svg", width: 2.25cm, alt: "Assignment gate.")], [$y = x_1$],
    [Constant], [#image("figures/ppad_completeness/gate_constant.svg", width: 2.25cm, alt: "Constant gate.")], [$y=a$],
    [Addition], [#image("figures/ppad_completeness/gate_addition.svg", width: 2.25cm, alt: "Addition gate.")], [$y=min{1, x_1+x_2}$],
    [Subtraction], [#image("figures/ppad_completeness/gate_subtraction.svg", width: 2.25cm, alt: "Subtraction gate.")], [$y=max{0, x_1-x_2}$],
    [Multiplication], [#image("figures/ppad_completeness/gate_multiplication.svg", width: 2.25cm, alt: "Multiplication gate.")], [$y=max{0,min{1, a dot x_1}}$],
    [Comparison],
    [#image("figures/ppad_completeness/gate_comparison.svg", width: 2.25cm, alt: "Comparison gate.")],
    [$y=display(cases(1\, qquad& "if" x_1 > x_2,
    0\, & "if" x_1<x_2, "any"\, & "if" x_1 = x_2. ))$

      When the inputs are equal, this gate does not restrict the output.
    ],
  )
- Directed edges connecting variables to gates and gates to variables (loops are allowed);
- Variable nodes have in-degree 1; gates have 0, 1, or 2 inputs depending on type as above; gates & nodes have arbitrary fanout.

#definition[Arithmetic Circuit SAT problem][
  Given an arithmetic circuit satisfying the description above, output an assignment of values $v_1, ..., v_n in [0,1]$ that satisfies all the gates.
]

#example[
  Consider the following diagram.
  #figure[
#image("figures/ppad_completeness/circuit.svg", width: 5cm, alt: "A cyclic arithmetic circuit containing a one-half constant, a comparison gate, and an assignment gate.")]
  The only satisfying assignment is $a = b = c = 1\/2$.
]

It is easy to see that this problem has the flavor of a Brouwer fixed point.
#theorem[#citep(<dgp09>)][
  The Arithmetic Circuit SAT problem always admits a solution, and it is PPAD-complete to find it.
]

= From gates to games

It is possible to convert an Arithmetic Circuit SAT instance into a Nash equilibrium computation problem in a _multiplayer game_. (The game can also be
converted into a two-player #citep(<chen2009settling>) or three-player game #citep(<dgp09>), but we do not show how in this lecture).

The idea is to use _gadgets_: constructions that simulate the behavior of the gates in the circuit.

== Addition gate

Consider any game that contains the following interaction between four players $x, y, z, w$, each of which has two actions, denoted ${0,1}$. With a slight abuse of notation, we will call $x,y,z,w $ the probability of playing action $1$; hence, $x, y, z, w in [0,1].$

#example[Addition gadget game][
  Consider any game that contains as a substructure the gadget shown in the diagram below, and payoffs set as follows.

  #figure(caption: [Addition gadget game. The dashed blue edges denote possible edges in the game, which do not affect the result in @thm-gadget-addition.])[
    #image("figures/ppad_completeness/addition_gadget.svg", width: 4cm, alt: "Addition gadget: input players x and y influence w, and w and the output player z influence each other.")
  ]

    #block(width: 100%, breakable: false)[
    #paragraph-marker(shape: "triangle-right") _Payoffs of player $w$._~ The payoff of player $w$ is defined as follows.
    If $w$ plays $0$, her payoff does not depend on $z$'s strategy, but only on $x$ and $y$, according to the payoff table
    #align(center)[#table(
        columns: (1.3cm, 1.3cm, 1.3cm),
        align: center,
        fill: none,
        stroke: .2mm,
        [], [$y=0$], [$y=1$],
        [$x=0$], [0], [1],
        [$x=1$], [1], [2],
      )]
    ]

    #block(width: 100%, breakable: false)[
    If $w$ plays $1$, her payoff does not depend on $x$ and $y$'s strategy and depends on $z$'s according to the table
    #align(center)[#table(
        columns: (1.3cm, 1.3cm, 1.3cm),
        align: center,
        fill: none,
        stroke: .2mm,
        [], [$z=0$], [$z=1$],
        [], [0], [1],
      )]
    ]

    #block(width: 100%, breakable: false)[
    #paragraph-marker(shape: "triangle-right") _Payoffs of player $z$._~ The payoff of player $z$ is defined according to the table
    #align(center)[#table(
        columns: (1.3cm, 1.3cm, 1.3cm),
        align: center,
        fill: none,
        stroke: .2mm,
        [], [$z=0$], [$z=1$],
        [$w=0$], [1\/2], [1],
        [$w=1$], [1\/2], [0],
      )]
    ]

  #paragraph-marker(shape: "triangle-right") _Other payoffs and considerations_.~~
  The utilities of players $x$ and $y$ are independent of the strategies of $w$ and $z$.
  Player $w$ does not affect other players in the game.
]

#theorem[
  In all Nash equilibria of the game, $z = min{x + y, 1}$.
] <thm-gadget-addition>
#proof[
  Suppose that $z < min{x + y, 1}.$ Then, $z < x + y$. But then $w$ will deterministically play $w=0$, which will force $z$ to play $z=1$. This is a contradiction, since by hypothesis $z < min{x+y,1}$, which implies $z < 1$.

  Suppose now that $z > min{x+y,1}.$ In this case, $min{x+y,1} != 1$, as otherwise this would imply $z > 1$ which is impossible. Thus, $z > x + y.$ This implies $w = 1$ and hence $z = 0$, which is again impossible since $z > x + y$, which implies $z > 0$.

  The only remaining possibility is therefore $z = min{x+y,1},$ as we wanted to show.
]

#lec_bibliography("meta/refs.bib")

