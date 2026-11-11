#' @title Generate TikZ Code from a Causal Graph
#'
#' @description
#' Generates LaTeX TikZ code from a `Disco`, `Knowledge`, or
#' `caugi::caugi` object, preserving node positions, labels, and visual styles.
#' Edges are rendered with arrows, line widths, and colors.
#' The output is readable LaTeX code that can be
#' directly compiled or modified.
#'
#' @param x A `Disco`, `Knowledge`, or `caugi::caugi` object.
#' @param ... Additional arguments passed to [plot()] and [caugi::plot()].
#' @param style `"default"` mirrors `plot()`. `"classic"` is a minimal look
#'   with plain-text nodes, gray tier bands, and a time axis. See Details.
#' @param scale Numeric scalar. Scaling factor for node coordinates. Default is `10`.
#' @param full_doc Logical. If `TRUE` (default), generates a full standalone
#'   LaTeX document. If `FALSE`, returns only the `tikzpicture` environment;
#'   load `\usetikzlibrary{arrows.meta, bending, backgrounds, fit, calc}` in
#'   your preamble.
#' @param bend How much edges are bent, in degrees:
#'   * A number bends every edge by that angle; `0` draws edges straight, and
#'     a negative number bends them the other way (see Details). Edges may
#'     still be bent differently to avoid nodes.
#'   * A named list sets the bend of individual edges, in the same nested
#'     form as `edge_style$by_edge`: `list(A = list(B = 20, C = -10))` bends
#'     the edge from `A` to `B` 20 degrees to the left (`bend left=20`) and the
#'     edge from `A` to `C` 10 degrees to the right; `0` draws an edge
#'     straight. Left and right are as seen going from the first to the second
#'     node, whichever way the edge points. These edges are drawn exactly as
#'     given. Add `default = <number>` to set the bend of all other edges, e.g.
#'     `list(default = 20, A = list(B = 0))`.
#'
#'   Default is `0` (`10` for `style = "classic"`).
#' @param tier_label_pos Character string specifying the position of tier labels
#'   relative to the tier rectangles. Must be one of `"above"`, `"below"`, `"left"`, or `"right"`.
#'   Default is `"above"`. For `style = "classic"`, see Details.
#' @param node_labels,tier_labels Optional named character vectors of LaTeX
#'   labels for nodes or tiers, e.g. `c(child_x1 = "$X_1$")`. Unlabelled nodes
#'   and tiers use their name.
#' @param bend_edges `r lifecycle::badge("deprecated")` Use `bend` instead:
#'   `bend_edges = FALSE` is `bend = 0`, and `bend_edges = TRUE` is
#'   `bend = bend_angle`.
#' @param bend_angle `r lifecycle::badge("deprecated")` Use `bend` instead.
#'
#' @return A character string containing LaTeX TikZ code. Depending on
#'  `full_doc`, this is either:
#'  * a complete LaTeX document (`full_doc = TRUE`), or
#'  * only the `tikzpicture` environment (`full_doc = FALSE`).
#'
#' @details
#' The function calls `plot()` to generate a `caugi::caugi_plot` object, then
#' traverses the plot object's grob structure to extract nodes and
#' edges. Supported features include:
#'
#' * **Nodes**
#'   - Fill color and draw color (supports both named colors and custom RGB values)
#'   - Font size
#'   - Coordinates are scaled by the `scale` parameter
#'
#' * **Edges**
#'   - Line color and width
#'   - Arrow scale
#'   - Optional bending to reduce overlapping arrows
#'
#' The output starts with named styles (`var` for nodes, `link` for edges,
#' `tier` and `tier label` for tiers) for easy restyling, and edges are
#' connected to nodes by name rather than coordinates.
#'
#' ## Bent edges
#'
#' With a positive `bend` (or `default`), edges bend to the left when they
#' point to the right and vice versa, so they bulge upwards; with
#' `style = "classic"` they always bend to the right. A negative angle bends
#' them the other way. Edges in both directions (`A --> B` and `B --> A`) are
#' bent to opposite sides, by that angle, or if it is `0`, by `25` degrees
#' (`10` for `style = "classic"`).
#'
#' Like `plot()`, edges that would pass through another node are bent around
#' it. A bent edge that would pass through a node is bent the other way
#' instead, or, if that also hits a node, by the angle closest to its bend
#' that clears all nodes. Bent edges that leave a node in nearly the
#' same direction are spread apart, by bending them the other way or more.
#' Node sizes are estimated from the labels, so a bend may need a manual
#' tweak.
#'
#' To draw edges exactly as requested, turn both adjustments off with
#' `edge_style = list(route = FALSE)`, or for single edges with
#' `edge_style$by_edge`. Edges given in a `bend` list are always drawn exactly
#' as given.
#'
#' ## Classic style
#'
#' Adds a `time axis` style, and the spacing is set by the `x` and `y` options
#' of the `tikzpicture`. Tier labels go on the time axis: `"below"` (default)
#' or `"above"` for column tiers, `"left"` (default) or `"right"` for row
#' tiers.
#'
#' @example inst/roxygen-examples/make-tikz-example.R
#'
#' @export
make_tikz <- function(
  x,
  ...,
  style = c("default", "classic"),
  scale = 10,
  full_doc = TRUE,
  bend = NULL,
  tier_label_pos = c("above", "below", "left", "right"),
  node_labels = NULL,
  tier_labels = NULL,
  bend_edges = lifecycle::deprecated(),
  bend_angle = lifecycle::deprecated()
) {
  style <- match.arg(style)
  tier_label_pos_given <- !missing(tier_label_pos)
  tier_label_pos <- match.arg(tier_label_pos)
  if (style == "classic" && !tier_label_pos_given) {
    tier_label_pos <- NULL
  }
  bends <- resolve_tikz_bend(
    bend,
    bend_edges,
    bend_angle,
    style,
    user_env = parent.frame()
  )

  dots <- list(...)
  caugi_plot_obj <- plot(x, ...)

  if (inherits(x, "Disco")) {
    x <- x$knowledge
  }

  tier_node_map <- NULL

  if ("tiers" %in% names(dots)) {
    tier_node_map <- dots$tiers
  } else if (inherits(x, "Knowledge")) {
    tier_vector <- x$vars$tier

    if (anyNA(tier_vector)) {
      tier_node_map <- NULL
    } else {
      tier_node_map <- split(x$vars$var, x$vars$tier)
    }
  }

  .make_tikz(
    caugi_plot_obj,
    tier_node_map = tier_node_map,
    style = style,
    scale = scale,
    full_doc = full_doc,
    bend = bends$bend,
    pair_bend = bends$pair_bend,
    bend_by_edge = bends$by_edge,
    tier_label_pos = tier_label_pos,
    node_labels = node_labels,
    tier_labels = tier_labels
  )
}


#' @title Resolve the Bend Arguments of `make_tikz()`
#'
#' @description
#' Validates `bend`, splits a `bend` list into the angle for all edges
#' (`default`) and the per-edge angles, and maps the deprecated `bend_edges`
#' and `bend_angle` onto it. In a `bend` list, `default` is the angle for all
#' edges only if it is a single unnamed number; otherwise it is taken as a node
#' called `default`.
#'
#' @inheritParams make_tikz
#' @param user_env Environment of the `make_tikz()` call, passed to
#'   [lifecycle::deprecate_warn()].
#' @returns A list with `bend` (signed angle for every edge, `0` = straight),
#'   `pair_bend` (signed angle for edges drawn in both directions) and `by_edge`
#'   (per-edge angles, see `resolve_tikz_bend_by_edge()`, or `NULL`).
#' @keywords internal
#' @noRd
resolve_tikz_bend <- function(
  bend = NULL,
  bend_edges = lifecycle::deprecated(),
  bend_angle = lifecycle::deprecated(),
  style = c("default", "classic"),
  user_env = parent.frame()
) {
  style <- match.arg(style)
  pair_bend <- if (style == "classic") 10 else 25

  if (lifecycle::is_present(bend_angle)) {
    lifecycle::deprecate_warn(
      when = "1.3.0",
      what = "make_tikz(bend_angle)",
      with = "make_tikz(bend)",
      user_env = user_env
    )
    pair_bend <- bend_angle
  }
  if (lifecycle::is_present(bend_edges)) {
    lifecycle::deprecate_warn(
      when = "1.3.0",
      what = "make_tikz(bend_edges)",
      with = "make_tikz(bend)",
      user_env = user_env
    )
  }

  by_edge <- NULL
  if (is.list(bend)) {
    nms <- names(bend) %||% rep("", length(bend))
    is_default <- nms == "default" &
      vapply(
        bend,
        function(b) is.numeric(b) && length(b) == 1 && is.null(names(b)),
        logical(1)
      )
    by_edge <- bend[!is_default]
    if (length(by_edge) == 0) {
      by_edge <- NULL
    }
    bend <- if (any(is_default)) bend[[which(is_default)[1]]] else NULL
  }

  if (is.null(bend)) {
    bent <- if (lifecycle::is_present(bend_edges)) {
      isTRUE(bend_edges)
    } else {
      style == "classic"
    }
    bend <- if (bent) pair_bend else 0
  }
  if (!is.numeric(bend) || length(bend) != 1 || !is.finite(bend)) {
    stop(
      "`bend` must be a single number or a named list of edges, ",
      "e.g. `list(default = 20, A = list(B = 0))`.",
      call. = FALSE
    )
  }
  list(
    bend = bend,
    pair_bend = if (bend != 0) bend else pair_bend,
    by_edge = by_edge
  )
}




#' @title Generate TikZ Code from a Caugi Plot
#'
#' @description
#' Generates LaTeX TikZ code from a `caugi::caugi_plot` object, preserving
#' node positions, labels, and visual styles. Edges are rendered with arrows,
#' line widths, and colors. The output is readable LaTeX code that can be
#' directly compiled or modified.
#'
#' @inheritParams make_tikz
#' @param caugi_plot_obj A `caugi::caugi_plot` object.
#' @param tier_node_map Optional named list mapping tier names to vectors of
#'  node names. If provided, tier rectangles and labels are added to the TikZ
#'  output. Default is `NULL`.
#' @param bend Angle in degrees for every edge (`0` = straight); negative
#'   bends the other way.
#' @param pair_bend Angle in degrees for edges drawn in both directions;
#'   negative bends the other way.
#' @param bend_by_edge `NULL` or per-edge angles (see
#'   `resolve_tikz_bend_by_edge()`).
#'
#' @return A character string containing LaTeX TikZ code. Depending on
#'   `full_doc`, this is either:
#'   * a complete LaTeX document (`full_doc = TRUE`), or
#'   * only the `tikzpicture` environment (`full_doc = FALSE`).
#'
#' @details
#' The function traverses the plot object's grob structure to extract nodes and
#' edges. Supported features include:
#'
#' * **Nodes**
#'   - Fill color and draw color (supports both named colors and custom RGB values)
#'   - Font size
#'   - Coordinates are scaled by the `scale` parameter
#'
#' * **Edges**
#'   - Line color and width
#'   - Arrow scale
#'   - Optional bending to reduce overlapping arrows
#'
#' The generated TikZ code uses global style settings, and edges are connected
#' to nodes by name (as opposed to hard-coded coordinates), making it easy to
#' modify the output further if needed.
#'
#' @example inst/roxygen-examples/make-tikz-example.R
#'
#' @keywords internal
#' @noRd
.make_tikz <- function(
  caugi_plot_obj,
  tier_node_map = NULL,
  style = c("default", "classic"),
  scale = 10,
  full_doc = TRUE,
  bend = 0,
  pair_bend = 25,
  bend_by_edge = NULL,
  tier_label_pos = c("above", "below", "left", "right"),
  node_labels = NULL,
  tier_labels = NULL
) {
  style <- match.arg(style)
  if (!is.null(tier_label_pos)) {
    tier_label_pos <- match.arg(tier_label_pos)
  }

  g <- caugi_plot_obj@grob$children$caugi.graph
  node_names <- vapply(
    extract_nodes(g$children$node_gtree$children, scale = 1),
    function(n) n$name,
    character(1)
  )
  node_labels <- resolve_tikz_labels(node_labels, node_names, "node_labels")
  tier_labels <- resolve_tikz_labels(
    tier_labels,
    names(tier_node_map),
    "tier_labels"
  )

  if (style == "classic") {
    return(make_tikz_classic(
      caugi_plot_obj = caugi_plot_obj,
      tier_node_map = tier_node_map,
      scale = scale,
      full_doc = full_doc,
      bend = bend,
      pair_bend = pair_bend,
      bend_by_edge = bend_by_edge,
      tier_label_pos = tier_label_pos,
      node_labels = node_labels,
      tier_labels = tier_labels
    ))
  }

  .make_tikz_core(
    caugi_plot_obj,
    scale = scale,
    tier_node_map = tier_node_map,
    full_doc = full_doc,
    bend = bend,
    pair_bend = pair_bend,
    bend_by_edge = bend_by_edge,
    tier_label_pos = tier_label_pos %||% "above",
    node_labels = node_labels,
    tier_labels = tier_labels
  )
}

#' @title Core TikZ Generation Logic
#' @inheritParams .make_tikz
#' @returns A character string containing LaTeX TikZ code.
#' @keywords internal
#' @noRd
.make_tikz_core <- function(
  caugi_plot_obj,
  scale = 10,
  tier_node_map = NULL,
  full_doc = TRUE,
  bend = 0,
  pair_bend = 25,
  bend_by_edge = NULL,
  tier_label_pos = "above",
  node_labels = NULL,
  tier_labels = NULL
) {
  stopifnot(inherits(caugi_plot_obj, "caugi::caugi_plot"))

  g <- caugi_plot_obj@grob$children$caugi.graph
  node_grob_children <- g$children$node_gtree$children
  edge_grob_children <- g$children[grep("^edge", names(g$children))]

  # ---- Extract nodes ----
  nodes <- extract_nodes(node_grob_children, scale)

  # ---- Global node colors ----
  global_node_fill <- compute_global_color(nodes, "fill")
  global_node_draw <- compute_global_color(nodes, "draw")

  # ---- Global edge color ----
  edge_dummy_nodes <- lapply(edge_grob_children, function(e) {
    col <- if (!is.null(e$gp$col) && length(e$gp$col) > 0) {
      rcolor_to_tikz(e$gp$col)
    } else {
      list(tikz = NULL)
    }
    list(style = list(draw = col))
  })
  global_edge_color <- compute_global_color(edge_dummy_nodes, "draw")

  # ---- Node and edge lines ----
  node_lines <- build_node_lines(
    nodes,
    global_node_fill,
    global_node_draw,
    labels = node_labels
  )
  # ---- Route edges around other nodes (as caugi::plot() does) ----
  unscaled <- extract_nodes(node_grob_children, scale = 1)
  edge_records <- tikz_edge_records(
    edge_grob_children,
    data.frame(
      name = vapply(unscaled, function(n) n$name, character(1)),
      x = vapply(unscaled, function(n) n$x, numeric(1)),
      y = vapply(unscaled, function(n) n$y, numeric(1)),
      stringsAsFactors = FALSE
    )
  )
  node_names <- vapply(nodes, function(n) n$name, character(1))
  labels <- if (is.null(node_labels)) {
    latex_escape(node_names)
  } else {
    unname(node_labels[node_names])
  }
  nodes_cm <- data.frame(
    name = node_names,
    x = vapply(nodes, function(n) n$x, numeric(1)),
    y = vapply(nodes, function(n) n$y, numeric(1)),
    tikz_node_extent(labels, shape = "circle")
  )
  # Default bend: by the x order of the end nodes. Edges in both directions
  # always bend left, which puts the two on opposite sides.
  from_x <- nodes_cm$x[match(edge_records$from, nodes_cm$name)]
  to_x <- nodes_cm$x[match(edge_records$to, nodes_cm$name)]
  bidir <- tikz_bidirected(edge_records$from, edge_records$to)
  default_angle <- ifelse(
    bidir,
    pair_bend,
    ifelse(to_x >= from_x, bend, -bend)
  )
  route_options <- tikz_bend_options(
    edge_records,
    nodes_cm,
    default = default_angle,
    bend_by_edge = bend_by_edge
  )

  # route_options holds every bend (NA = straight), so extract_edges() must
  # not add its own.
  edge_info <- extract_edges(
    edge_grob_children,
    nodes,
    scale,
    bend_edges = FALSE,
    bend_angle = 0,
    global_edge_color,
    route_options = route_options
  )
  edge_lines <- edge_info$edge_lines
  global_arrow_length <- edge_info$global_arrow_length

  # ---- Optional tier rectangles and labels ----
  tier_rect_lines <- tier_label_lines <- character(0)
  if (!is.null(tier_node_map)) {
    stopifnot(is.list(tier_node_map) && length(tier_node_map) > 0)
    tier_rect_lines <- lapply(names(tier_node_map), function(tier_name) {
      node_names <- tier_node_map[[tier_name]]
      sprintf(
        "\\node[tier, fit=(%s)] (%s) {};",
        paste(node_names, collapse = ")("),
        tier_name
      )
    })
    tier_label_lines <- lapply(names(tier_node_map), function(tier_name) {
      pos_info <- get_anchor_and_offset(tier_label_pos, offset = 0.2)
      sprintf(
        "\\node[tier label, anchor=%s] at ($(%s.%s)+(%scm,%scm)$) {%s};",
        pos_info$anchor,
        tier_name,
        pos_info$anchor_point,
        pos_info$dx,
        pos_info$dy,
        tier_labels[[tier_name]] %||% latex_escape(tier_name)
      )
    })
  }

  # ---- Named TikZ styles ----
  tikz_styles <- build_tikz_styles(
    global_node_fill = global_node_fill,
    global_node_draw = global_node_draw,
    global_edge_color = global_edge_color,
    arrow_scale = global_arrow_length,
    tiers = length(tier_rect_lines) > 0
  )

  generator_line <- paste0(
    "%%% Generated by causalDisco (version ",
    utils::packageVersion("causalDisco"),
    ")"
  )

  # ---- Assemble TikZ ----
  assemble_tikz <- function(doc = TRUE) {
    lines <- c(
      if (doc) {
        c(
          generator_line,
          "\\documentclass[tikz,border=2mm]{standalone}",
          "\\usetikzlibrary{arrows.meta, bending, backgrounds, fit, calc}",
          "",
          "\\begin{document}"
        )
      } else {
        generator_line
      },

      tikz_styles,

      "\\begin{tikzpicture}",

      # ---- Nodes ----
      node_lines,

      # ---- Optional tier rectangles ----
      if (length(tier_rect_lines)) {
        c(
          "\\begin{scope}[on background layer]",
          tier_rect_lines,
          "\\end{scope}"
        )
      },

      # ---- Optional tier labels ----
      tier_label_lines,

      # ---- Edges ----
      sprintf("\\path %s;", paste(edge_lines, collapse = "\n      ")),

      "\\end{tikzpicture}",
      if (doc) "\\end{document}"
    )

    paste(unlist(lines), collapse = "\n")
  }

  assemble_tikz(full_doc)
}
