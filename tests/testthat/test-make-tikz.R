test_that("make_tikz produces correct snippet for simple A --> B graph", {
  cg <- caugi::caugi(A %-->% B)
  layout <- data.frame(
    name = c("A", "B"),
    x = c(0, 0),
    y = c(0, 1)
  )
  tikz_snippet <- make_tikz(cg, layout = layout, full_doc = FALSE)

  # ---- Check TikZ basics ----
  expect_true(grepl(
    "link/.style={arrows={[scale=3]}}",
    tikz_snippet,
    fixed = TRUE
  ))
  expect_true(grepl(
    "var/.style={draw, circle, fill=lightgray}",
    tikz_snippet,
    fixed = TRUE
  ))
  expect_true(grepl("\\begin{tikzpicture}", tikz_snippet, fixed = TRUE))
  expect_true(grepl("\\end{tikzpicture}", tikz_snippet, fixed = TRUE))

  # ---- Check nodes ----
  expect_true(grepl(
    "\\node[var] (A) at (0,0) {A};",
    tikz_snippet,
    fixed = TRUE
  ))
  expect_true(grepl(
    "\\node[var] (B) at (0,10) {B};",
    tikz_snippet,
    fixed = TRUE
  ))

  # ---- Check edge ----
  expect_true(grepl("(A) edge[link, -Latex] (B)", tikz_snippet, fixed = TRUE))

  tikz_snippet_bend <- make_tikz(cg, full_doc = FALSE, bend_edges = TRUE)
  expect_true(grepl(
    "(A) edge[link, bend left=25, -Latex] (B)",
    tikz_snippet_bend,
    fixed = TRUE
  ))

  tikz_snippet_full <- make_tikz(cg, full_doc = TRUE)
  expect_true(grepl(
    "\\documentclass[tikz,border=2mm]{standalone}",
    tikz_snippet_full,
    fixed = TRUE
  ))
})

test_that("make_tikz produces correct snippet for simple A --- B graph", {
  cg <- caugi::caugi(A %---% B)
  layout <- data.frame(
    name = c("A", "B"),
    x = c(0, 0),
    y = c(1, 0)
  )

  tikz_snippet <- make_tikz(cg, layout = layout, full_doc = FALSE)

  # ---- Check TikZ basics ----
  expect_true(grepl(
    "var/.style={draw, circle, fill=lightgray}",
    tikz_snippet,
    fixed = TRUE
  ))
  expect_true(grepl("\\begin{tikzpicture}", tikz_snippet, fixed = TRUE))
  expect_true(grepl("\\end{tikzpicture}", tikz_snippet, fixed = TRUE))

  # ---- Check nodes ----
  expect_true(grepl(
    "\\node[var] (A) at (0,10) {A};",
    tikz_snippet,
    fixed = TRUE
  ))
  expect_true(grepl(
    "\\node[var] (B) at (0,0) {B};",
    tikz_snippet,
    fixed = TRUE
  ))

  # ---- Check edge ----
  expect_true(grepl("(A) edge[link, -] (B)", tikz_snippet, fixed = TRUE))
})

test_that("make_tikz produces correct snippet for simple A <-> B graph", {
  cg <- caugi::caugi(A %<->% B)
  layout <- data.frame(
    name = c("A", "B"),
    x = c(1, 0),
    y = c(0, 0)
  )

  tikz_snippet <- make_tikz(cg, layout = layout, full_doc = FALSE)

  # ---- Check TikZ basics ----
  expect_true(grepl(
    "var/.style={draw, circle, fill=lightgray}",
    tikz_snippet,
    fixed = TRUE
  ))
  expect_true(grepl("\\begin{tikzpicture}", tikz_snippet, fixed = TRUE))
  expect_true(grepl("\\end{tikzpicture}", tikz_snippet, fixed = TRUE))

  # ---- Check nodes ----
  expect_true(grepl(
    "\\node[var] (A) at (10,0) {A};",
    tikz_snippet,
    fixed = TRUE
  ))
  expect_true(grepl(
    "\\node[var] (B) at (0,0) {B};",
    tikz_snippet,
    fixed = TRUE
  ))

  # ---- Check edge ----
  expect_true(grepl(
    "(A) edge[link, {Latex}-{Latex}] (B)",
    tikz_snippet,
    fixed = TRUE
  ))
})

test_that("make_tikz produces bent edges automatically for A --> B, B --> A graph", {
  cg <- caugi::caugi(A %-->% B, B %-->% A, simple = FALSE, class = "UNKNOWN")
  layout <- data.frame(
    name = c("A", "B"),
    x = c(1, 0),
    y = c(0, 0)
  )

  tikz_snippet <- make_tikz(
    cg,
    layout = layout,
    full_doc = FALSE,
    bend_angle = 10
  )

  # ---- Check edge ----
  expect_true(grepl(
    "(A) edge[link, bend left=10, -Latex] (B)",
    tikz_snippet,
    fixed = TRUE
  ))
  expect_true(grepl(
    "(B) edge[link, bend left=10, -Latex] (A)",
    tikz_snippet,
    fixed = TRUE
  ))
})

test_that("make_tikz works on required and forbidden knowledge", {
  kn <- knowledge(
    A %-->% B,
    A %-->% C,
    B %!-->% C
  )

  tikz_snippet <- make_tikz(
    kn,
    required_col = "blue",
    forbidden_col = "green",
    full_doc = FALSE,
    bend_angle = 10
  )

  # Global color should be blue (2 required)
  expect_true(grepl(
    "link/.style={draw=blue",
    tikz_snippet,
    fixed = TRUE
  ))

  # The forbidden edge should be green
  expect_true(grepl(
    "(B) edge[link, draw=green, -Latex] (C)",
    tikz_snippet,
    fixed = TRUE
  ))
})

test_that("make_tikz works on tiered knowledge", {
  data(tpc_example)
  kn_tiered <- knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      old ~ starts_with("old")
    )
  )

  tikz_snippet <- make_tikz(
    kn_tiered,
    full_doc = FALSE
  )

  expect_true(grepl(
    "node[tier, fit=(child_x1)(child_x2)] (child)",
    tikz_snippet,
    fixed = TRUE
  ))

  cd_tges <- tges(engine = "causalDisco", score = "tbic")
  disco_cd_tges <- disco(
    data = tpc_example,
    method = cd_tges,
    knowledge = kn_tiered
  )

  tikz_snippet <- make_tikz(
    disco_cd_tges,
    scale = 10,
    full_doc = FALSE
  )

  expect_true(grepl(
    "begin{scope}[on background layer]",
    tikz_snippet,
    fixed = TRUE
  ))

  expect_true(grepl(
    "node[tier, fit=(child_x1)(child_x2)] (child)",
    tikz_snippet,
    fixed = TRUE
  ))

  expect_true(grepl(
    "node[tier label, anchor=south] at ($(child.north)+(0cm,0.2cm)$) {child}",
    tikz_snippet,
    fixed = TRUE
  ))
})

########### style = "classic" #########

classic_tiered_knowledge <- function() {
  data(tpc_example, envir = environment())
  knowledge(
    tpc_example,
    tier(
      child ~ starts_with("child"),
      youth ~ starts_with("youth"),
      old ~ starts_with("old")
    ),
    child_x1 %-->% oldage_x5
  )
}

test_that("classic style draws plain nodes, tier bands, and a time axis", {
  kn <- classic_tiered_knowledge()
  tikz <- make_tikz(kn, style = "classic", full_doc = FALSE)

  expect_true(grepl(
    "\\begin{tikzpicture}[x=3.5cm, y=1.5cm]",
    tikz,
    fixed = TRUE
  ))
  expect_true(grepl("var/.style={inner sep=2pt}", tikz, fixed = TRUE))
  expect_true(grepl(
    "o/.tip={Circle[open, length=1.6mm]}",
    tikz,
    fixed = TRUE
  ))
  expect_match(
    tikz,
    "\\\\node\\[var\\] \\(child_x1\\) at \\([^)]+\\) \\{child\\\\_x1\\};"
  )
  expect_false(grepl("circle", tikz, fixed = TRUE))

  # one band per tier, ordered by time
  expect_true(grepl("(tier-1) {};", tikz, fixed = TRUE))
  expect_true(grepl("(tier-3) {};", tikz, fixed = TRUE))
  expect_true(grepl("\\node[tier, fit={", tikz, fixed = TRUE))
  expect_true(grepl(
    "\\draw[time axis] ([xshift=-3mm]tier-1.south west) -- ([xshift=5mm]tier-3.south east);",
    tikz,
    fixed = TRUE
  ))
  expect_true(grepl(
    "\\node[tier label, below=3pt] at (tier-1.south) {child};",
    tikz,
    fixed = TRUE
  ))
  expect_true(grepl(
    "\\node[tier label, below=3pt] at (tier-3.south) {old};",
    tikz,
    fixed = TRUE
  ))

  # required edge keeps its color and is bent (routed around youth_x3)
  expect_match(
    tikz,
    "\\(child_x1\\) edge\\[->, draw=blue, bend (left|right)=[0-9]+\\] \\(oldage_x5\\)"
  )

  tikz_full <- make_tikz(kn, style = "classic")
  expect_true(grepl(
    "\\usetikzlibrary{arrows.meta, bending, backgrounds, fit}",
    tikz_full,
    fixed = TRUE
  ))
  expect_true(grepl("\\end{document}", tikz_full, fixed = TRUE))
})

test_that("classic style supports rows orientation and label sides", {
  kn <- classic_tiered_knowledge()

  tikz_rows <- make_tikz(
    kn,
    style = "classic",
    orientation = "rows",
    full_doc = FALSE
  )
  expect_true(grepl(
    "\\begin{tikzpicture}[x=2.5cm, y=2cm]",
    tikz_rows,
    fixed = TRUE
  ))
  expect_true(grepl(
    "\\node[tier label, left=3pt] at (tier-1.west) {child};",
    tikz_rows,
    fixed = TRUE
  ))

  tikz_above <- make_tikz(
    kn,
    style = "classic",
    tier_label_pos = "above",
    full_doc = FALSE
  )
  expect_true(grepl(
    "\\node[tier label, above=3pt] at (tier-2.north) {youth};",
    tikz_above,
    fixed = TRUE
  ))

  expect_error(
    make_tikz(kn, style = "classic", tier_label_pos = "left"),
    "must be \"below\" or \"above\"",
    fixed = TRUE
  )
  expect_error(
    make_tikz(
      kn,
      style = "classic",
      orientation = "rows",
      tier_label_pos = "below"
    ),
    "must be \"left\" or \"right\"",
    fixed = TRUE
  )
})

test_that("classic style draws PAG edge marks with open circles", {
  cg <- caugi::caugi(A %o->% B, B %o-o% C, C %-->% D)
  tikz <- make_tikz(cg, style = "classic", full_doc = FALSE)
  expect_true(grepl("(A) edge[o->", tikz, fixed = TRUE))
  expect_true(grepl("(B) edge[o-o", tikz, fixed = TRUE))
  expect_true(grepl("(C) edge[->", tikz, fixed = TRUE))

  # untiered: plot coordinates, no tier decorations
  expect_true(grepl("\\begin{tikzpicture}\n", tikz, fixed = TRUE))
  expect_false(grepl("time axis]", tikz, fixed = TRUE))
})

test_that("classic layout centers unequal tiers and staggers nodes", {
  pos <- data.frame(
    name = c("a1", "a2", "a3", "b1", "b2"),
    x = c(0, 0, 0, 1, 1),
    y = c(0, 0.5, 1, 0, 1)
  )
  tiers <- list(b = c("b1", "b2"), a = c("a1", "a2", "a3"))
  layout <- classic_tier_layout(pos, tiers)

  expect_equal(layout$orientation, "columns")
  expect_equal(layout$tiers, c("a", "b"))
  expect_equal(layout$max_nodes, 3)
  expect_equal(layout$coords$name, pos$name)
  expect_equal(layout$coords$y, c(0, 1, 2, 0.5, 1.5))
  expect_equal(layout$coords$x, c(-0.15, 0.15, -0.15, 0.85, 1.15))

  # rows: tiers along y (first tier on top), nodes along x
  pos_rows <- data.frame(
    name = pos$name,
    x = c(0, 0.5, 1, 0, 1),
    y = c(1, 1, 1, 0, 0)
  )
  layout_rows <- classic_tier_layout(pos_rows, tiers)
  expect_equal(layout_rows$orientation, "rows")
  expect_equal(layout_rows$tiers, c("a", "b"))
  expect_equal(layout_rows$coords$x, c(0, 1, 2, 0.5, 1.5))
  expect_equal(layout_rows$coords$y, c(0.15, -0.15, 0.15, -0.85, -1.15))

  # no consistent tier axis (e.g. a custom layout) -> NULL
  pos_custom <- pos
  pos_custom$x <- c(0, 0.2, 0, 1, 1)
  expect_null(classic_tier_layout(pos_custom, tiers))
  expect_null(classic_tier_layout(pos, NULL))
})

test_that("classic style falls back to fitted tiers for custom layouts", {
  kn <- classic_tiered_knowledge()
  layout <- data.frame(
    name = c(
      "child_x1",
      "child_x2",
      "youth_x3",
      "youth_x4",
      "oldage_x5",
      "oldage_x6"
    ),
    x = c(0, 0.1, 0.5, 0.4, 1, 0.9),
    y = c(0, 1, 0, 1, 0, 1)
  )
  tikz <- make_tikz(kn, style = "classic", layout = layout)
  expect_true(grepl(
    "\\usetikzlibrary{arrows.meta, bending, backgrounds, fit, calc}",
    tikz,
    fixed = TRUE
  ))
  expect_true(grepl(
    "\\node[tier, inner sep=6pt, fit=(child_x1)(child_x2)] (child) {};",
    tikz,
    fixed = TRUE
  ))
  expect_false(grepl("time axis]", tikz, fixed = TRUE))
})

########### node_labels / tier_labels #########

test_that("node_labels and tier_labels are inserted verbatim in both styles", {
  kn <- classic_tiered_knowledge()
  node_labels <- c(child_x1 = "$X_1$", oldage_x5 = "$X_5$")
  tier_labels <- list(child = "Childhood")

  tikz_classic <- make_tikz(
    kn,
    style = "classic",
    node_labels = node_labels,
    tier_labels = tier_labels,
    full_doc = FALSE
  )
  expect_match(tikz_classic, "\\(child_x1\\) at \\([^)]+\\) \\{\\$X_1\\$\\};")
  expect_match(
    tikz_classic,
    "\\(child_x2\\) at \\([^)]+\\) \\{child\\\\_x2\\};"
  )
  expect_true(grepl("{Childhood};", tikz_classic, fixed = TRUE))
  expect_true(grepl("{youth};", tikz_classic, fixed = TRUE))

  tikz_default <- make_tikz(
    kn,
    node_labels = node_labels,
    tier_labels = tier_labels,
    full_doc = FALSE
  )
  expect_match(tikz_default, "\\(child_x1\\) at \\([^)]+\\) \\{\\$X_1\\$\\};")
  expect_true(grepl("{Childhood};", tikz_default, fixed = TRUE))
})

test_that("node_labels and tier_labels are validated", {
  kn <- classic_tiered_knowledge()
  expect_error(
    make_tikz(kn, node_labels = c(nope = "x")),
    "`node_labels` contains names that are not in the graph: nope",
    fixed = TRUE
  )
  expect_error(
    make_tikz(kn, tier_labels = c("Childhood")),
    "`tier_labels` must be a named character vector.",
    fixed = TRUE
  )
  expect_error(
    make_tikz(caugi::caugi(A %-->% B), tier_labels = c(t1 = "T1")),
    "`tier_labels` contains names that are not in the graph: t1",
    fixed = TRUE
  )
})

test_that("default style draws PAG edge marks", {
  cg <- caugi::caugi(A %o->% B, B %o-o% C, C %--o% D)
  expect_no_warning(tikz <- make_tikz(cg, full_doc = FALSE))
  expect_true(grepl("{Circle[open]}-Latex]", tikz, fixed = TRUE))
  expect_true(grepl("{Circle[open]}-{Circle[open]}]", tikz, fixed = TRUE))
  expect_true(grepl("-{Circle[open]}]", tikz, fixed = TRUE))
})

########### edge routing #########

test_that("make_tikz bends edges around nodes in the way, like plot()", {
  cg <- caugi::caugi(A %-->% B, B %-->% C, A %-->% C)
  layout <- data.frame(name = c("A", "B", "C"), x = c(0, 0.5, 1), y = 0)

  tikz <- make_tikz(cg, layout = layout, full_doc = FALSE)
  expect_true(grepl("(A) edge[link, -Latex] (B)", tikz, fixed = TRUE))
  expect_true(grepl("(B) edge[link, -Latex] (C)", tikz, fixed = TRUE))
  expect_match(
    tikz,
    "\\(A\\) edge\\[link, bend (left|right)=[0-9]+, -Latex\\] \\(C\\)"
  )

  # routing follows caugi's edge_style$route
  tikz_off <- make_tikz(
    cg,
    layout = layout,
    edge_style = list(route = FALSE),
    full_doc = FALSE
  )
  expect_true(grepl("(A) edge[link, -Latex] (C)", tikz_off, fixed = TRUE))

  # classic style routes too, with at least bend_angle when bending all edges
  tikz_classic <- make_tikz(cg, layout = layout, style = "classic")
  # A --> B bends right, away from the routed A --> C
  expect_match(tikz_classic, "\\(A\\) edge\\[->, bend right=[0-9]+\\] \\(B\\)")
  m <- regmatches(
    tikz_classic,
    regexec(
      "\\(A\\) edge\\[->, bend (left|right)=([0-9]+)\\] \\(C\\)",
      tikz_classic
    )
  )[[1]]
  expect_length(m, 3)
  expect_gte(as.numeric(m[3]), 10)

  tikz_classic_straight <- make_tikz(
    cg,
    layout = layout,
    style = "classic",
    bend_edges = FALSE,
    full_doc = FALSE
  )
  expect_true(grepl("(A) edge[->] (B)", tikz_classic_straight, fixed = TRUE))
  expect_match(
    tikz_classic_straight,
    "\\(A\\) edge\\[->, bend (left|right)=[0-9]+\\] \\(C\\)"
  )
})

test_that("make_tikz routes a long edge across tiers around a node", {
  kn <- classic_tiered_knowledge()

  # child_x1 --> oldage_x5 passes straight through youth_x3
  tikz <- make_tikz(kn, full_doc = FALSE)
  expect_match(
    tikz,
    "\\(child_x1\\) edge\\[link, bend (left|right)=[0-9]+, -Latex\\] \\(oldage_x5\\)"
  )
  tikz_off <- make_tikz(kn, edge_style = list(route = FALSE), full_doc = FALSE)
  expect_true(grepl(
    "(child_x1) edge[link, -Latex] (oldage_x5)",
    tikz_off,
    fixed = TRUE
  ))
})
