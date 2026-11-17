# Generate TikZ Code from a Causal Graph

Generates LaTeX TikZ code from a `Disco`, `Knowledge`, or
[`caugi::caugi`](https://caugi.org/reference/caugi.html) object,
preserving node positions, labels, and visual styles. Edges are rendered
with arrows, line widths, and colors. The output is readable LaTeX code
that can be directly compiled or modified.

## Usage

``` r
make_tikz(
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
)
```

## Arguments

- x:

  A `Disco`, `Knowledge`, or
  [`caugi::caugi`](https://caugi.org/reference/caugi.html) object.

- ...:

  Additional arguments passed to
  [`plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md)
  and [`caugi::plot()`](https://caugi.org/reference/plot.caugi.html).

- style:

  `"default"` mirrors
  [`plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md).
  `"classic"` is a minimal look with plain-text nodes, gray tier bands,
  and a time axis. See Details.

- scale:

  Numeric scalar. Scaling factor for node coordinates. Default is `10`.

- full_doc:

  Logical. If `TRUE` (default), generates a full standalone LaTeX
  document. If `FALSE`, returns only the `tikzpicture` environment; load
  `\usetikzlibrary{arrows.meta, bending, backgrounds, fit, calc}` in
  your preamble.

- bend:

  How much edges are bent, in degrees:

  - A number bends every edge by that angle; `0` draws edges straight,
    and a negative number bends them the other way (see Details). Edges
    may still be bent differently to avoid nodes.

  - A named list sets the bend of individual edges, in the same nested
    form as `edge_style$by_edge`: `list(A = list(B = 20, C = -10))`
    bends the edge from `A` to `B` 20 degrees to the left
    (`bend left=20`) and the edge from `A` to `C` 10 degrees to the
    right; `0` draws an edge straight. Left and right are as seen going
    from the first to the second node, whichever way the edge points.
    These edges are drawn exactly as given. Add `default = <number>` to
    set the bend of all other edges, e.g.
    `list(default = 20, A = list(B = 0))`.

  Default is `0` (`10` for `style = "classic"`).

- tier_label_pos:

  Character string specifying the position of tier labels relative to
  the tier rectangles. Must be one of `"above"`, `"below"`, `"left"`, or
  `"right"`. Default is `"above"`. For `style = "classic"`, see Details.

- node_labels, tier_labels:

  Optional named character vectors of LaTeX labels for nodes or tiers,
  e.g. `c(child_x1 = "$X_1$")`. Unlabelled nodes and tiers use their
  name.

- bend_edges:

  **\[deprecated\]** Use `bend` instead: `bend_edges = FALSE` is
  `bend = 0`, and `bend_edges = TRUE` is `bend = bend_angle`.

- bend_angle:

  **\[deprecated\]** Use `bend` instead.

## Value

A character string containing LaTeX TikZ code. Depending on `full_doc`,
this is either:

- a complete LaTeX document (`full_doc = TRUE`), or

- only the `tikzpicture` environment (`full_doc = FALSE`).

## Details

The function calls
[`plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md)
to generate a
[`caugi::caugi_plot`](https://caugi.org/reference/caugi_plot.html)
object, then traverses the plot object's grob structure to extract nodes
and edges. Supported features include:

- **Nodes**

  - Fill color and draw color (supports both named colors and custom RGB
    values)

  - Font size

  - Coordinates are scaled by the `scale` parameter

- **Edges**

  - Line color and width

  - Arrow scale

  - Optional bending to reduce overlapping arrows

The output starts with named styles (`var` for nodes, `link` for edges,
`tier` and `tier label` for tiers) for easy restyling, and edges are
connected to nodes by name rather than coordinates.

### Bent edges

With a positive `bend` (or `default`), edges bend to the left when they
point to the right and vice versa, so they bulge upwards; with
`style = "classic"` they always bend to the right. A negative angle
bends them the other way. Edges in both directions (`A --> B` and
`B --> A`) are bent to opposite sides, by that angle, or if it is `0`,
by `25` degrees (`10` for `style = "classic"`).

Like
[`plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md),
edges that would pass through another node are bent around it. A bent
edge that would pass through a node is bent the other way instead, or,
if that also hits a node, by the angle closest to its bend that clears
all nodes. Bent edges that leave a node in nearly the same direction are
spread apart, by bending them the other way or more. Node sizes are
estimated from the labels, so a bend may need a manual tweak.

To draw edges exactly as requested, turn both adjustments off with
`edge_style = list(route = FALSE)`, or for single edges with
`edge_style$by_edge`. Edges given in a `bend` list are always drawn
exactly as given.

### Classic style

Adds a `time axis` style, and the spacing is set by the `x` and `y`
options of the `tikzpicture`. Tier labels go on the time axis: `"below"`
(default) or `"above"` for column tiers, `"left"` (default) or `"right"`
for row tiers.

## Examples

``` r
################# Convert Knowledge to Tikz ################

data(num_data)
kn <- knowledge(
  num_data,
  X1 %-->% X2,
  X2 %!-->% X3 + Y,
  Y %!-->% Z
)

# Full standalone document
tikz_kn <- make_tikz(kn, scale = 10, full_doc = TRUE)
cat(tikz_kn)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \documentclass[tikz,border=2mm]{standalone}
#> \usetikzlibrary{arrows.meta, bending, backgrounds, fit, calc}
#> 
#> \begin{document}
#> \tikzset{
#>   var/.style={draw, circle, fill=lightgray},
#>   link/.style={draw=red, arrows={[scale=3]}}
#> }
#> \begin{tikzpicture}
#> \node[var] (X1) at (1.667,0) {X1};
#> \node[var] (X2) at (1.667,3.333) {X2};
#> \node[var] (X3) at (3.333,6.667) {X3};
#> \node[var] (Y) at (0,6.667) {Y};
#> \node[var] (Z) at (0,10) {Z};
#> \path (X1) edge[link, draw=blue, -Latex] (X2)
#>       (X2) edge[link, -Latex] (X3)
#>       (X2) edge[link, -Latex] (Y)
#>       (Y) edge[link, -Latex] (Z);
#> \end{tikzpicture}
#> \end{document}

# Only the tikzpicture environment
tikz_kn_snippet <- make_tikz(kn, full_doc = FALSE)
cat(tikz_kn_snippet)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   var/.style={draw, circle, fill=lightgray},
#>   link/.style={draw=red, arrows={[scale=3]}}
#> }
#> \begin{tikzpicture}
#> \node[var] (X1) at (1.667,0) {X1};
#> \node[var] (X2) at (1.667,3.333) {X2};
#> \node[var] (X3) at (3.333,6.667) {X3};
#> \node[var] (Y) at (0,6.667) {Y};
#> \node[var] (Z) at (0,10) {Z};
#> \path (X1) edge[link, draw=blue, -Latex] (X2)
#>       (X2) edge[link, -Latex] (X3)
#>       (X2) edge[link, -Latex] (Y)
#>       (Y) edge[link, -Latex] (Z);
#> \end{tikzpicture}

# With bent edges
tikz_bent <- make_tikz(
  kn,
  full_doc = FALSE,
  bend = 25
)
cat(tikz_bent)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   var/.style={draw, circle, fill=lightgray},
#>   link/.style={draw=red, arrows={[scale=3]}}
#> }
#> \begin{tikzpicture}
#> \node[var] (X1) at (1.667,0) {X1};
#> \node[var] (X2) at (1.667,3.333) {X2};
#> \node[var] (X3) at (3.333,6.667) {X3};
#> \node[var] (Y) at (0,6.667) {Y};
#> \node[var] (Z) at (0,10) {Z};
#> \path (X1) edge[link, draw=blue, bend left=25, -Latex] (X2)
#>       (X2) edge[link, bend right=25, -Latex] (X3)
#>       (X2) edge[link, bend right=25, -Latex] (Y)
#>       (Y) edge[link, bend left=25, -Latex] (Z);
#> \end{tikzpicture}

# With a color not supported by default TikZ colors; will fall back to RGB
tikz_darkblue <- make_tikz(
  kn,
  node_style = list(fill = "darkblue"),
  full_doc = FALSE
)
cat(tikz_darkblue)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   var/.style={draw, circle, fill={rgb:red,0.000;green,0.000;blue,0.545}},
#>   link/.style={draw=red, arrows={[scale=3]}}
#> }
#> \begin{tikzpicture}
#> \node[var] (X1) at (1.667,0) {X1};
#> \node[var] (X2) at (1.667,3.333) {X2};
#> \node[var] (X3) at (3.333,6.667) {X3};
#> \node[var] (Y) at (0,6.667) {Y};
#> \node[var] (Z) at (0,10) {Z};
#> \path (X1) edge[link, draw=blue, -Latex] (X2)
#>       (X2) edge[link, -Latex] (X3)
#>       (X2) edge[link, -Latex] (Y)
#>       (Y) edge[link, -Latex] (Z);
#> \end{tikzpicture}

# With tiered knowledge
data(tpc_example)
kn_tiered <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  )
)
tikz_tiered_kn <- make_tikz(
  kn_tiered,
  full_doc = FALSE
)
cat(tikz_tiered_kn)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   var/.style={draw, circle, fill=lightgray},
#>   link/.style={},
#>   tier/.style={draw, rectangle, fill=blue!20, rounded corners, inner sep=0.5cm},
#>   tier label/.style={}
#> }
#> \begin{tikzpicture}
#> \node[var] (child_x1) at (0,0) {child\_x1};
#> \node[var] (child_x2) at (0,10) {child\_x2};
#> \node[var] (youth_x3) at (5,0) {youth\_x3};
#> \node[var] (youth_x4) at (5,10) {youth\_x4};
#> \node[var] (oldage_x5) at (10,0) {oldage\_x5};
#> \node[var] (oldage_x6) at (10,10) {oldage\_x6};
#> \begin{scope}[on background layer]
#> \node[tier, fit=(child_x1)(child_x2)] (child) {};
#> \node[tier, fit=(oldage_x5)(oldage_x6)] (old) {};
#> \node[tier, fit=(youth_x3)(youth_x4)] (youth) {};
#> \end{scope}
#> \node[tier label, anchor=south] at ($(child.north)+(0cm,0.2cm)$) {child};
#> \node[tier label, anchor=south] at ($(old.north)+(0cm,0.2cm)$) {old};
#> \node[tier label, anchor=south] at ($(youth.north)+(0cm,0.2cm)$) {youth};
#> \path ;
#> \end{tikzpicture}

# Classic style with LaTeX labels
tikz_classic <- make_tikz(
  kn_tiered,
  style = "classic",
  node_labels = c(child_x1 = "$X_1$", child_x2 = "$X_2$"),
  tier_labels = c(child = "Childhood", old = "Old age"),
  full_doc = FALSE
)
cat(tikz_classic)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   >={Stealth[length=2.2mm, width=1.7mm]},
#>   o/.tip={Circle[open, length=1.6mm]},
#>   var/.style={inner sep=2pt},
#>   link/.style={semithick},
#>   tier/.style={fill=black!8, inner sep=4pt},
#>   tier label/.style={font=\small},
#>   time axis/.style={semithick, -{Stealth[length=2mm]}}
#> }
#> \begin{tikzpicture}[x=3.5cm, y=1.5cm]
#> \node[var] (child_x1) at (-0.15,0) {$X_1$};
#> \node[var] (child_x2) at (0.15,1) {$X_2$};
#> \node[var] (youth_x3) at (0.85,0) {youth\_x3};
#> \node[var] (youth_x4) at (1.15,1) {youth\_x4};
#> \node[var] (oldage_x5) at (1.85,0) {oldage\_x5};
#> \node[var] (oldage_x6) at (2.15,1) {oldage\_x6};
#> \begin{scope}[on background layer]
#> \node[tier, fit={(child_x1)(child_x2)(0,-0.5)(0,1.5)}] (tier-1) {};
#> \node[tier, fit={(youth_x3)(youth_x4)(1,-0.5)(1,1.5)}] (tier-2) {};
#> \node[tier, fit={(oldage_x5)(oldage_x6)(2,-0.5)(2,1.5)}] (tier-3) {};
#> \end{scope}
#> \draw[time axis] ([xshift=-3mm]tier-1.south west) -- ([xshift=5mm]tier-3.south east);
#> \node[tier label, below=3pt] at (tier-1.south) {Childhood};
#> \node[tier label, below=3pt] at (tier-2.south) {youth};
#> \node[tier label, below=3pt] at (tier-3.south) {Old age};
#> \end{tikzpicture}

# Edges are bent around nodes in the way: here A --> C bends around B
cg_line <- caugi::caugi(A %-->% B + C, B %-->% C)
layout_line <- data.frame(name = c("A", "B", "C"), x = c(0, 1, 2), y = 0)
tikz_routed <- make_tikz(
  cg_line,
  layout = layout_line,
  style = "classic",
  full_doc = FALSE
)
cat(tikz_routed)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   >={Stealth[length=2.2mm, width=1.7mm]},
#>   o/.tip={Circle[open, length=1.6mm]},
#>   var/.style={inner sep=2pt},
#>   link/.style={semithick},
#>   tier/.style={fill=black!8, inner sep=4pt},
#>   tier label/.style={font=\small},
#>   time axis/.style={semithick, -{Stealth[length=2mm]}}
#> }
#> \begin{tikzpicture}
#> \node[var] (A) at (0,0) {A};
#> \node[var] (B) at (10,0) {B};
#> \node[var] (C) at (20,0) {C};
#> \path[link] (A) edge[->, bend right=10] (B)
#>       (A) edge[->, bend left=20] (C)
#>       (B) edge[->, bend right=10] (C);
#> \end{tikzpicture}

# Draw every edge exactly with the requested bend instead
tikz_exact <- make_tikz(
  cg_line,
  layout = layout_line,
  style = "classic",
  edge_style = list(route = FALSE),
  full_doc = FALSE
)
cat(tikz_exact)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   >={Stealth[length=2.2mm, width=1.7mm]},
#>   o/.tip={Circle[open, length=1.6mm]},
#>   var/.style={inner sep=2pt},
#>   link/.style={semithick},
#>   tier/.style={fill=black!8, inner sep=4pt},
#>   tier label/.style={font=\small},
#>   time axis/.style={semithick, -{Stealth[length=2mm]}}
#> }
#> \begin{tikzpicture}
#> \node[var] (A) at (0,0) {A};
#> \node[var] (B) at (10,0) {B};
#> \node[var] (C) at (20,0) {C};
#> \path[link] (A) edge[->, bend right=10] (B)
#>       (A) edge[->, bend right=10] (C)
#>       (B) edge[->, bend right=10] (C);
#> \end{tikzpicture}

# Set the bend of single edges (positive = bend left, negative = bend right);
# these are always drawn exactly as given
tikz_bends <- make_tikz(
  cg_line,
  layout = layout_line,
  style = "classic",
  bend = list(A = list(B = 30, C = 0)),
  full_doc = FALSE
)
cat(tikz_bends)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   >={Stealth[length=2.2mm, width=1.7mm]},
#>   o/.tip={Circle[open, length=1.6mm]},
#>   var/.style={inner sep=2pt},
#>   link/.style={semithick},
#>   tier/.style={fill=black!8, inner sep=4pt},
#>   tier label/.style={font=\small},
#>   time axis/.style={semithick, -{Stealth[length=2mm]}}
#> }
#> \begin{tikzpicture}
#> \node[var] (A) at (0,0) {A};
#> \node[var] (B) at (10,0) {B};
#> \node[var] (C) at (20,0) {C};
#> \path[link] (A) edge[->, bend left=30] (B)
#>       (A) edge[->] (C)
#>       (B) edge[->, bend right=30] (C);
#> \end{tikzpicture}


################# Convert Disco to Tikz ################

data(num_data)
kn <- knowledge(
  num_data,
  X1 %-->% X2,
  X2 %!-->% X3 + Y,
  Y %!-->% Z
)

pc_bnlearn <- pc(engine = "bnlearn", test = "fisher_z", alpha = 0.05)
disco_kn <- disco(data = num_data, method = pc_bnlearn, knowledge = kn)

tikz_snippet <- make_tikz(disco_kn, scale = 10, full_doc = FALSE)
cat(tikz_snippet)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   var/.style={draw, circle, fill=lightgray},
#>   link/.style={draw=blue, arrows={[scale=3]}}
#> }
#> \begin{tikzpicture}
#> \node[var] (X1) at (7.401,3.504) {X1};
#> \node[var] (X2) at (2.595,3.504) {X2};
#> \node[var] (X3) at (0,0) {X3};
#> \node[var] (Z) at (10,0.001) {Z};
#> \node[var] (Y) at (4.999,0.188) {Y};
#> \path (X1) edge[link, -Latex] (X2)
#>       (X1) edge[link, -Latex] (Y)
#>       (X1) edge[link, -] (Z)
#>       (X3) edge[link, -Latex] (X2)
#>       (X3) edge[link, -Latex] (Y)
#>       (Y) edge[link, -Latex] (X2)
#>       (Z) edge[link, -Latex] (Y);
#> \end{tikzpicture}

################# Convert caugi objects to Tikz ################

cg <- caugi::caugi(A %-->% B + C)

tikz_snippet <- make_tikz(
  cg,
  node_style = list(fill = "red"),
  scale = 10,
  full_doc = FALSE
)
cat(tikz_snippet)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   var/.style={draw, circle, fill=red},
#>   link/.style={arrows={[scale=3]}}
#> }
#> \begin{tikzpicture}
#> \node[var] (A) at (5,0) {A};
#> \node[var] (B) at (10,10) {B};
#> \node[var] (C) at (0,10) {C};
#> \path (A) edge[link, -Latex] (B)
#>       (A) edge[link, -Latex] (C);
#> \end{tikzpicture}
```
