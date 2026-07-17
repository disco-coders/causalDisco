#' Plot a Disco Object
#'
#' Visualize a causal graph stored within a `Disco` object. This function
#' extends [plot.Knowledge()] by combining the causal graph from a `caugi` object with
#' background knowledge.
#'
#' - **Required edges** are drawn in **blue** by default (`required_col`), can be changed.
#' - **Forbidden edges** are not drawn.
#' - If tiered knowledge is provided, nodes are arranged according to their tiers.
#' - Other edge styling (line width, arrow size, etc.) can be supplied via `edge_style`.
#'   To override the color of a specific edge, specify it in
#'   `edge_style$by_edge[[from]][[to]]$col`.
#'
#' @inheritParams plot.Knowledge
#' @param x A `Disco` object containing both the causal graph and the associated knowledge.
#' @param ... Additional arguments passed to [caugi::plot()] and [plot.Knowledge()].
#'
#' @return Invisibly returns the underlying `caugi` object. The main effect is the plot.
#'
#' @details
#' This function combines the causal graph and the `Knowledge` object into a single plotting
#' structure. If the knowledge contains tiers, nodes are laid out accordingly; otherwise,
#' the default caugi layout is used. Edges marked as required are automatically colored
#' (or can be overridden per edge using `edge_style$by_edge`).
#'
#' @examples
#' data(tpc_example)
#'
#' # Define tiered knowledge
#' kn <- knowledge(
#'   tpc_example,
#'   tier(
#'     child ~ starts_with("child"),
#'     youth ~ starts_with("youth"),
#'     old ~ starts_with("old")
#'   )
#' )
#'
#' # Fit a causal discovery model
#' cd_tges <- tges(engine = "causalDisco", score = "tbic")
#' disco_cd_tges <- disco(data = tpc_example, method = cd_tges, knowledge = kn)
#'
#' # Plot with default column orientation
#' plot(disco_cd_tges)
#'
#' # Plot with row orientation
#' plot(disco_cd_tges, orientation = "rows")
#'
#' # Plot with custom node and edge styling
#' plot(
#'   disco_cd_tges,
#'   node_style = list(
#'     fill = "lightblue", # Fill color
#'     col = "darkblue", # Border color
#'     lwd = 2, # Border width
#'     padding = 4, # Text padding (mm)
#'     size = 1.2 # Size multiplier
#'   ),
#'   edge_style = list(
#'     lwd = 1.5, # Edge width
#'     arrow_size = 4, # Arrow size (mm)
#'     col = "darkgreen", # Edge color
#'     fill = "black", # Arrow fill color
#'     lty = "dashed" # Edge line type
#'   )
#' )
#'
#' # To override a specific edge style which is required you need to target that individual node:
#' kn <- knowledge(
#'   tpc_example,
#'   tier(
#'     child ~ starts_with("child"),
#'     youth ~ starts_with("youth"),
#'     old ~ starts_with("old")
#'   ),
#'   child_x1 %-->% child_x2 + youth_x4 # required edges
#' )
#' bnlearn_pc <- pc(engine = "bnlearn", test = "fisher_z")
#' disco_bnlearn_pc <- disco(data = tpc_example, method = bnlearn_pc, knowledge = kn)
#'
#' # Edge from child_x1 to child_x2 will be orange, but edge from child_x1 to youth_x4
#' # will be required_col (blue) since we only override the child_x1 to child_x2 edge.
#' plot(
#'   disco_bnlearn_pc,
#'   edge_style = list(
#'     by_edge = list(
#'       child_x1 = list(
#'         child_x2 = list(col = "orange", fill = "orange")
#'       )
#'     )
#'   ),
#'   required_col = "blue"
#' )
#'
#' # Plot without tiers
#' data(num_data)
#' kn_untiered <- knowledge(
#'   num_data,
#'   X1 %-->% X2 + X3,
#'   Z %!-->% Y
#' )
#'
#' bnlearn_pc <- pc(engine = "bnlearn", test = "fisher_z")
#' res_untiered <- disco(data = num_data, method = bnlearn_pc, knowledge = kn_untiered)
#' plot(res_untiered)
#'
#' # With a custom defined layout
#' custom_layout <- data.frame(
#'  name = c("X1", "X2", "X3", "Z", "Y"),
#'  x = c(0, 1, 2, 2, 3),
#'  y = c(0, 1, 0.25, -1, 0)
#' )
#' plot(res_untiered, layout = custom_layout)
#'
#' @seealso [caugi::plot()]
#' @export
plot.Disco <- function(
  x,
  required_col = "blue",
  ...
) {
  info_object <- combine_knowledge_and_caugi(x$caugi, x$knowledge)
  cg <- info_object$caugi
  tiers <- info_object$tiers

  # Build automatic edge styles for required edges only
  auto_edge_styles <- list(by_edge = list())
  if (!is.null(x$knowledge$edges) && nrow(x$knowledge$edges) > 0) {
    for (i in seq_len(nrow(x$knowledge$edges))) {
      from <- x$knowledge$edges$from[i]
      to <- x$knowledge$edges$to[i]
      status <- x$knowledge$edges$status[i]

      if (
        status == "required" && any(cg@edges$from == from & cg@edges$to == to)
      ) {
        if (is.null(auto_edge_styles$by_edge[[from]])) {
          auto_edge_styles$by_edge[[from]] <- list()
        }
        auto_edge_styles$by_edge[[from]][[to]] <- list(
          col = required_col,
          fill = required_col
        )
      }
    }
  }

  plot_caugi_common(cg, tiers, auto_edge_styles, ...)
}

#' Plot a Knowledge Object
#'
#' Visualize a `Knowledge` object as a directed graph using [caugi::plot()].
#'
#' - **Required edges** are drawn in **blue** by default (can be changed via `required_col`).
#' - **Forbidden edges** are drawn in **red** by default (can be changed via `forbidden_col`). If A to B
#' and B to A is forbidden, an edge `<->` is drawn.
#' - If tiered knowledge is provided, nodes are arranged according to their tiers.
#' - Users can override other edge styling (e.g., line width, arrow size) via the
#'   `edge_style` argument. To override the color of a specific edge, use
#'   `edge_style$by_edge[[from]][[to]]$col`.
#'
#' @param x A `Knowledge` object, created using [knowledge()].
#' @param required_col Character(1). Color for edges marked as "required". Default `"blue"`.
#' @param forbidden_col Character(1). Color for edges marked as "forbidden". Default `"red"`.
#' @param ... Additional arguments passed to [caugi::plot()], e.g., `node_style`, `edge_style`.
#'
#' @return Invisibly returns the [caugi::caugi] object used for plotting. The main effect is the plot.
#'
#' @details
#' - Nodes are arranged by tiers if tier information is provided in the `Knowledge` object.
#' - If some nodes are missing tier assignments, a warning is issued and the plot falls back
#'   to untiered plotting.
#' - The function automatically handles edges marked as "required" or "forbidden" in the `Knowledge` object.
#' - Other edge styling (line width, arrow size, etc.) can be supplied via `edge_style`.
#'   The only way to override edge colors for specific edges is to specify them directly
#'   in `edge_style$by_edge[[from]][[to]]$col`.
#'
#' @examples
#' data(tpc_example)
#'
#' # Define a `Knowledge` object with tiers
#' kn_tiered <- knowledge(
#'   tpc_example,
#'   tier(
#'     child ~ starts_with("child"),
#'     youth ~ starts_with("youth"),
#'     old ~ starts_with("old")
#'   )
#' )
#'
#' # Simple plot (default column orientation)
#' plot(kn_tiered)
#'
#' # Plot with row orientation
#' plot(kn_tiered, orientation = "rows")
#'
#' # Plot with custom node styling, edge width/arrow size and edge colors
#' kn <- knowledge(
#'   tpc_example,
#'   tier(
#'     child ~ starts_with("child"),
#'     youth ~ starts_with("youth"),
#'     old ~ starts_with("old")
#'   ),
#'   child_x1 %-->% child_x2, # required edge
#'   youth_x4 %!-->% youth_x3  # forbidden edge
#' )
#' plot(
#'   kn,
#'   node_style = list(
#'     fill = "lightblue", # Fill color
#'     col = "darkblue", # Border color
#'     lwd = 2, # Border width
#'     padding = 4, # Text padding (mm)
#'     size = 1.2 # Size multiplier
#'   ),
#'   edge_style = list(
#'     lwd = 1.5, # Edge width
#'     arrow_size = 4 # Arrow size (mm)
#'   ),
#'   required_col = "darkgreen",
#'   forbidden_col = "darkorange"
#' )
#'
#' # To override a specific edge style which is required/forbidden
#' # you need to target that individual node:
#' kn <- knowledge(
#'   tpc_example,
#'   tier(
#'     child ~ starts_with("child"),
#'     youth ~ starts_with("youth"),
#'     old ~ starts_with("old")
#'   ),
#'   child_x1 %-->% child_x2 + youth_x4, # required edges
#'   youth_x4 %!-->% youth_x3 + oldage_x5  # forbidden edges
#' )
#'
#' # Edge from child_x1 to child_x2 will be orange, but edge from child_x1 to youth_x4
#' # will be required_col (blue) since we only override the child_x1 to child_x2 edge.
#' # Similarly, edge from youth_x4 to youth_x3 will be yellow, but edge from youth_x4
#' # to oldage_x5 will be forbidden_col (red).
#' plot(
#'   kn,
#'   edge_style = list(
#'     by_edge = list(
#'       child_x1 = list(
#'         child_x2 = list(col = "orange", fill = "orange")
#'       ),
#'       youth_x4 = list(
#'         youth_x3 = list(col = "yellow", fill = "yellow")
#'       )
#'     )
#'   ),
#'   required_col = "blue",
#'   forbidden_col = "red"
#' )
#'
#' # Define a `Knowledge` object without tiers
#' kn_untiered <- knowledge(
#'   tpc_example,
#'   child_x1 %-->% child_x2 + youth_x3,
#'   youth_x4 %!-->% oldage_x5
#' )
#' # Plot with default layout
#' plot(kn_untiered)
#'
#' # With a custom defined layout
#' custom_layout <- data.frame(
#'  name = c("child_x1", "child_x2", "youth_x3", "youth_x4", "oldage_x5", "oldage_x6"),
#'  x = c(0, 1, 2, 2, 3, 4),
#'  y = c(0, 1, 0, -1, 0, 1)
#' )
#' plot(kn_untiered, layout = custom_layout)
#'
#' @export
plot.Knowledge <- function(
  x,
  required_col = "blue",
  forbidden_col = "red",
  ...
) {
  info_object <- knowledge_to_caugi(x)
  cg <- info_object$caugi
  tiers <- info_object$tiers

  # TODO: When caugi supports curved edges, modify this to use curved edges (sometimes)...
  auto_edge_styles <- list(by_edge = list())

  # --- add required edges ---
  if (
    !is.null(info_object$required_edges) && nrow(info_object$required_edges) > 0
  ) {
    for (i in seq_len(nrow(info_object$required_edges))) {
      from <- info_object$required_edges$from[i]
      to <- info_object$required_edges$to[i]

      if (is.null(auto_edge_styles$by_edge[[from]])) {
        auto_edge_styles$by_edge[[from]] <- list()
      }
      auto_edge_styles$by_edge[[from]][[to]] <- list(
        col = required_col,
        fill = required_col
      )
    }
  }

  # --- add forbidden edges ---
  if (
    !is.null(info_object$forbidden_edges) &&
      nrow(info_object$forbidden_edges) > 0
  ) {
    for (i in seq_len(nrow(info_object$forbidden_edges))) {
      from <- info_object$forbidden_edges$from[i]
      to <- info_object$forbidden_edges$to[i]

      if (is.null(auto_edge_styles$by_edge[[from]])) {
        auto_edge_styles$by_edge[[from]] <- list()
      }
      auto_edge_styles$by_edge[[from]][[to]] <- list(
        col = forbidden_col,
        fill = forbidden_col
      )
    }
  }

  plot_caugi_common(cg, tiers, auto_edge_styles, ...)
}


#' Common Plotting Function for Causal Graphs with Tiers and Edge Styles
#' @param cg A [caugi::caugi] object representing the causal graph to be plotted.
#' @param tiers A list of character vectors representing the tiers for tiered plotting.
#' @param auto_edge_styles A list specifying automatic edge styles to be applied.
#' This is typically generated based on required/forbidden edges in knowledge.
#' @param ... Additional arguments passed to [caugi::plot()], such as `node_style` or `edge_style`.
#' @keywords internal
#' @noRd
plot_caugi_common <- function(
  cg,
  tiers,
  auto_edge_styles = list(by_edge = list()),
  ...
) {
  dots <- list(...)

  # Merge user-supplied edge_style
  user_edge_styles <- dots$edge_style
  if (!is.null(user_edge_styles)) {
    merged_edge_styles <- auto_edge_styles

    # Merge by_edge (specific edges)
    if (!is.null(user_edge_styles$by_edge)) {
      for (from in names(user_edge_styles$by_edge)) {
        if (is.null(merged_edge_styles$by_edge[[from]])) {
          merged_edge_styles$by_edge[[from]] <- list()
        }
        for (to in names(user_edge_styles$by_edge[[from]])) {
          merged_edge_styles$by_edge[[from]][[to]] <- user_edge_styles$by_edge[[
            from
          ]][[to]]
        }
      }
    }

    # Merge all other top-level edge_style options (lwd, arrow_size, etc.)
    for (name in setdiff(names(user_edge_styles), "by_edge")) {
      merged_edge_styles[[name]] <- user_edge_styles[[name]]
    }

    dots$edge_style <- NULL
  } else {
    merged_edge_styles <- auto_edge_styles
  }

  # Check tiers
  has_tiers <- length(tiers) > 0 &&
    !all(sapply(tiers, function(x) all(is.na(x))))
  any_na_tiers <- any(sapply(tiers, function(x) anyNA(x)))

  # Prepare plot arguments
  plot_args <- list(cg, edge_style = merged_edge_styles)

  user_supplied_layout <- !is.null(dots$layout)
  if (has_tiers && !any_na_tiers && !user_supplied_layout) {
    plot_args$tiers <- tiers
  } else if (has_tiers && any_na_tiers && !user_supplied_layout) {
    warning(
      "Not all nodes are assigned to tiers. Tiered plotting not implemented for partial tiers. \nDefaulting to untiered plotting.",
      call. = FALSE
    )
  }

  do.call(plot, c(plot_args, dots))
}

#' Plot Method for causalDisco Objects
#'
#' This is the generic `plot()` function for objects of class `Knowledge`
#' or `Disco`. It dispatches to the class-specific plotting methods
#' [plot.Knowledge()] and [plot.Disco()].
#'
#' @param x An object to plot (class `Knowledge` or `Disco`).
#' @param ... Additional arguments passed to class-specific plot methods and to [caugi::plot()].
#'
#' @return Invisibly returns the input object. The primary effect is the generated plot.
#'
#' @seealso [plot.Knowledge()], [plot.Disco()], [caugi::plot()]
#'
#' @examples
#' data(tpc_example)
#' kn <- knowledge(
#'   tpc_example,
#'   tier(
#'     child ~ starts_with("child"),
#'     youth ~ starts_with("youth"),
#'     old ~ starts_with("old")
#'   )
#' )
#' plot(kn)
#'
#' cd_tges <- tges(engine = "causalDisco", score = "tbic")
#' disco_cd_tges <- disco(data = tpc_example, method = cd_tges, knowledge = kn)
#' plot(disco_cd_tges)
#'
#' @name plot
NULL
