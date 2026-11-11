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


#' @title Compute the Obstacle-Avoiding Bend for a Single Edge
#'
#' @description
#' Mirrors the edge routing in `caugi::plot()`: an edge that passes too close
#' to another node is bent away from it. The bend is expressed as a TikZ
#' `bend left`/`bend right` angle, so the output stays readable.
#'
#' TikZ draws `bend left=a` as a cubic curve whose control points lie at
#' `0.3915 * L` from the ends (`L` the edge length), turned `a` degrees to the
#' left of the straight line.
#'
#' If the edge drawn with its default bend stays `clearance` cm away from
#' every obstacle, it is kept. Otherwise the bend whose size is closest to the
#' default's size is used, among those (in whole degrees, up to `max_angle`)
#' that clear all obstacles. The direction does not count, so the first thing
#' tried is the same bend on the other side. Ties go to the smaller bend, then
#' to the side facing away from the worst obstacle. A straight edge is thus
#' bent as little as needed. If no bend clears all obstacles, the one that
#' gets closest is used.
#'
#' @param x0,y0,x1,y1 Edge start and end (cm).
#' @param obstacles Data frame with `x`, `y`, `hw`, `hh` (cm) of the other
#'   nodes (`hw`, `hh`: half-extents, see `tikz_node_extent()`).
#' @param default Signed default bend angle (degrees, positive = left,
#'   0 = straight).
#' @param flip Logical; whether the bend may change direction. With `FALSE`
#'   only the size of a non-zero default bend may change.
#' @param clearance Minimum distance (cm) between the edge and other nodes.
#' @param max_angle Largest bend angle (degrees) to consider.
#' @returns `NULL` (keep the default bend) or a signed bend angle.
#' @keywords internal
#' @noRd
tikz_route_one <- function(
  x0,
  y0,
  x1,
  y1,
  obstacles,
  default = 0,
  flip = TRUE,
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

  start <- min_gap(default)
  if (start$gap >= clearance) {
    return(NULL)
  }

  # Side facing away from the worst obstacle (cross product > 0: on the left).
  k <- start$worst
  cross <- dx * (obstacles$y[k] - y0) - dy * (obstacles$x[k] - x0)
  away <- if (cross > 0) -1 else 1

  target <- abs(default)
  candidates <- unique(c(-target, target, seq(-max_angle, max_angle)))
  if (!flip && default != 0) {
    candidates <- candidates[sign(candidates) == sign(default)]
  }
  candidates <- candidates[candidates != default]
  candidates <- candidates[order(
    abs(abs(candidates) - target),
    abs(candidates),
    sign(candidates) != away
  )]

  best <- list(gap = start$gap, angle = default)
  for (angle in candidates) {
    gap <- min_gap(angle)$gap
    if (gap >= clearance) {
      return(angle)
    }
    if (gap > best$gap) {
      best <- list(gap = gap, angle = angle)
    }
  }
  if (best$angle == default) NULL else best$angle
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
#' bends them up to three times as much (at most `max_angle`), when that
#' spreads the ends towards `min_sep` degrees apart, as long as the edge does
#' not then run (closer) through another node.
#' Straight edges and edges in `fixed` are never changed.
#'
#' @param edges Data frame with `from` and `to`.
#' @param nodes Data frame with `name`, `x`, `y`, `hw`, `hh` (cm).
#' @param options Character vector of bend options (`"bend left=10"`) or `NA`.
#' @param fixed Logical vector; edges whose bend must not be flipped.
#' @param min_sep Minimum angle (degrees) between edge ends at a node.
#' @param clearance Minimum distance (cm) between an edge and other nodes.
#' @param max_angle Largest bend angle (degrees) to use.
#' @returns The adjusted `options`.
#' @keywords internal
#' @noRd
tikz_fan_out <- function(
  edges,
  nodes,
  options,
  fixed,
  min_sep = 30,
  clearance = 0.1,
  max_angle = 60
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
        if (cand == angle[i] || abs(cand) > max_angle) {
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


#' @title Find Edges Drawn in Both Directions
#' @param from,to Character vectors of edge endpoints.
#' @returns Logical vector, `TRUE` where the reverse edge is also present.
#' @keywords internal
#' @noRd
tikz_bidirected <- function(from, to) {
  paste(to, from, sep = "\r") %in% paste(from, to, sep = "\r")
}


#' @title Resolve User-Given Bend Angles per Edge
#'
#' @description
#' Matches the per-edge angles of a `bend` list (as passed to `make_tikz()`)
#' to the edges. An angle
#' given for `A -> B` applies to the edge drawn from `A` to `B`; if there is
#' none but there is an edge drawn from `B` to `A`, it applies to that edge
#' with the sign flipped, so the curve is the same either way.
#'
#' @param bend_by_edge `NULL` or a named list of named lists of single numbers,
#'   `list(A = list(B = 20))`: the signed bend angle in degrees (positive =
#'   `bend left`, negative = `bend right`, 0 = straight) of the edge `A -> B`.
#' @param from,to Character vectors of edge endpoints.
#' @returns Numeric vector, one per edge: the bend angle, or `NA` if not given.
#' @keywords internal
#' @noRd
resolve_tikz_bend_by_edge <- function(bend_by_edge, from, to) {
  out <- rep(NA_real_, length(from))
  if (is.null(bend_by_edge)) {
    return(out)
  }
  named <- function(x) {
    !is.null(names(x)) && !anyNA(names(x)) && all(names(x) != "")
  }
  if (
    !is.list(bend_by_edge) ||
      !named(bend_by_edge) ||
      !all(vapply(
        bend_by_edge,
        function(x) (is.list(x) || is.numeric(x)) && named(x),
        logical(1)
      ))
  ) {
    stop(
      "`bend` must be a single number or a named list of edges, ",
      "e.g. `list(default = 20, A = list(B = 0))`.",
      call. = FALSE
    )
  }

  key <- paste(from, to, sep = "\r")
  reverse <- paste(to, from, sep = "\r")
  unknown <- character(0)
  for (f in names(bend_by_edge)) {
    for (t in names(bend_by_edge[[f]])) {
      angle <- bend_by_edge[[f]][[t]]
      if (!is.numeric(angle) || length(angle) != 1 || !is.finite(angle)) {
        stop(
          sprintf("`bend$%s$%s` must be a single number.", f, t),
          call. = FALSE
        )
      }
      k <- paste(f, t, sep = "\r")
      if (any(key == k)) {
        out[key == k] <- angle
      } else if (any(reverse == k)) {
        out[reverse == k] <- -angle
      } else {
        unknown <- c(unknown, paste(f, "-", t))
      }
    }
  }
  if (length(unknown) > 0) {
    stop(
      sprintf(
        "`bend` contains edges that are not in the graph: %s",
        paste(unknown, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  out
}


#' @title Final Bend Options for a Set of Edges
#'
#' @description
#' Shared by both TikZ styles. Edges with a bend in `bend_by_edge` get exactly
#' that bend, and edges with `route = FALSE` exactly their default bend. All
#' other edges are routed around nodes (`tikz_route_one()`) and then spread
#' out where they leave a node in nearly the same direction
#' (`tikz_fan_out()`). Edges in both directions keep their bend direction,
#' which keeps the pair apart; only the size of their bend may change.
#'
#' @param edges Data frame from `tikz_edge_records()`.
#' @param nodes Data frame with `name`, `x`, `y`, `hw`, `hh` (cm).
#' @param default Signed default bend angle (degrees, positive = left),
#'   recycled to one per edge.
#' @inheritParams resolve_tikz_bend_by_edge
#' @returns Character vector, one per edge: a bend option or `NA` (straight).
#' @keywords internal
#' @noRd
tikz_bend_options <- function(edges, nodes, default, bend_by_edge = NULL) {
  if (nrow(edges) == 0) {
    return(character(0))
  }
  angle <- rep_len(default, nrow(edges))
  custom <- resolve_tikz_bend_by_edge(bend_by_edge, edges$from, edges$to)
  given <- !is.na(custom)
  angle[given] <- custom[given]
  route <- edges$route & !given
  bidir <- tikz_bidirected(edges$from, edges$to)

  from <- match(edges$from, nodes$name)
  to <- match(edges$to, nodes$name)
  for (i in which(route)) {
    routed <- tikz_route_one(
      nodes$x[from[i]],
      nodes$y[from[i]],
      nodes$x[to[i]],
      nodes$y[to[i]],
      nodes[-c(from[i], to[i]), , drop = FALSE],
      default = angle[i],
      flip = !bidir[i]
    )
    if (!is.null(routed)) {
      angle[i] <- routed
    }
  }

  tikz_fan_out(edges, nodes, tikz_angle_option(angle), fixed = bidir | !route)
}
