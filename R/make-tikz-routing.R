#' @title Estimate the Half-Extents of a TikZ Node
#'
#' @description
#' TikZ sizes nodes from their text, which is only known once LaTeX runs. This
#' gives a rough estimate (in cm, for a 10pt font) that is good enough to decide
#' whether an edge passes through a node.
#'
#' @param label Character vector of LaTeX node labels.
#' @param shape `"text"` for plain-text nodes (classic style) or `"circle"` for
#'   circled nodes (default style).
#' @returns A data frame with columns `hw` and `hh` (half-width, half-height).
#' @keywords internal
#' @noRd
tikz_node_extent <- function(label, shape = c("text", "circle")) {
  shape <- match.arg(shape)
  # Drop LaTeX commands and markup characters that take no horizontal space.
  visible <- gsub("\\\\[A-Za-z]+|[{}$^\\\\]", "", label)
  visible <- gsub("_", "", visible, fixed = TRUE)
  half_text_w <- 0.09 * pmax(nchar(visible), 1)
  half_text_h <- 0.15
  inner_sep <- if (shape == "text") 0.07 else 0.12
  if (shape == "circle") {
    r <- sqrt(half_text_w^2 + half_text_h^2) + inner_sep
    data.frame(hw = r, hh = r)
  } else {
    data.frame(hw = half_text_w + inner_sep, hh = half_text_h + inner_sep)
  }
}


#' @title Compute Obstacle-Avoiding Bends for TikZ Edges
#'
#' @description
#' Mirrors the edge routing in `caugi::plot()`: an edge whose straight line
#' passes too close to another node is bent away from it. The bend is expressed
#' as a TikZ `bend left`/`bend right` angle, so the output stays readable.
#'
#' TikZ draws `bend left=a` as a cubic curve whose control points lie at
#' `0.3915 * L` from the ends (`L` the edge length), turned `a` degrees to the
#' left of the straight line. For each edge, the smallest angle (in whole
#' degrees, up to `max_angle`) that keeps the curve `clearance` cm away from
#' every other node is chosen, preferring the side facing away from the worst
#' obstacle. If no angle clears all nodes, the side and angle that get closest
#' are used.
#'
#' @param edges Data frame with columns `from` and `to` (node names).
#' @param nodes Data frame with columns `name`, `x`, `y` (cm) and `hw`, `hh`
#'   (half-extents in cm, see `tikz_node_extent()`).
#' @param route Logical vector, one per edge; edges with `FALSE` are skipped.
#' @param clearance Minimum distance (cm) between an edge and other nodes.
#' @param max_angle Largest bend angle (degrees) to consider.
#' @returns A list with one entry per edge: `NULL` (no bend needed) or a list
#'   with `dir` (`"bend left"` or `"bend right"`) and `angle` (degrees).
#' @keywords internal
#' @noRd
tikz_route_edges <- function(
  edges,
  nodes,
  route = rep(TRUE, nrow(edges)),
  clearance = 0.1,
  max_angle = 60
) {
  lapply(seq_len(nrow(edges)), function(i) {
    if (!isTRUE(route[i])) {
      return(NULL)
    }
    from <- match(edges$from[i], nodes$name)
    to <- match(edges$to[i], nodes$name)
    obstacles <- nodes[-c(from, to), , drop = FALSE]
    tikz_route_one(
      nodes$x[from],
      nodes$y[from],
      nodes$x[to],
      nodes$y[to],
      obstacles,
      clearance = clearance,
      max_angle = max_angle
    )
  })
}


#' @title Compute the Bend for a Single Edge
#' @inheritParams tikz_route_edges
#' @param x0,y0,x1,y1 Edge start and end (cm).
#' @param obstacles Data frame with `x`, `y`, `hw`, `hh` of the other nodes.
#' @returns `NULL` or a list with `dir` and `angle`.
#' @keywords internal
#' @noRd
tikz_route_one <- function(
  x0,
  y0,
  x1,
  y1,
  obstacles,
  clearance = 0.1,
  max_angle = 60
) {
  dx <- x1 - x0
  dy <- y1 - y0
  len <- sqrt(dx^2 + dy^2)
  if (len <= 0 || nrow(obstacles) == 0) {
    return(NULL)
  }

  min_gap <- function(angle) {
    tikz_curve_gap(x0, y0, x1, y1, angle, obstacles)
  }

  straight <- min_gap(0)
  if (straight$gap >= clearance) {
    return(NULL)
  }

  # Prefer bending away from the worst obstacle (cross product > 0: on the left).
  k <- straight$worst
  cross <- dx * (obstacles$y[k] - y0) - dy * (obstacles$x[k] - x0)
  sides <- if (cross > 0) c(-1, 1) else c(1, -1)

  best <- list(gap = -Inf)
  for (side in sides) {
    for (angle in seq_len(max_angle)) {
      gap <- min_gap(side * angle)$gap
      if (gap >= clearance) {
        return(list(
          dir = if (side > 0) "bend left" else "bend right",
          angle = angle
        ))
      }
      if (gap > best$gap) {
        best <- list(gap = gap, side = side, angle = angle)
      }
    }
  }
  list(
    dir = if (best$side > 0) "bend left" else "bend right",
    angle = best$angle
  )
}


#' @title Gap Between a Bent Edge and Obstacle Nodes
#'
#' @description
#' Samples the cubic curve TikZ draws for `bend left=angle` (control points at
#' `0.3915 * L` from the ends, turned `angle` degrees; negative = right) and
#' returns its smallest distance to any obstacle box. Only the middle of the
#' curve is checked; its ends are inside the end nodes.
#'
#' @param x0,y0,x1,y1 Edge start and end (cm).
#' @param angle Signed bend angle in degrees (positive = left).
#' @param obstacles Data frame with `x`, `y`, `hw`, `hh` (at least one row).
#' @returns A list with `gap` (cm, negative = overlap) and `worst` (row index
#'   of the closest obstacle).
#' @keywords internal
#' @noRd
tikz_curve_gap <- function(x0, y0, x1, y1, angle, obstacles) {
  dx <- x1 - x0
  dy <- y1 - y0
  len <- sqrt(dx^2 + dy^2)
  t <- seq(0.05, 0.95, length.out = 91)
  rad <- angle * pi / 180
  ux <- dx / len
  uy <- dy / len
  d <- 0.3915 * len
  c1x <- x0 + d * (cos(rad) * ux - sin(rad) * uy)
  c1y <- y0 + d * (cos(rad) * uy + sin(rad) * ux)
  c2x <- x1 + d * (-cos(rad) * ux - sin(rad) * uy)
  c2y <- y1 + d * (-cos(rad) * uy + sin(rad) * ux)
  b0 <- (1 - t)^3
  b1 <- 3 * (1 - t)^2 * t
  b2 <- 3 * (1 - t) * t^2
  b3 <- t^3
  px <- b0 * x0 + b1 * c1x + b2 * c2x + b3 * x1
  py <- b0 * y0 + b1 * c1y + b2 * c2y + b3 * y1
  gaps <- vapply(
    seq_len(nrow(obstacles)),
    function(k) {
      min(pmax(
        abs(px - obstacles$x[k]) - obstacles$hw[k],
        abs(py - obstacles$y[k]) - obstacles$hh[k]
      ))
    },
    numeric(1)
  )
  list(gap = min(gaps), worst = which.min(gaps))
}


#' @title Spread Out Edge Ends That Leave a Node in Nearly the Same Direction
#'
#' @description
#' Two bent edges can leave (or enter) a node almost parallel, so their arrow
#' tips or circles overlap. This flips the bend direction of such edges, or
#' bends them up to three times as much, when that spreads the ends towards
#' `min_sep` degrees apart, as long as the edge does not then run (closer)
#' through another node.
#' Straight edges and edges in `fixed` are never changed.
#'
#' @param edges Data frame with `from` and `to`.
#' @param nodes Data frame with `name`, `x`, `y`, `hw`, `hh` (cm).
#' @param options Character vector of bend options (`"bend left=10"`) or `NA`.
#' @param fixed Logical vector; edges whose bend must not be flipped.
#' @param min_sep Minimum angle (degrees) between edge ends at a node.
#' @param clearance Minimum distance (cm) between an edge and other nodes.
#' @returns The adjusted `options`.
#' @keywords internal
#' @noRd
tikz_fan_out <- function(
  edges,
  nodes,
  options,
  fixed,
  min_sep = 30,
  clearance = 0.1
) {
  n <- nrow(edges)
  if (n < 2) {
    return(options)
  }
  from <- match(edges$from, nodes$name)
  to <- match(edges$to, nodes$name)
  base <- atan2(nodes$y[to] - nodes$y[from], nodes$x[to] - nodes$x[from]) *
    180 /
    pi
  angle <- tikz_option_angle(options)

  # Direction in which each edge end leaves its node: at the start the curve is
  # turned `angle` to the left, at the end it arrives from the same side.
  end_node <- c(from, to)
  pairs <- do.call(
    cbind,
    lapply(unique(end_node), function(v) {
      idx <- which(end_node == v)
      if (length(idx) < 2) NULL else utils::combn(idx, 2)
    })
  )
  if (is.null(pairs)) {
    return(options)
  }
  penalty <- function(a) {
    ends <- c(base + a, base + 180 - a)
    diff <- abs((ends[pairs[1, ]] - ends[pairs[2, ]] + 180) %% 360 - 180)
    sum(pmax(min_sep - diff, 0))
  }
  gap <- function(i, a) {
    obstacles <- nodes[-c(from[i], to[i]), , drop = FALSE]
    if (nrow(obstacles) == 0) {
      return(Inf)
    }
    n0 <- c(nodes$x[from[i]], nodes$y[from[i]])
    n1 <- c(nodes$x[to[i]], nodes$y[to[i]])
    tikz_curve_gap(n0[1], n0[2], n1[1], n1[2], a, obstacles)$gap
  }

  # Each adjustable edge may bend either way, by up to three times its original
  # angle. A small cost per degree prefers flipping over bending more.
  original <- abs(angle)
  objective <- function(a) penalty(a) + 0.01 * sum(abs(a))

  # Greedily apply the change that lowers the objective most; this stops
  # because each step strictly lowers it and there are finitely many states.
  repeat {
    current <- objective(angle)
    if (penalty(angle) == 0) {
      break
    }
    best <- NULL
    for (i in which(!fixed & angle != 0)) {
      for (cand in c(-1, 1, -2, 2, -3, 3) * original[i]) {
        if (cand == angle[i]) {
          next
        }
        candidate <- angle
        candidate[i] <- cand
        obj <- objective(candidate)
        if (obj < current) {
          new_gap <- gap(i, cand)
          if (new_gap >= clearance || new_gap >= gap(i, angle[i])) {
            current <- obj
            best <- c(i, cand)
          }
        }
      }
    }
    if (is.null(best)) {
      break
    }
    angle[best[1]] <- best[2]
  }
  tikz_angle_option(angle)
}


#' @title Convert Between Bend Options and Signed Angles
#' @param options Character vector of `"bend left=<a>"`/`"bend right=<a>"` or
#'   `NA`.
#' @param angle Numeric vector of signed angles (positive = left, 0 = none).
#' @returns Signed angles, or bend options (`NA` for 0).
#' @keywords internal
#' @noRd
tikz_option_angle <- function(options) {
  a <- suppressWarnings(as.numeric(sub("^bend (left|right)=", "", options)))
  a[is.na(a)] <- 0
  ifelse(grepl("^bend right", options), -a, a)
}

#' @rdname tikz_option_angle
#' @noRd
tikz_angle_option <- function(angle) {
  ifelse(
    angle == 0,
    NA_character_,
    paste0(
      ifelse(angle > 0, "bend left=", "bend right="),
      format_coord(abs(angle))
    )
  )
}


#' @title Combine a Routed Bend with the Requested Bend Settings
#'
#' @param route `NULL` or a list with `dir` and `angle` from
#'   `tikz_route_edges()`.
#' @param bend_edges Logical; whether all edges are bent.
#' @param bend_angle Bend angle used when `bend_edges = TRUE`.
#' @returns `NULL` (no routed bend) or a TikZ option such as `"bend left=23"`.
#'   With `bend_edges = TRUE` the angle is at least `bend_angle`.
#' @keywords internal
#' @noRd
tikz_route_option <- function(route, bend_edges, bend_angle) {
  if (is.null(route)) {
    return(NULL)
  }
  angle <- if (bend_edges) max(route$angle, bend_angle) else route$angle
  paste0(route$dir, "=", format_coord(angle))
}


#' @title Find Edges Drawn in Both Directions
#' @param from,to Character vectors of edge endpoints.
#' @returns Logical vector, `TRUE` where the reverse edge is also present.
#' @keywords internal
#' @noRd
tikz_bidirected <- function(from, to) {
  paste(to, from, sep = "\r") %in% paste(from, to, sep = "\r")
}


#' @title Routed Bend Options for a Set of Edges
#'
#' @description
#' Runs `tikz_route_edges()` for every edge that caugi routes, except edges
#' drawn in both directions (those are bent apart instead), and formats the
#' result with `tikz_route_option()`.
#'
#' @param edges Data frame from `tikz_edge_records()`.
#' @param nodes Data frame with `name`, `x`, `y`, `hw`, `hh` (cm).
#' @inheritParams tikz_route_option
#' @returns Character vector, one per edge: a bend option or `NA`.
#' @keywords internal
#' @noRd
tikz_route_options <- function(edges, nodes, bend_edges, bend_angle) {
  if (nrow(edges) == 0) {
    return(character(0))
  }
  route <- edges$route & !tikz_bidirected(edges$from, edges$to)
  routes <- tikz_route_edges(edges, nodes, route = route)
  vapply(
    routes,
    function(r) tikz_route_option(r, bend_edges, bend_angle) %||% NA_character_,
    character(1)
  )
}
