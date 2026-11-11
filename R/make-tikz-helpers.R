#' @title Convert R Color to TikZ Color Specification
#'
#' @param r_col A color name or hex code in R.
#' @returns The TikZ color: a TikZ color name, or a custom RGB specification
#'   such as `{rgb:red,0.071;green,0.204;blue,0.337}`. `NULL` for no color.
#' @keywords internal
#' @noRd
rcolor_to_tikz <- function(r_col) {
  if (length(r_col) == 0) {
    return(NULL)
  }
  r_col <- tolower(r_col)
  if (r_col == "lightgrey") {
    r_col <- "lightgray"
  }

  tikz_defaults <- c(
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

  if (r_col %in% tikz_defaults) {
    return(r_col)
  }

  rgb_vals <- grDevices::col2rgb(r_col) / 255
  sprintf(
    "{rgb:red,%.3f;green,%.3f;blue,%.3f}",
    rgb_vals[1],
    rgb_vals[2],
    rgb_vals[3]
  )
}

#' @title Extract TikZ Node Information
#' @param node_grob_children A list of node grob children.
#' @param scale Numeric scalar. Scaling factor for node coordinates.
#' @returns A list of node objects with `name`, `x`, `y`, and the TikZ colors
#'   `fill` and `draw` (`NULL` if unset).
#' @keywords internal
#' @noRd
extract_nodes <- function(node_grob_children, scale) {
  circle_nodes <- node_grob_children[grepl(
    "^node\\.",
    names(node_grob_children)
  )]
  text_grobs <- node_grob_children[grepl(
    "^label\\.",
    names(node_grob_children)
  )]
  label_map <- stats::setNames(
    lapply(text_grobs, function(x) x$label),
    gsub("label\\.", "node.", names(text_grobs))
  )

  lapply(circle_nodes, function(node) {
    list(
      name = label_map[[node$name]],
      x = as.numeric(node$x) * scale,
      y = as.numeric(node$y) * scale,
      fill = rcolor_to_tikz(node$gp$fill),
      draw = rcolor_to_tikz(node$gp$col)
    )
  })
}


#' @title Most Common Value
#' @param x A vector; `NA`s are ignored.
#' @returns The most common value of `x` (the first one in sorted order on
#'   ties), or `NULL` if there is none.
#' @keywords internal
#' @noRd
most_common <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(NULL)
  }
  counts <- table(x)
  names(counts)[which.max(counts)]
}


#' @title Compute Global Color for Nodes
#' @param nodes A list of node objects from `extract_nodes()`.
#' @param color_type A character string, either `"fill"` or `"draw"`.
#' @returns The most common TikZ color for the given `color_type`, or `NULL`
#'   if no color is specified.
#' @keywords internal
#' @noRd
compute_global_color <- function(nodes, color_type) {
  most_common(vapply(
    nodes,
    function(n) n[[color_type]] %||% NA_character_,
    character(1)
  ))
}


#' @title Node Positions as a Data Frame
#' @param nodes A list of node objects from `extract_nodes()`.
#' @returns A data frame with columns `name`, `x`, `y`.
#' @keywords internal
#' @noRd
tikz_node_table <- function(nodes) {
  data.frame(
    name = vapply(nodes, function(n) n$name, character(1)),
    x = vapply(nodes, function(n) n$x, numeric(1)),
    y = vapply(nodes, function(n) n$y, numeric(1)),
    stringsAsFactors = FALSE
  )
}


#' @title Escape LaTeX Special Characters
#' @param x A character string.
#' @returns The input string with LaTeX special characters escaped.
#' @keywords internal
#' @noRd
latex_escape <- function(x) {
  # Escapes _, %, &, #, $, {, }, ~, ^, \ (most common LaTeX specials)
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([_%#&$^{}~])", "\\\\\\1", x)
  x
}


#' @title Build TikZ Node Lines
#'
#' @param nodes A list of node objects from `extract_nodes()`.
#' @param global_node_fill Global fill color for nodes (part of the `var` style).
#' @param global_node_draw Global draw color for nodes (part of the `var` style).
#' @param labels Named character vector of LaTeX node labels, keyed by node
#'   name (see `resolve_tikz_labels()`).
#'
#' @returns A character vector of TikZ node lines. Each node uses the `var`
#'   style, followed by any fill/draw colors that differ from the global ones.
#' @keywords internal
#' @noRd
build_node_lines <- function(
  nodes,
  global_node_fill,
  global_node_draw,
  labels
) {
  vapply(
    nodes,
    function(n) {
      style <- c(
        "var",
        if (!is.null(n$fill) && !identical(n$fill, global_node_fill)) {
          paste0("fill=", n$fill)
        },
        if (!is.null(n$draw) && !identical(n$draw, global_node_draw)) {
          paste0("draw=", n$draw)
        }
      )
      sprintf(
        "\\node[%s] (%s) at (%s,%s) {%s};",
        paste(style, collapse = ", "),
        n$name,
        format_coord(n$x),
        format_coord(n$y),
        labels[[n$name]]
      )
    },
    character(1)
  )
}

#' @title Get Anchor and Offset for Tier Labels
#' @param pos A character string specifying the position: "above", "below", "left", or "right".
#' @param offset Numeric scalar. Offset distance for the label.
#' @returns A list with `anchor`, `anchor_point`, `dx`, and `dy` for positioning the label.
#' @keywords internal
#' @noRd
get_anchor_and_offset <- function(pos, offset = 0.2) {
  switch(
    pos,
    above = list(anchor = "south", anchor_point = "north", dx = 0, dy = offset),
    below = list(
      anchor = "north",
      anchor_point = "south",
      dx = 0,
      dy = -offset
    ),
    left = list(anchor = "east", anchor_point = "west", dx = -offset, dy = 0),
    right = list(anchor = "west", anchor_point = "east", dx = offset, dy = 0)
  )
}


#' @title Build the Named TikZ Styles of the Default Style
#'
#' @description
#' Defines `var` (nodes), `link` (edges) and, with tiers, `tier` and
#' `tier label`, so the figure can be restyled in one place.
#'
#' @param global_node_fill Global fill color for nodes, or `NULL`.
#' @param global_node_draw Global draw color for nodes, or `NULL`.
#' @param global_edge_color Global color for edges, or `NULL`.
#' @param arrow_scale Scale of the arrow tips.
#' @param tiers Logical; whether to define the tier styles.
#'
#' @returns A character string with a `\tikzset{...}` block.
#' @keywords internal
#' @noRd
build_tikz_styles <- function(
  global_node_fill,
  global_node_draw,
  global_edge_color,
  arrow_scale = 1,
  tiers = FALSE
) {
  opts <- function(...) paste(c(...), collapse = ", ")
  var <- opts(
    if (is.null(global_node_draw)) {
      "draw"
    } else {
      paste0("draw=", global_node_draw)
    },
    "circle",
    if (!is.null(global_node_fill)) paste0("fill=", global_node_fill)
  )
  link <- opts(
    if (!is.null(global_edge_color)) paste0("draw=", global_edge_color),
    if (arrow_scale != 1) paste0("arrows={[scale=", arrow_scale, "]}")
  )
  styles <- c(
    sprintf("  var/.style={%s}", var),
    sprintf("  link/.style={%s}", link),
    if (tiers) {
      c(
        "  tier/.style={draw, rectangle, fill=blue!20, rounded corners, inner sep=0.5cm}",
        "  tier label/.style={}"
      )
    }
  )
  paste(
    c("\\tikzset{", paste(styles, collapse = ",\n"), "}"),
    collapse = "\n"
  )
}

#' @title Extract Edge Records from Caugi Edge Grobs
#' @param edge_grob_children A list of edge grobs.
#' @param pos Data frame with `name`, `x`, `y` (unscaled plot coordinates).
#' @returns A data frame with columns `from`, `to`, `type`, `col` (TikZ color
#'   or `NA` for the default), and `route` (whether caugi routes the edge
#'   around other nodes).
#' @keywords internal
#' @noRd
tikz_edge_records <- function(edge_grob_children, pos) {
  if (length(edge_grob_children) == 0) {
    return(data.frame(
      from = character(0),
      to = character(0),
      type = character(0),
      col = character(0),
      route = logical(0),
      stringsAsFactors = FALSE
    ))
  }
  find_node <- function(x, y) {
    pos$name[which(
      abs(pos$x - as.numeric(x)) < 1e-9 & abs(pos$y - as.numeric(y)) < 1e-9
    )[1]]
  }
  recs <- lapply(edge_grob_children, function(e) {
    tk <- rcolor_to_tikz(e$gp$col)
    data.frame(
      from = find_node(e$x0, e$y0),
      to = find_node(e$x1, e$y1),
      type = e$edge_type %||% "-->",
      col = if (is.null(tk) || tk == "black") NA_character_ else tk,
      route = isTRUE(e$route),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, recs)
}


#' @title Build TikZ Edge Lines (Default Style)
#'
#' @param edge_grob_children A list of edge grob children.
#' @param edges Data frame from `tikz_edge_records()`, one row per grob.
#' @param bend_options Character vector, one per edge, of bend options (e.g.
#'   `"bend left=23"`) or `NA` (straight), from `tikz_bend_options()`.
#' @param global_edge_color Global color for edges (part of the `link` style).
#'
#' @returns A list with two elements:
#' * `edge_lines`: TikZ edge lines, each starting with the `link` style.
#' * `global_arrow_length`: The global arrow length used.
#' @keywords internal
#' @noRd
extract_edges <- function(
  edge_grob_children,
  edges,
  bend_options,
  global_edge_color
) {
  arrow_length <- function(e) {
    len <- e$arrow$length
    if (is.null(len) || length(len) == 0) NA_real_ else as.numeric(len)
  }
  global_arrow_length <- as.numeric(
    most_common(vapply(edge_grob_children, arrow_length, numeric(1))) %||% 1
  )

  edge_lines <- vapply(
    seq_along(edge_grob_children),
    function(i) {
      edge <- edge_grob_children[[i]]
      col <- rcolor_to_tikz(edge$gp$col)
      len <- arrow_length(edge)
      style <- c(
        "link",
        if (!is.null(col) && !identical(col, global_edge_color)) {
          paste0("draw=", col)
        },
        if (length(edge$gp$lwd) > 0) paste0("line width=", edge$gp$lwd),
        if (!is.na(len) && len != global_arrow_length) {
          paste0("arrows={[scale=", len, "]}")
        },
        if (!is.na(bend_options[i])) bend_options[i],
        tikz_edge_arrow(edge$edge_type, style = "default")
      )
      sprintf(
        "(%s) edge[%s] (%s)",
        edges$from[i],
        paste(style, collapse = ", "),
        edges$to[i]
      )
    },
    character(1)
  )

  list(
    edge_lines = edge_lines,
    global_arrow_length = global_arrow_length
  )
}

#' @title Map a Caugi Edge Type to a TikZ Arrow Specification
#'
#' @param edge_type A caugi edge type, e.g. `"-->"`, `"o->"`.
#' @param style `"default"` uses explicit `Latex` and `Circle[open]` tips;
#'   `"classic"` uses the `>` and `o` tips defined in the classic preamble.
#' @returns A TikZ arrow specification string. Unknown edge types fall back to
#'   a directed arrow with a warning.
#' @keywords internal
#' @noRd
tikz_edge_arrow <- function(edge_type, style = c("default", "classic")) {
  style <- match.arg(style)
  specs <- if (style == "default") {
    c(
      "-->" = "-Latex",
      "---" = "-",
      "<->" = "{Latex}-{Latex}",
      "o-o" = "{Circle[open]}-{Circle[open]}",
      "o->" = "{Circle[open]}-Latex",
      "--o" = "-{Circle[open]}"
    )
  } else {
    c(
      "-->" = "->",
      "---" = "-",
      "<->" = "<->",
      "o-o" = "o-o",
      "o->" = "o->",
      "--o" = "-o"
    )
  }
  if (!is.null(edge_type) && edge_type %in% names(specs)) {
    return(unname(specs[edge_type]))
  }
  warning(paste(
    "Unknown edge type:",
    edge_type,
    "- using",
    sprintf("'%s'", specs[["-->"]]),
    "as fallback."
  ))
  unname(specs[["-->"]])
}

#' @title Resolve User-Supplied TikZ Labels
#'
#' @param labels `NULL`, or a named character vector (or named list of
#'   strings) mapping keys to LaTeX labels. Labels are used verbatim.
#' @param keys Character vector of valid keys (node or tier names).
#' @param arg Argument name, used in error messages.
#' @returns A named character vector with one label per key. Keys without a
#'   user-supplied label get their LaTeX-escaped name.
#' @keywords internal
#' @noRd
resolve_tikz_labels <- function(labels, keys, arg) {
  out <- stats::setNames(latex_escape(keys), keys)
  if (is.null(labels)) {
    return(out)
  }
  if (is.list(labels)) {
    labels <- unlist(labels)
  }
  if (
    !is.character(labels) ||
      is.null(names(labels)) ||
      any(names(labels) == "")
  ) {
    stop(
      sprintf("`%s` must be a named character vector.", arg),
      call. = FALSE
    )
  }
  unknown <- setdiff(names(labels), keys)
  if (length(unknown) > 0) {
    stop(
      sprintf(
        "`%s` contains names that are not in the graph: %s",
        arg,
        paste(unknown, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  out[names(labels)] <- labels
  out
}

#' @title Format Coordinate for TikZ
#'
#' @param coord A numeric coordinate.
#'
#' @returns A character string rounded to at most 3 decimal places,
#'   with trailing zeros (and any trailing decimal point) removed.
#' @keywords internal
#' @noRd
format_coord <- function(x) {
  out <- sprintf("%.3f", x + 0) # + 0 turns -0 into 0
  sub("\\.?0+$", "", out)
}
