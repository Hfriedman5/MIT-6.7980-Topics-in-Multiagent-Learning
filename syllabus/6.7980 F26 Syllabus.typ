#import "gabri-schedule.typ": break-badge, email, item, lecture, module, no-class, proj, schedule
#import "fall-2026-calendar.typ": calendar-exceptions, class-dates

#set document(title: "6.7980 Topics in Multiagent Learning - Fall 2026", author: (
  "Gabriele Farina",
  "Constantinos Daskalakis",
))
#set page(
  margin: (top: 1.05in, bottom: 1.05in, left: 1.1in, right: 1.1in),
  numbering: "1",
  paper: "us-letter",
)
#set list(tight: true, marker: sym.triangle.r.filled)
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

#item("Lecture")[Tuesdays and Thursdays, 11:00am-12:30pm, in room `E25-111`.]

#item("Instructors")[
  - Prof. Gabriele Farina, office `45-501F` (in the College of Computing building) \
    ~~~~#email("gfarina@mit.edu") ~~ URL: #link("https://www.mit.edu/~gfarina")[`www.mit.edu/~gfarina`]
  - Prof. Constantinos Daskalakis, office `32-G694` (in the Stata building) \
    ~~~~#email("costis@csail.mit.edu") ~~ URL: #link("https://people.csail.mit.edu/costis")[`people.csail.mit.edu/costis`]

  We are happy to meet with students by appointment.
]

#item("Teaching assistants")[
  - Kat Federova (#email("fedorova@mit.edu")). Office hours: TBD.
  - Mingyang Liu (#email("liumy19@mit.edu")). Office hours: TBD.
  - Daniel Xia (#email("dxia03@mit.edu")). Office hours: TBD.
  - Rui Yao (#email("rayyao@mit.edu")). Office hours: TBD.
]

#item("Grading")[
  - Attendance and participation (see below) --- 20%.
  - Improving material (see below) --- 30%.
  - Project (see below) --- 50%.
]

#item("Attendance")[
  We expect everyone to attend at least 50% of the lectures. The "Attendance and participation" component of grading above reflects (in a binary manner) whether that was met. We will measure attendance using random quizzes during classes.
]

#item(
  "Coursework",
)[There are no assigned homework sets. Students will contribute to the shared course materials and complete a project, as described below.]

#item(
  "Prerequisites",
)[Discrete Mathematics and Algorithms at the advanced undergraduate level; mathematical maturity.]

#item(
  "Lecture notes",
)[Lecture notes are available as HTML and PDF on the course website. Announcements and administrative materials will be posted on Canvas.]

#item(
  "Collaboration policy",
)[We encourage working together on the course materials, projects, and discussion of the ideas. Contributions and project work should reflect _your own_ understanding. Acknowledge collaborators and sources, and do not present somebody else's work as your own.]

#item(
  "Acceptable AI use",
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
  numbering: none,
)
#v(2mm)

We will divide the class into groups, each focusing on a different part of the material. Using the #link("https://github.com/gabrfarina/MIT-6.7980-Topics-in-Multiagent-Learning")[class GitHub repository], each group can open issues to identify improvements and submit pull requests to implement them. We will improve the material together, reviewing and building on one another's contributions.

Contributions can include clarifying explanations and proofs, fixing errors, adding examples and homework-style exercises for future readers, and polishing figures, organization, and presentation. If anyone is brave enough, we would also love interactive components that let readers experiment with the ideas.

_On the bright side, there is no homework! :-)_ Improving the shared material accounts for 30% of the course grade.

= Project

Projects may be completed individually or in groups of 2-5 students and will include a presentation. We will offer three project directions:

#link("https://www.mit.edu/~6.7980/fow")[*Fog of War Chess Challenge.*] Build and evaluate an agent that plays with partial information. Explore how it uses observations, reasons about uncertainty, and chooses strategic actions. Each bot sandbox is allocated two CPU cores and 4 GiB of memory. A dedicated document will describe the challenge, including the rules, starter code, and how to access the arena.

#figure(
  block(width: 100%, inset: 0pt, radius: 5pt, clip: true, stroke: .4pt + luma(82%))[
    #image("assets/fog-of-war-challenge.png", width: 100%)
  ],
  numbering: none,
)

*Modeling questions.* Formulate a multiagent problem by specifying the players, objectives, information, and available actions. Study how modeling choices affect the resulting strategic behavior. We will provide a separate document with possible modeling questions and leads to explore.

*Theory questions.* Investigate a mathematical question about equilibria, learning dynamics, or computational complexity. Develop rigorous proofs, bounds, or counterexamples that clarify the behavior of multiagent systems. We will provide a separate document with possible theory questions and leads to explore.

The project is the central component of the course and accounts for 50% of the final grade. We will therefore be "robust" in our grading: we will look carefully at the depth of your understanding, the quality and substance of your work, and how clearly you explain your results.

= Tentative Schedule

#set par(justify: false)
#set table.cell(breakable: false)

// Reorder these entries freely: dates and lecture numbers are assigned below.
#let outline = (
  ..calendar-exceptions,
  lecture(
    "overview",
    [Course Overview],
    description: [We will discuss the syllabus, projects, administrative details, and an overview of the topics covered.],
    instructor: [Constantinos Daskalakis; Gabriele Farina],
  ),
  module[Part I: Foundations],
  lecture(
    "nash",
    [Setting and equilibria: the Nash equilibrium],
    description: [Nash's existence theorem and its connection to fixed-point theorems.],
    instructor: [Constantinos Daskalakis],
  ),
  lecture(
    "brouwer",
    [Brouwer and Sperner],
    description: [Sperner's lemma, Brouwer's theorem, and combinatorial proofs of equilibrium existence.],
    instructor: [Constantinos Daskalakis],
  ),
  lecture(
    "nash-properties",
    [Properties of Nash equilibrium],
    description: [Topological and computational properties. Zero-sum games and linear programming. Correlated and coarse correlated equilibria.],
    instructor: [Gabriele Farina],
  ),
  lecture(
    "learning-foundations",
    [Learning in games: Foundations],
    description: [Regret and hindsight rationality. Regret minimization and its relationships with equilibrium concepts.],
    instructor: [Gabriele Farina],
  ),
  lecture(
    "learning-algorithms",
    [Learning in games: Algorithms],
    description: [General principles for learning algorithms. Follow-the-leader, regret matching, multiplicative weights, and online mirror descent.],
    instructor: [Gabriele Farina],
  ),
  lecture(
    "bandit",
    [Learning with bandit feedback],
    description: [Partial feedback and exploration. From multiplicative weights to `Exp3`; regret guarantees.],
    instructor: [Constantinos Daskalakis],
  ),
  lecture(
    "efg-modeling",
    [Modeling extensive-form games],
    description: [Perfect and imperfect information. Kuhn's theorem. Normal-form and sequence-form strategies.],
    instructor: [Gabriele Farina],
  ),
  lecture(
    "efg-learning",
    [Learning in extensive-form games],
    description: [No-regret learning, counterfactual utilities, and counterfactual regret minimization (CFR).],
    instructor: [Gabriele Farina],
  ),
  lecture(
    "deep-rl-1",
    [Multiagent deep RL],
    description: [Reinforcement learning in games. Self-play and deep learning methods for perfect-information games.],
    instructor: [Gabriele Farina],
  ),
  lecture(
    "taking-stock",
    [Taking stock],
    badge: proj,
    description: [We will discuss big open questions in the field and possible project ideas.],
    instructor: [Gabriele Farina; Constantinos Daskalakis],
    standalone: true,
  ),
  module[Part II: Information, Communication, Alignment],
  lecture(
    "information-design",
    [Information and mechanism design],
    description: [Designing information and incentives in strategic interactions.],
    instructor: [Brian Hu Zhang],
  ),
  lecture(
    "team-games",
    [Team games and hidden-role games],
    description: [Coordination in teams and games with hidden roles.],
    instructor: [Brian Hu Zhang],
  ),
  lecture(
    "alignment-1",
    [Alignment (part I)],
    description: [Reinforcement learning from human feedback (RLHF) and alignment.],
    instructor: [Natalie Collina],
  ),
  lecture(
    "alignment-2",
    [Alignment (part II)],
    description: [Regularized RLHF and direct preference optimization (DPO).],
    instructor: [Natalie Collina],
  ),

  module[Part III: Advanced learning],
  lecture(
    "calibration",
    [Forecasting and calibration],
    description: [Calibrated prediction and its connections to learning in games.],
    instructor: [Gabriele Farina],
  ),
  lecture(
    "kernelized",
    [High-dimensional games],
    description: [Learning with large strategy spaces. Kernelized methods and multiplicative weights.],
    instructor: [Constantinos Daskalakis],
  ),
  lecture(
    "nonconvex",
    [Nonconvex games],
    description: [Nonconvexity, learning dynamics, and local equilibrium concepts.],
    instructor: [Weiqiang Zheng],
  ),
  module[Part IV: Computational complexity],
  lecture(
    "tfnp",
    [Total search and TFNP],
    description: [Total search problems, the TFNP framework, and the PPAD complexity class.],
    instructor: [Constantinos Daskalakis],
  ),
  lecture(
    "ppad",
    [PPAD-hardness of Nash equilibrium],
    description: [Reductions and the computational hardness of finding Nash equilibria.],
    instructor: [Constantinos Daskalakis],
  ),
  module[Project work and presentations],
  no-class(
    title: [No class],
    description: [Project break],
    badge: break-badge,
  ),
  lecture(
    "presentations-1",
    [Project presentations],
    description: [Show us your cool work!],
    badge: proj,
  ),
  lecture(
    "presentations-2",
    [Project presentations],
    description: [Show us your cool work!],
    badge: proj,
  ),
  lecture(
    "presentations-3",
    [Project presentations],
    description: [Show us your cool work!],
    badge: proj,
  ),
  lecture(
    "presentations-4",
    [Project presentations],
    description: [Show us your cool work!],
    badge: proj,
  ),
)

#schedule(class-dates, outline, hide-instructors: true)
