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
#' @param scale Numeric scalar. Scaling factor for node coordinates. Default is `10`.
#' @param full_doc Logical. If `TRUE` (default), generates a full standalone
#'   LaTeX document. If `FALSE`, returns only the `tikzpicture` environment;
#'   load `\usetikzlibrary{arrows.meta, bending, backgrounds, fit, calc}` in
#'   your preamble.
#' @param bend_edges Logical. If `TRUE`, all edges are bent by `bend_angle`.
#'   Default is `FALSE` (`TRUE` for `style = "classic"`). Edges through other
#'   nodes and edges in both directions are always bent.
#' @param bend_angle Numeric scalar. Angle in degrees for bending arrows when
#'   `bend_edges = TRUE`. Default is `25` (`10` for `style = "classic"`).
#' @param tier_label_pos Character string specifying the position of tier labels
#'   relative to the tier rectangles. Must be one of `"above"`, `"below"`, `"left"`, or `"right"`.
#'   Default is `"above"`. For `style = "classic"`, see Details.
#' @param style `"default"` mirrors `plot()`. `"classic"` is a minimal look
#'   with plain-text nodes, gray tier bands, and a time axis. See Details.
#' @param node_labels,tier_labels Optional named character vectors of LaTeX
#'   labels for nodes or tiers, e.g. `c(child_x1 = "$X_1$")`. Unlabelled nodes
#'   and tiers use their name.
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
#' Like `plot()`, edges that would pass through another node are bent around
#' it. Node sizes are estimated from the labels, so the bend may need a manual
#' tweak. Use `edge_style = list(route = FALSE)` to turn this off. Bent edges
#' that leave a node in nearly the same direction are spread apart.
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
  bend_edges = FALSE,
  bend_angle = 25,
  tier_label_pos = c("above", "below", "left", "right"),
  node_labels = NULL,
  tier_labels = NULL
) {
  style <- match.arg(style)
  tier_label_pos_given <- !missing(tier_label_pos)
  tier_label_pos <- match.arg(tier_label_pos)
  if (style == "classic") {
    if (missing(bend_edges)) {
      bend_edges <- TRUE
    }
    if (missing(bend_angle)) {
      bend_angle <- 10
    }
    if (!tier_label_pos_given) {
      tier_label_pos <- NULL
    }
  }
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
    bend_edges = bend_edges,
    bend_angle = bend_angle,
    tier_label_pos = tier_label_pos,
    node_labels = node_labels,
    tier_labels = tier_labels
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
  bend_edges = FALSE,
  bend_angle = 25,
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
      bend_edges = bend_edges,
      bend_angle = bend_angle,
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
    bend_edges = bend_edges,
    bend_angle = bend_angle,
    tier_label_pos = tier_label_pos %||% "above",
    node_labels = node_labels,
    tier_labels = tier_labels
  )
}

#' @title Core TikZ Generation Logic
#' @inheritParams make_tikz
#' @returns A character string containing LaTeX TikZ code.
#' @keywords internal
#' @noRd
.make_tikz_core <- function(
  caugi_plot_obj,
  scale = 10,
  tier_node_map = NULL,
  full_doc = TRUE,
  bend_edges = FALSE,
  bend_angle = 25,
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
  route_options <- tikz_route_options(
    edge_records,
    nodes_cm,
    bend_edges = bend_edges,
    bend_angle = bend_angle
  )
  # Routed edges and edges in both directions keep their bend direction.
  bidir <- tikz_bidirected(edge_records$from, edge_records$to)
  fixed <- !is.na(route_options) | bidir
  unbent <- is.na(route_options)
  if (bend_edges) {
    # Bend all edges, direction by the x order of the end nodes.
    from_x <- nodes_cm$x[match(edge_records$from, nodes_cm$name)]
    to_x <- nodes_cm$x[match(edge_records$to, nodes_cm$name)]
    route_options[unbent] <- paste0(
      ifelse(to_x >= from_x, "bend left=", "bend right="),
      format_coord(bend_angle)
    )[unbent]
  } else {
    # Edges in both directions: bend left on both puts them on opposite sides.
    route_options[unbent & bidir] <- paste0(
      "bend left=",
      format_coord(bend_angle)
    )
  }
  route_options <- tikz_fan_out(edge_records, nodes_cm, route_options, fixed)

  edge_info <- extract_edges(
    edge_grob_children,
    nodes,
    scale,
    bend_edges,
    bend_angle,
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
