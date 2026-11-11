########### rcolor_to_tikz Tests #########

test_that("rcolor_to_tikz handles NULL and empty input", {
  expect_null(rcolor_to_tikz(NULL))
  expect_null(rcolor_to_tikz(character(0)))
})

test_that("rcolor_to_tikz handles default TikZ colors", {
  defaults <- c(
    "black",
    "blue",
    "brown",
    "cyan",
    "darkgray",
    "gray",
    "green",
    "lightgray",
    "magenta",
    "orange",
    "pink",
    "purple",
    "red"
  )
  for (col in defaults) {
    expect_equal(rcolor_to_tikz(col), col)
    expect_equal(rcolor_to_tikz(toupper(col)), col)
  }
})

test_that("rcolor_to_tikz maps 'lightgrey' to 'lightgray'", {
  expect_equal(rcolor_to_tikz("lightgrey"), "lightgray")
  expect_equal(rcolor_to_tikz("LIGHTGREY"), "lightgray")
})

test_that("rcolor_to_tikz handles custom colors", {
  expect_equal(
    rcolor_to_tikz("#123456"),
    "{rgb:red,0.071;green,0.204;blue,0.337}"
  )
  # R color name not in the TikZ defaults
  expect_match(
    rcolor_to_tikz("goldenrod"),
    "^\\{rgb:red,.*;green,.*;blue,.*\\}$"
  )
})

######### extract_nodes Tests #########

test_that("extract_nodes returns correct nodes with colors", {
  # Mock grobs
  node_grob_children <- list(
    node.A = list(
      name = "node.A",
      x = 1,
      y = 2,
      gp = list(fill = "red", col = "black", fontsize = 12)
    ),
    node.B = list(
      name = "node.B",
      x = 3,
      y = 4,
      gp = list(fill = "blue", col = NULL, fontsize = 10)
    ),
    label.A = list(label = "Node A"),
    label.B = list(label = "Node B"),
    other = list(something = TRUE) # Should be ignored
  )

  result <- extract_nodes(node_grob_children, scale = 2)

  expect_equal(length(result), 2)
  expect_equal(
    unname(result[[1]]),
    list("Node A", 2, 4, "red", "black")
  )
  expect_equal(result[[2]]$name, "Node B")
  expect_equal(c(result[[2]]$x, result[[2]]$y), c(6, 8))
  expect_equal(result[[2]]$fill, "blue")
  expect_null(result[[2]]$draw) # col = NULL
})

test_that("extract_nodes handles empty input gracefully", {
  expect_equal(extract_nodes(list(), 1), list())
})

test_that("extract_nodes works when gp elements are missing", {
  node_grob_children <- list(
    node.C = list(name = "C", x = 0, y = 0, gp = list()),
    label.C = list(label = "Node C")
  )
  result <- extract_nodes(node_grob_children, 1)
  expect_null(result[[1]]$fill)
  expect_null(result[[1]]$draw)
  expect_equal(result[[1]]$x, 0)
  expect_equal(result[[1]]$y, 0)
})


############ compute_global_color Tests #########

test_that("compute_global_color returns most common color", {
  nodes <- list(
    list(fill = "red"),
    list(fill = "blue"),
    list(fill = "red"),
    list(fill = "green")
  )
  expect_equal(compute_global_color(nodes, "fill"), "red")
})

test_that("compute_global_color ignores nodes without that color", {
  nodes <- list(
    list(fill = "red"),
    list(fill = NULL),
    list(draw = "blue"),
    list(fill = "red")
  )
  expect_equal(compute_global_color(nodes, "fill"), "red")
})

test_that("compute_global_color returns NULL for empty input or no colors", {
  expect_null(compute_global_color(list(), "fill"))
  nodes <- list(list(draw = "blue"), list(draw = "green"))
  expect_null(compute_global_color(nodes, "fill"))
})


############# latex_escape Tests #########

test_that("latex_escape escapes all LaTeX special characters", {
  specials <- c("_", "%", "#", "&", "$", "^", "{", "}", "~")

  for (ch in specials) {
    result <- latex_escape(ch)
    expect_equal(result, paste0("\\", ch))
  }
})

test_that("latex_escape escapes backslash correctly", {
  expect_equal(latex_escape("\\"), "\\textbackslash\\{\\}")
})

test_that("latex_escape handles strings with multiple specials", {
  input <- "100% of $people & 50_50 #tests {ok} ~yes^no \\"
  expected <- "100\\% of \\$people \\& 50\\_50 \\#tests \\{ok\\} \\~yes\\^no \\textbackslash\\{\\}"
  expect_equal(latex_escape(input), expected)
})

test_that("latex_escape leaves normal text unchanged", {
  expect_equal(latex_escape("Hello World!"), "Hello World!")
})

test_that("latex_escape handles empty string", {
  expect_equal(latex_escape(""), "")
})


######### build_node_lines Tests #########

test_that("build_node_lines leaves global colors to the var style", {
  nodes <- list(
    list(name = "node1", x = 1, y = 2, fill = "red", draw = "black"),
    list(name = "node2", x = 3, y = 4, fill = "red")
  )
  lines <- build_node_lines(nodes, "red", "black", c(node1 = "A", node2 = "B"))
  expect_equal(
    lines,
    c("\\node[var] (node1) at (1,2) {A};", "\\node[var] (node2) at (3,4) {B};")
  )
})

test_that("build_node_lines adds non-global fill/draw correctly", {
  nodes <- list(list(
    name = "node1",
    x = 0,
    y = 0,
    fill = "blue",
    draw = "green"
  ))
  lines <- build_node_lines(nodes, "red", "black", c(node1 = "$X_1$"))
  expect_equal(
    lines,
    "\\node[var, fill=blue, draw=green] (node1) at (0,0) {$X_1$};"
  )
})


######### get_anchor_and_offset Tests #########

test_that("get_anchor_and_offset returns correct anchors for above", {
  res <- get_anchor_and_offset("above")
  expect_equal(res$anchor, "south")
  expect_equal(res$anchor_point, "north")
  expect_equal(res$dx, 0)
  expect_equal(res$dy, 0.2) # default offset
})

test_that("get_anchor_and_offset returns correct anchors for below", {
  res <- get_anchor_and_offset("below")
  expect_equal(res$anchor, "north")
  expect_equal(res$anchor_point, "south")
})

test_that("get_anchor_and_offset returns correct anchors for left", {
  res <- get_anchor_and_offset("left")
  expect_equal(res$anchor, "east")
  expect_equal(res$anchor_point, "west")
})

test_that("get_anchor_and_offset returns correct anchors for right", {
  res <- get_anchor_and_offset("right")
  expect_equal(res$anchor, "west")
  expect_equal(res$anchor_point, "east")
})

test_that("get_anchor_and_offset respects custom offset", {
  res <- get_anchor_and_offset("above", offset = 0.5)
  expect_equal(res$dy, 0.5)
  res <- get_anchor_and_offset("left", offset = 1)
  expect_equal(res$dx, -1)
})


############ build_tikz_styles Tests #########

test_that("build_tikz_styles defines var and link with no global colors", {
  expect_equal(
    build_tikz_styles(NULL, NULL, NULL),
    "\\tikzset{\n  var/.style={draw, circle},\n  link/.style={}\n}"
  )
})

test_that("build_tikz_styles puts global colors and arrow scale in the styles", {
  res <- build_tikz_styles("red", "blue", "green", arrow_scale = 3)
  expect_true(grepl(
    "var/.style={draw=blue, circle, fill=red}",
    res,
    fixed = TRUE
  ))
  expect_true(grepl(
    "link/.style={draw=green, arrows={[scale=3]}}",
    res,
    fixed = TRUE
  ))
  expect_false(grepl("tier", res, fixed = TRUE))
})

test_that("build_tikz_styles adds tier styles only when there are tiers", {
  res <- build_tikz_styles("red", NULL, NULL, tiers = TRUE)
  expect_true(grepl("var/.style={draw, circle, fill=red}", res, fixed = TRUE))
  expect_true(grepl(
    "tier/.style={draw, rectangle, fill=blue!20, rounded corners, inner sep=0.5cm}",
    res,
    fixed = TRUE
  ))
  expect_true(grepl("tier label/.style={}", res, fixed = TRUE))
})


########### extract_edges Tests #########

edge_grob <- function(col = NULL, lwd = NULL, length = NULL, type = "-->") {
  list(
    gp = list(col = col, lwd = lwd),
    arrow = list(length = length),
    edge_type = type
  )
}
ab <- data.frame(from = "A", to = "B")

test_that("extract_edges computes global arrow length correctly", {
  grobs <- list(
    edge_grob(length = 0.5),
    edge_grob(length = 0.5),
    edge_grob(length = 1)
  )
  result <- extract_edges(grobs, ab[c(1, 1, 1), ], rep(NA, 3), NULL)
  expect_equal(result$global_arrow_length, 0.5) # most common
  # only the edge that differs gets its own arrow scale
  expect_false(grepl("scale", result$edge_lines[1], fixed = TRUE))
  expect_true(grepl("arrows={[scale=1]}", result$edge_lines[3], fixed = TRUE))
})

test_that("extract_edges generates correct edge line with styles", {
  res <- extract_edges(
    list(edge_grob(col = "red", lwd = 1, length = 0.8)),
    ab,
    "bend left=10",
    global_edge_color = "blue"
  )
  expect_equal(
    res$edge_lines,
    "(A) edge[link, draw=red, line width=1, bend left=10, -Latex] (B)"
  )
  expect_equal(res$global_arrow_length, 0.8)

  # the global edge color is left to the link style
  res_blue <- extract_edges(list(edge_grob(col = "blue")), ab, NA, "blue")
  expect_equal(res_blue$edge_lines, "(A) edge[link, -Latex] (B)")
})

test_that("extract_edges falls back for unknown edge type with warning", {
  expect_warning(
    res <- extract_edges(list(edge_grob(type = "???")), ab, NA, NULL),
    "Unknown edge type"
  )
  expect_true(grepl("-Latex", res$edge_lines[1]))
})

test_that("extract_edges handles empty edge list", {
  res <- extract_edges(list(), ab[0, ], character(0), NULL)
  expect_equal(res$edge_lines, character(0))
  expect_equal(res$global_arrow_length, 1)
})

test_that("extract_edges ignores missing gp or arrow attributes", {
  res <- extract_edges(list(edge_grob()), ab, NA, NULL)
  expect_equal(res$edge_lines, "(A) edge[link, -Latex] (B)")
})


########### format_coord Tests #########

test_that("format_coord formats coordinates correctly", {
  expect_equal(format_coord(1), "1")
  expect_equal(format_coord(1.1), "1.1")
  expect_equal(format_coord(1.11), "1.11")
  expect_equal(format_coord(1.111), "1.111")
  expect_equal(format_coord(1.1111), "1.111")
})

########### tikz_edge_arrow / resolve_tikz_labels / format_coord #########

test_that("tikz_edge_arrow maps every caugi edge type in both styles", {
  types <- c("-->", "---", "<->", "o-o", "o->", "--o")
  expect_equal(
    vapply(
      types,
      tikz_edge_arrow,
      character(1),
      style = "classic",
      USE.NAMES = FALSE
    ),
    c("->", "-", "<->", "o-o", "o->", "-o")
  )
  expect_equal(
    vapply(
      types,
      tikz_edge_arrow,
      character(1),
      style = "default",
      USE.NAMES = FALSE
    ),
    c(
      "-Latex",
      "-",
      "{Latex}-{Latex}",
      "{Circle[open]}-{Circle[open]}",
      "{Circle[open]}-Latex",
      "-{Circle[open]}"
    )
  )
  expect_warning(
    res <- tikz_edge_arrow("???", style = "classic"),
    "Unknown edge type"
  )
  expect_equal(res, "->")
})

test_that("resolve_tikz_labels escapes defaults and keeps user labels verbatim", {
  res <- resolve_tikz_labels(c(a_1 = "$a_1$"), c("a_1", "b_1"), "node_labels")
  expect_equal(res, c(a_1 = "$a_1$", b_1 = "b\\_1"))
  expect_equal(resolve_tikz_labels(NULL, "x", "node_labels"), c(x = "x"))
})

test_that("format_coord never returns negative zero", {
  expect_equal(format_coord(-0), "0")
  expect_equal(format_coord(c(-0.15, 2, 1.5)), c("-0.15", "2", "1.5"))
})

########### Edge routing helpers #########

test_that("tikz_route_one bends away from a node in the way", {
  # obstacle just above the line -> bend right (below), and vice versa
  above <- tikz_route_one(
    0,
    0,
    4,
    0,
    data.frame(x = 2, y = 0.05, hw = 0.3, hh = 0.2)
  )
  below <- tikz_route_one(
    0,
    0,
    4,
    0,
    data.frame(x = 2, y = -0.05, hw = 0.3, hh = 0.2)
  )
  expect_lt(above, 0)
  expect_equal(below, -above)

  # obstacle far away, no obstacles, or a zero-length edge -> no bend
  far <- data.frame(x = 2, y = 3, hw = 0.3, hh = 0.2)
  expect_null(tikz_route_one(0, 0, 4, 0, far))
  expect_null(tikz_route_one(0, 0, 4, 0, far[0, ]))
  expect_null(tikz_route_one(1, 1, 1, 1, far))
})

test_that("tikz_route_one checks the default bend, not the straight line", {
  # obstacle below a long edge: the straight line clears it, but the default
  # bend right runs into it -> the same bend on the other side
  obstacle <- data.frame(x = 3.5, y = -0.6, hw = 0.25, hh = 0.22)
  expect_null(tikz_route_one(0, 0, 7, 0, obstacle))
  expect_equal(tikz_route_one(0, 0, 7, 0, obstacle, default = -10), 10)

  # a default bend that clears is kept (NULL = use the default)
  expect_null(tikz_route_one(0, 0, 7, 0, obstacle, default = 10))
})

test_that("tikz_route_one picks the bend closest in size to the default", {
  # obstacles on both sides: a 10 degree bend hits one of them either way, a
  # slightly smaller bend clears both
  two <- data.frame(x = 3.5, y = c(-0.6, 0.6), hw = 0.25, hh = 0.22)
  res <- tikz_route_one(0, 0, 7, 0, two, default = -10)
  expect_equal(abs(res), 7)

  # without flip the bend keeps its direction
  expect_equal(tikz_route_one(0, 0, 7, 0, two, default = -10, flip = FALSE), -7)
})

test_that("tikz_route_one uses the largest angle when nothing clears", {
  # an obstacle covering the whole area cannot be avoided
  huge <- data.frame(x = 2, y = 0, hw = 50, hh = 50)
  res <- tikz_route_one(0, 0, 4, 0, huge, max_angle = 20)
  expect_equal(abs(res), 20)
})

test_that("tikz_bend_options applies default bends and routes edges", {
  nodes <- data.frame(
    name = c("A", "B", "C"),
    x = c(0, 2, 4),
    y = 0,
    hw = 0.3,
    hh = 0.2
  )
  # A --> C runs through B and is bent; A --> B is straight
  edges <- data.frame(from = c("A", "A"), to = c("C", "B"), route = TRUE)
  res <- tikz_bend_options(edges, nodes, default = 0)
  expect_match(res[1], "^bend (left|right)=[0-9]+$")
  expect_true(is.na(res[2]))

  # default bends that clear keep their size; the two ends at A are spread
  # to opposite sides
  res <- tikz_bend_options(edges, nodes, default = -45)
  expect_equal(sort(tikz_option_angle(res)), c(-45, 45))

  # rows 1 and 3 form a bidirected pair: routed, but keep their direction;
  # row 4 has routing turned off and keeps its default unchecked
  edges <- data.frame(
    from = c("A", "A", "C", "A"),
    to = c("C", "B", "A", "C"),
    route = c(TRUE, TRUE, TRUE, FALSE)
  )
  res <- tikz_bend_options(edges, nodes, default = c(-10, 0, -10, -10))
  expect_match(res[c(1, 3)], "^bend right=[0-9]+$")
  expect_gt(tikz_option_angle(res[1]), -60)
  expect_lt(tikz_option_angle(res[1]), -10)
  expect_true(is.na(res[2]))
  expect_equal(res[4], "bend right=10")

  expect_equal(tikz_bend_options(edges[0, ], nodes, default = 0), character(0))
})

test_that("resolve_tikz_bend_by_edge matches edges in either direction", {
  from <- c("A", "B", "C")
  to <- c("B", "C", "B")
  expect_equal(resolve_tikz_bend_by_edge(NULL, from, to), rep(NA_real_, 3))

  # exact direction first; B --> A is not an edge, so it applies to A --> B
  # with the sign flipped
  res <- resolve_tikz_bend_by_edge(list(B = list(A = 20, C = 5)), from, to)
  expect_equal(res, c(-20, 5, NA))

  expect_error(
    resolve_tikz_bend_by_edge(list(A = list(C = 1)), from, to),
    "not in the graph: A - C",
    fixed = TRUE
  )
  expect_error(
    resolve_tikz_bend_by_edge(list(A = list(B = c(1, 2))), from, to),
    "`bend$A$B` must be a single number.",
    fixed = TRUE
  )
  expect_error(resolve_tikz_bend_by_edge(c(A = 1), from, to), "named list")
  expect_error(
    resolve_tikz_bend_by_edge(list(list(B = 1)), from, to),
    "named list"
  )
})

test_that("tikz_bend_options keeps given and unrouted bends exactly", {
  nodes <- data.frame(
    name = c("A", "B", "C"),
    x = c(0, 2, 4),
    y = 0,
    hw = 0.3,
    hh = 0.2
  )
  # A --> C runs through B and A --> B leaves A in nearly the same direction
  edges <- data.frame(from = c("A", "A"), to = c("C", "B"), route = TRUE)
  routed <- tikz_bend_options(edges, nodes, default = -10)
  expect_false(identical(routed, rep("bend right=10", 2)))

  edges$route <- FALSE
  expect_equal(
    tikz_bend_options(edges, nodes, default = -10),
    rep("bend right=10", 2)
  )

  edges$route <- TRUE
  res <- tikz_bend_options(
    edges,
    nodes,
    default = -10,
    bend_by_edge = list(A = list(C = 0))
  )
  expect_true(is.na(res[1]))
})

test_that("tikz_node_extent ignores LaTeX markup when sizing labels", {
  ext <- tikz_node_extent(c("$X_1$", "X1", "child\\_x1"), shape = "text")
  expect_equal(ext$hw[1], ext$hw[2])
  expect_gt(ext$hw[3], ext$hw[1])
  expect_true(all(ext$hh == ext$hh[1]))

  circ <- tikz_node_extent("X1", shape = "circle")
  expect_equal(circ$hw, circ$hh)
})

test_that("tikz_bidirected finds edges drawn in both directions", {
  expect_equal(
    tikz_bidirected(c("A", "B", "A"), c("B", "A", "C")),
    c(TRUE, TRUE, FALSE)
  )
})

test_that("tikz_option_angle and tikz_angle_option convert both ways", {
  opts <- c("bend left=10", "bend right=25", NA)
  expect_equal(tikz_option_angle(opts), c(10, -25, 0))
  expect_equal(tikz_angle_option(c(10, -25, 0)), opts)
})

test_that("tikz_fan_out spreads edge ends that leave a node together", {
  # B and C are almost in the same direction from A
  nodes <- data.frame(
    name = c("A", "B", "C"),
    x = c(0, 4, 4),
    y = c(0, 0, 0.5),
    hw = 0.2,
    hh = 0.2
  )
  edges <- data.frame(from = c("A", "A"), to = c("B", "C"))
  start <- function(opts) {
    base <- atan2(nodes$y[2:3], nodes$x[2:3]) * 180 / pi
    base + tikz_option_angle(opts)
  }
  opts <- rep("bend right=10", 2)
  expect_lt(abs(diff(start(opts))), 30)

  res <- tikz_fan_out(edges, nodes, opts, fixed = c(FALSE, FALSE))
  expect_false(identical(res, opts))
  expect_gte(abs(diff(start(res))), 30)

  # fixed and straight edges are never changed
  expect_equal(tikz_fan_out(edges, nodes, opts, fixed = c(TRUE, TRUE)), opts)
  straight <- c(NA_character_, NA_character_)
  expect_equal(
    tikz_fan_out(edges, nodes, straight, fixed = c(FALSE, FALSE)),
    straight
  )

  # well separated ends are left alone
  nodes$y[3] <- 4
  expect_equal(tikz_fan_out(edges, nodes, opts, fixed = c(FALSE, FALSE)), opts)
})
