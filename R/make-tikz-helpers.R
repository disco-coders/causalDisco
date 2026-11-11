#' @title Convert R Color to TikZ Color Specification
#'
#' @param r_col A color name or hex code in R.
#' @returns A list with two elements:
#' * `tikz`: The TikZ color specification string.
#' * `r_col`: The original R color if a custom RGB specification was used, otherwise `NULL`.
#' @keywords internal
#' @noRd
rcolor_to_tikz <- function(r_col) {
  if (is.null(r_col) || length(r_col) == 0) {
    return(list(tikz = NULL, r_col = NULL))
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
    return(list(tikz = r_col, r_col = NULL))
  }

  rgb_vals <- grDevices::col2rgb(r_col) / 255
  tikz_str <- sprintf(
    "{rgb:red,%.3f;green,%.3f;blue,%.3f}",
    rgb_vals[1],
    rgb_vals[2],
    rgb_vals[3]
  )
  list(tikz = tikz_str, r_col = r_col)
}

#' @title Extract TikZ Node Information
#' @param node_grob_children A list of node grob children.
#' @param scale Numeric scalar. Scaling factor for node coordinates.
#' @returns A list of node objects with `name`, `x`, `y`, `style`, and `label`.
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

  nodes <- lapply(circle_nodes, function(node) {
    gp <- node$gp
    style <- list()
    if (!is.null(gp$fill) && length(gp$fill) > 0) {
      style$fill <- rcolor_to_tikz(gp$fill)
    }
    if (!is.null(gp$col) && length(gp$col) > 0) {
      style$draw <- rcolor_to_tikz(gp$col)
    }
    list(
      name = label_map[[node$name]],
      x = as.numeric(node$x) * scale,
      y = as.numeric(node$y) * scale,
      style = style,
      label = label_map[[node$name]]
    )
  })
  nodes
}


#' @title Compute Global Color for Nodes or Edges
#' @param nodes A list of node or edge objects with `style`.
#' @param color_type A character string, either `"fill"` or `"draw"`.
#' @returns The most common TikZ color specification for the given `color_type`,
#' or `NULL` if no color is specified.
#' @keywords internal
#' @noRd
compute_global_color <- function(nodes, color_type) {
  vals <- sapply(nodes, function(n) {
    if (
      !is.null(n$style[[color_type]]) && !is.null(n$style[[color_type]]$tikz)
    ) {
      n$style[[color_type]]$tikz
    } else {
      NA
    }
  })
  vals <- vals[!is.na(vals)]
  if (length(vals) > 0) {
    names(sort(table(vals), decreasing = TRUE))[1]
  } else {
    NULL
  }
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
#' @param nodes A list of node objects with `name`, `x`, `y`, `style`, and `label`.
#' @param global_node_fill Global fill color for nodes (part of the `var` style).
#' @param global_node_draw Global draw color for nodes (part of the `var` style).
#' @param labels Optional named character vector of LaTeX node labels, keyed by
#'   node name. If `NULL`, the escaped node label is used.
#'
#' @returns A character vector of TikZ node lines. Each node uses the `var`
#'   style, followed by any fill/draw colors that differ from the global ones
#'   and any other styles.
#' @keywords internal
#' @noRd
build_node_lines <- function(
  nodes,
  global_node_fill,
  global_node_draw,
  labels = NULL
) {
  unlist(lapply(nodes, function(n) {
    style_list <- "var"
    for (sty_name in names(n$style)) {
      if (sty_name %in% c("fill", "draw")) {
        global_val <- if (sty_name == "fill") {
          global_node_fill
        } else {
          global_node_draw
        }
        val <- n$style[[sty_name]]$tikz
        if (!is.null(val) && !identical(val, global_val)) {
          style_list <- c(style_list, paste0(sty_name, "=", val))
        }
      } else {
        style_list <- c(
          style_list,
          paste0(sty_name, "=", n$style[[sty_name]])
        )
      }
    }
    sprintf(
      "\\node[%s] (%s) at (%s,%s) {%s};",
      paste(style_list, collapse = ", "),
      n$name,
      format_coord(n$x),
      format_coord(n$y),
      if (is.null(labels)) latex_escape(n$label) else labels[[n$name]]
    )
  }))
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
    right = list(anchor = "west", anchor_point = "east", dx = offset, dy = 0),
    stop("tier_label_pos must be one of: above, below, left, right")
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

#' @title Extract TikZ Edge Lines
#'
#' @param edge_grob_children A list of edge grob children.
#' @param nodes A list of node objects with `name`, `x`, `y`, `style`, and `label`.
#' @param scale Numeric scalar. Scaling factor for node coordinates.
#' @param bend_edges Logical. If `TRUE`, edges are drawn with bent arrows.
#' @param bend_angle Numeric scalar. Angle in degrees for bending arrows.
#' @param global_edge_color Global color for edges.
#' @param route_options Optional character vector, one per edge, of routed
#'   bend options (e.g. `"bend left=23"`) or `NA`. A routed bend replaces the
#'   bend from `bend_edges`.
#'
#' @returns A list with two elements:
#' * `edge_lines`: TikZ edge lines, each starting with the `link` style.
#' * `global_arrow_length`: The global arrow length used.
#' @keywords internal
#' @noRd
extract_edges <- function(
  edge_grob_children,
  nodes,
  scale,
  bend_edges,
  bend_angle,
  global_edge_color,
  route_options = NULL
) {
  # ---- Determine global arrow scale (numeric, unit-safe) ----
  edge_lengths <- sapply(edge_grob_children, function(e) {
    if (!is.null(e$arrow$length) && length(e$arrow$length) > 0) {
      as.numeric(e$arrow$length)
    } else {
      NA_real_
    }
  })

  edge_lengths <- edge_lengths[!is.na(edge_lengths)]
  if (length(edge_lengths) > 0) {
    global_arrow_length <- as.numeric(names(sort(
      table(edge_lengths),
      decreasing = TRUE
    ))[1])
  } else {
    global_arrow_length <- 1
  }

  # ---- Build edges ----
  edge_lines <- sapply(seq_along(edge_grob_children), function(i) {
    edge <- edge_grob_children[[i]]
    route_option <- if (is.null(route_options)) NA else route_options[i]

    # Resolve from/to nodes
    from_node <- nodes[[which(sapply(nodes, function(n) {
      n$x == as.numeric(edge$x0) * scale &&
        n$y == as.numeric(edge$y0) * scale
    }))]]$label

    to_node <- nodes[[which(sapply(nodes, function(n) {
      n$x == as.numeric(edge$x1) * scale &&
        n$y == as.numeric(edge$y1) * scale
    }))]]$label

    style <- "link"

    # ---- Color ----
    if (!is.null(edge$gp$col) && length(edge$gp$col) > 0) {
      col_tikz <- rcolor_to_tikz(edge$gp$col)
      if (
        !is.null(col_tikz$tikz) && !identical(col_tikz$tikz, global_edge_color)
      ) {
        style <- c(style, paste0("draw=", col_tikz$tikz))
      }
    }

    # ---- Line width ----
    if (!is.null(edge$gp$lwd) && length(edge$gp$lwd) > 0) {
      style <- c(style, paste0("line width=", edge$gp$lwd))
    }

    # ---- Arrow scale (unit-safe comparison) ----
    if (!is.null(edge$arrow$length) && length(edge$arrow$length) > 0) {
      edge_len_num <- as.numeric(edge$arrow$length)
      if (!is.na(edge_len_num) && edge_len_num != global_arrow_length) {
        style <- c(style, paste0("arrows={[scale=", edge_len_num, "]}"))
      }
    }

    # ---- Bend arrows ----
    if (!is.na(route_option)) {
      style <- c(style, route_option)
    } else if (bend_edges) {
      from_x <- nodes[[which(sapply(nodes, function(n) {
        n$label == from_node
      }))]]$x
      to_x <- nodes[[which(sapply(nodes, function(n) n$label == to_node))]]$x
      bend_dir <- if (to_x >= from_x) "bend left" else "bend right"
      style <- c(style, paste0(bend_dir, "=", bend_angle))
    }

    # ---- Edge type -> TikZ arrow spec ----
    arrow_spec <- tikz_edge_arrow(edge$edge_type, style = "default")

    sprintf(
      "(%s) edge[%s] (%s)",
      from_node,
      paste(c(style, arrow_spec), collapse = ", "),
      to_node
    )
  })

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
