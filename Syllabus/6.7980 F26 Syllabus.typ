#import "macros.typ": email, item

#set document(title: "6.7980 Topics in Multiagent Learning - Fall 2026", author: (
  "Gabriele Farina",
  "Constantinos Daskalakis",
))
#set page(
  margin: (top: 1.05in, bottom: 1.05in, left: 1.1in, right: 1.1in),
  numbering: "1",
  paper: "us-letter",
)
#set list(tight: true)
#set text(font: "New Computer Modern", size: 9.5pt)
#set par(justify: true, leading: .6em, spacing: 1.15em)
#show strong: set text(font: "Frutiger")
#show heading: set text(font: "Frutiger")

#show heading: set block(above: 6mm, below: 5mm)

#align(center)[
  #text(font: "Frutiger", size: 24pt, weight: "bold")[Topics in Multiagent Learning]
  #v(3mm)
  #text(font: "Frutiger", weight: "bold", size: 16pt)[MIT 6.7980 --- Fall 2026]
]
#v(6mm)

#item(title: "Lecture")[Tuesdays and Thursdays, 11:00am-12:30pm, *in room E25-111*.]

#set list(marker: sym.triangle.r.filled)
#item(title: "Instructors")[
  - Prof. Gabriele Farina, office 45-501F (in the College of Computing building) \
    ~~~~#email("gfarina@mit.edu") ~~ URL: #link("https://www.mit.edu/~gfarina")[`www.mit.edu/~gfarina`]
  - Prof. Constantinos Daskalakis, office 32-G694 (in the Stata building) \
    ~~~~#email("costis@csail.mit.edu") ~~ URL: #link("https://people.csail.mit.edu/costis")[`people.csail.mit.edu/costis`]

  We are happy to meet with students by appointment.
]

#item(title: "Teaching assistants")[
  - Kat Federova (#email("fedorova@mit.edu")). Office hours: TBD.
  - Mingyang Liu (#email("liumy19@mit.edu")). Office hours: TBD.
  - Daniel Xia (#email("dxia03@mit.edu")). Office hours: TBD.
  - Rui Yao (#email("rayyao@mit.edu")). Office hours: TBD.
]

#item(title: "Grading")[
  - Attendance and participation (see below) --- 20%.
  - Improving material (see below) --- 30%.
  - Project (see below) --- 50%.
]

#item(title: "Attendance")[
  We expect everyone to attend at least 50% of the lectures. The "Attendance and participation" component of grading above reflects (in a binary manner) whether that was met. We will measure attendance using random quizzes during classes.
]

#item(
  title: "Coursework",
)[There are no assigned homework sets. Students will contribute to the shared course materials and complete a project, as described below.]

#item(
  title: "Prerequisites",
)[Discrete Mathematics and Algorithms at the advanced undergraduate level; mathematical maturity.]

#item(
  title: "Lecture notes",
)[Lecture notes are available as HTML and PDF on the course website. Announcements and administrative materials will be posted on Canvas.]

#item(
  title: "Collaboration policy",
)[We encourage working together on the course materials, projects, and discussion of the ideas. Contributions and project work should reflect _your own_ understanding. Acknowledge collaborators and sources, and do not present somebody else's work as your own.]

// Transcribed from the supplied policy screenshot. The only content adaptation
// is the course reference: 16.940 -> 6.7980. The screenshot's page/section numbers
// are not part of the policy.
#item(
  title: "Acceptable AI use",
)[#footnote[This policy is inspired _in part_ from the #text(blue)[#link("https://tll.mit.edu/teaching-resources/course-design/ai-in-teaching-learning/acceptable-ai-use-policies/")[template policy]] provided by the MIT Teaching + Learning Lab.]
  Students may use generative AI tools (e.g., LLMs) to support learning, brainstorming, editing, debugging, or generating explanations. We believe that _your human understanding_ is still the ultimate goal of education more broadly. We should aim to expand our knowledge, deepen our understanding, and sharpen our thinking. Generative AI might be a great tool for aiding this process, but learning and growth require productive struggle. Don't let generative AI remove or reduce your productive struggle.
  We also expect (and require) _full transparency_ regarding your use of AI. Always indicate if and how you used generative AI, i.e., which tools you used and during which phases of your work.
]

#pagebreak()
= Description

This course studies multiagent systems through game theory, optimization, and learning theory. We cover foundational topics such as Nash equilibria, regret minimization, learning dynamics, and extensive-form games.

We also explore modern topics: multiagent deep reinforcement learning; information and mechanism design; team games and hidden-role games; alignment; high-dimensional and kernelized learning; nonconvex games; calibration; and the complexity of finding equilibria. Applications and open research questions connect the theory to multiagent AI.

= Improving Material

We would like to make the lecture notes available to as many people as possible. You can now read them in a browser, follow links between sections and references, and move between the notes and their source. We would like everyone's help to make this a useful resource for learners around the world.

#v(2mm)
#figure(
  image("assets/html-notes-collage.svg", width: 100%),
  // caption: [The course website and HTML notes: equilibrium dynamics, game trees, and Nash equilibria.],
  numbering: none,
)
#v(2mm)

We will divide the class into groups, each focusing on a different part of the material. Using the #link("https://github.com/gabrfarina/MIT-6.7980-Topics-in-Multiagent-Learning")[class GitHub repository], each group can open issues to identify improvements and submit pull requests to implement them. We will improve the material together, reviewing and building on one another's contributions.

Contributions can include clarifying explanations and proofs, fixing errors, adding examples and homework-style exercises for future readers, and polishing figures, organization, and presentation. If anyone is brave enough, we would also love interactive components that let readers experiment with the ideas.

_On the bright side, there is no homework! :-)_ Improving the shared material accounts for 30% of the course grade.

= Project

Projects may be completed individually or in groups of 2-3 students and will include a presentation. We will offer three project directions:

*#link("https://github.com/gabrfarina/6.7980-f26-fow-challenge")[Fog of War Challenge].* Build and evaluate an agent that plays with partial information. Explore how it uses observations, reasons about uncertainty, and chooses strategic actions. The rules, starter code, and arena are maintained in the separate challenge repository.

*Modeling questions.* Formulate a multiagent problem by specifying the players, objectives, information, and available actions. Study how modeling choices affect the resulting strategic behavior.

*Theory questions.* Investigate a mathematical question about equilibria, learning dynamics, or computational complexity. Develop rigorous proofs, bounds, or counterexamples that clarify the behavior of multiagent systems.

The project is the central component of the course and accounts for 50% of the final grade. We will therefore be "robust" in our grading: we will look carefully at the depth of your understanding, the quality and substance of your work, and how clearly you explain your results.

#pagebreak()
= Schedule

#set par(justify: false)
#set table.cell(breakable: false)
#let module(title) = (
  [],
  table.cell(colspan: 2, align: left)[#v(3mm)#smallcaps[#title]],
)
#let schedule-date(date) = {
  let day = int(date.split(" ").last())
  let last = calc.rem(day, 10)
  let suffix = if day >= 11 and day <= 13 { "th" } else {
    if last == 1 { "st" } else if last == 2 { "nd" } else if last == 3 { "rd" } else { "th" }
  }
  [#date#super[#suffix]]
}
#let desc(body) = {
  [#linebreak()#text(size: 9.8pt)[#body]]
  v(.5mm)
}
// Standalone rows begin a group without a part heading on the course website.
#let row(n, date, title, description: none, instructor: [], standalone: false) = (
  [#n],
  [#schedule-date(date)],
  [*#title*#if instructor != [] [#h(1fr)#box[#text(size: 8.5pt, style: "italic")[#instructor]]]#if description != none [#desc(description)]],
)
#let schedule(..cells) = table(
  columns: (auto, auto, 80%),
  align: (right, left, left),
  stroke: (col, row) => (
    bottom: .2mm + gray,
    left: if col == 2 { .2mm + gray } else { none },
    right: none,
    top: .2mm + gray,
  ),
  inset: 2.1mm,
  ..cells.pos(),
)

#schedule(
  ..row(
    0,
    "Sep 10",
    [Course Overview],
    description: [We will discuss the syllabus, projects, administrative details, and an overview of the topics covered.],
    instructor: [Constantinos Daskalakis; Gabriele Farina],
  ),
  ..module[Part I: Foundations (8 lectures)],
  ..row(
    1,
    "Sep 15",
    [Setting and equilibria: the Nash equilibrium],
    description: [Nash's existence theorem and its connection to fixed-point theorems.],
    instructor: [Constantinos Daskalakis],
  ),
  ..row(
    2,
    "Sep 17",
    [Brouwer and Sperner],
    description: [Sperner's lemma, Brouwer's theorem, and combinatorial proofs of equilibrium existence.],
    instructor: [Constantinos Daskalakis],
  ),
  ..row(
    3,
    "Sep 22",
    [Properties of Nash equilibrium],
    description: [Topological and computational properties. Zero-sum games and linear programming. Correlated and coarse correlated equilibria.],
    instructor: [Gabriele Farina],
  ),
  ..row(
    4,
    "Sep 24",
    [Learning in games: Foundations],
    description: [Regret and hindsight rationality. Regret minimization and its relationships with equilibrium concepts.],
    instructor: [Gabriele Farina],
  ),
  ..row(
    5,
    "Sep 29",
    [Learning in games: Algorithms],
    description: [General principles for learning algorithms. Follow-the-leader, regret matching, multiplicative weights, and online mirror descent.],
    instructor: [Gabriele Farina],
  ),
  ..row(
    6,
    "Oct 1",
    [Learning with bandit feedback],
    description: [Partial feedback and exploration. From multiplicative weights to Exp3; regret guarantees.],
    instructor: [Constantinos Daskalakis],
  ),
  ..row(
    7,
    "Oct 6",
    [Modeling extensive-form games],
    description: [Perfect and imperfect information. Kuhn's theorem. Normal-form and sequence-form strategies.],
    instructor: [Gabriele Farina],
  ),
  ..row(
    8,
    "Oct 8",
    [Learning in extensive-form games],
    description: [No-regret learning, counterfactual utilities, and counterfactual regret minimization (CFR).],
    instructor: [Gabriele Farina],
  ),
  ..row([], "Oct 13", [No class], description: [MIT follows a Monday schedule.]),

  ..row(
    9,
    "Oct 15",
    [Taking stock],
    description: [We will discuss big open questions in the field and possible project ideas.],
    instructor: [Gabriele Farina; Constantinos Daskalakis],
    standalone: true,
  ),
  ..module[Part II: Multiagent deep reinforcement learning (2 lectures)],
  ..row(
    10,
    "Oct 20",
    [Multiagent deep RL (part I)],
    description: [Reinforcement learning in games. Self-play and deep learning methods for perfect-information games.],
    instructor: [Gabriele Farina],
  ),
  ..row(
    11,
    "Oct 22",
    [Multiagent deep RL (part II)],
    description: [Deep reinforcement learning for imperfect-information games. Game-playing applications, including Generals.io.],
    instructor: [Gabriele Farina],
  ),
  ..module[Part III: Information, Communication, Alignment (4 lectures)],
  ..row(
    12,
    "Oct 27",
    [Information and mechanism design],
    description: [Designing information and incentives in strategic interactions.],
    instructor: [Brian Hu Zhang],
  ),
  ..row(
    13,
    "Oct 29",
    [Team games and hidden-role games],
    description: [Coordination in teams and games with hidden roles.],
    instructor: [Brian Hu Zhang],
  ),
  ..row(
    14,
    "Nov 3",
    [Alignment (part I)],
    description: [Reinforcement learning from human feedback (RLHF) and alignment.],
    instructor: [Natalie Collina],
  ),
  ..row(
    15,
    "Nov 5",
    [Alignment (part II)],
    description: [Regularized RLHF and direct preference optimization (DPO).],
    instructor: [Natalie Collina],
  ),

  ..module[Part IV: Advanced learning (3 lectures)],
  ..row(
    16,
    "Nov 10",
    [Nonconvex games],
    description: [Nonconvexity, learning dynamics, and local equilibrium concepts.],
    instructor: [Weiqiang Zheng],
  ),
  ..row(
    17,
    "Nov 12",
    [High-dimensional and kernelized learning],
    description: [Learning with large strategy spaces. Kernelized methods and multiplicative weights.],
    instructor: [Constantinos Daskalakis],
  ),
  ..row(
    18,
    "Nov 17",
    [Calibration],
    description: [Calibrated prediction and its connections to learning in games.],
    instructor: [Constantinos Daskalakis],
  ),
  ..module[Part V: Computational complexity (2 lectures)],
  ..row(
    19,
    "Nov 19",
    [Total search and TFNP],
    description: [Total search problems, the TFNP framework, and the PPAD complexity class.],
    instructor: [Constantinos Daskalakis],
  ),
  ..row(
    20,
    "Nov 24",
    [PPAD-hardness of Nash equilibrium],
    description: [Reductions and the computational hardness of finding Nash equilibria.],
    instructor: [Constantinos Daskalakis],
  ),
  ..row([], "Nov 26", [No class], description: [Thanksgiving holiday.]),
  ..module[Project work and presentations],
  ..row(21, "Dec 1", [Project work], description: [Time reserved for project development and preparation.]),
  ..row(22, "Dec 3", [Project work], description: [Time reserved for project development and preparation.]),
  ..row(23, "Dec 8", [Project presentations]),
  ..row(24, "Dec 10", [Project presentations]),
)
