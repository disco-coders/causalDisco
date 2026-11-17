# Visualization

``` r

library(causalDisco)
#> causalDisco startup:
#>   Java heap size requested: 2 GB
#>   Tetrad version: 7.6.10
#>   Java successfully initialized with 2 GB.
#>   To change heap size, set options(java.heap.size = 'Ng') or Sys.setenv(JAVA_HEAP_SIZE = 'Ng') *before* loading.
#>   Restart R to apply changes.
```

This article demonstrates how to visualize causal graphs. We cover
plotting `Knowledge` objects and `Disco` objects, customizing layouts
and styles, and exporting graphs to readable TikZ for inclusion and
further customization in LaTeX documents.

## Plotting

You can visualize causal graphs using the
[`plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md)
function, which works for both `Knowledge` and `Disco` objects. The
function leverages the underlying
[`caugi::plot()`](https://caugi.org/reference/plot.caugi.html) method,
providing flexible options for customizing the appearance of nodes and
edges.

### Plotting Knowledge Objects

We will use the dataset `num_data` for the following examples, which
contains 5 numeric variables (`X1`, `X2`, `X3`, `Y`, and `Z`). We start
by creating a simple `Knowledge` object and visualizing it with
[`plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md).

``` r

data(num_data)
kn <- knowledge(
  num_data,
  X1 %-->% X2 + X3, # Require edge from X1 to X2, and X1 to X3
  X2 %!-->% X3 + Y, # Forbid edge from X2 to X3, and X2 to Y
  Y %!-->% Z # Forbid edge from Y to Z
)

plot(kn)
```

![](visualization_files/figure-html/knowledge-plot-1.png)

By default, required edges are shown in blue and forbidden edges in red.
You can customize these colors using the `required_col` and
`forbidden_col` arguments:

``` r

plot(kn, required_col = "skyblue", forbidden_col = "orange")
```

![](visualization_files/figure-html/knowledge-plot-different-colors-1.png)

Different node layouts, node styles, and edge styles can be controlled
via the `layout`, `node_style`, and `edge_style` parameters. We
illustrate this with a simple example below. For a full description of
available options, see the documentation for
[`causalDisco::plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md),
as well as the underlying
[`caugi::plot()`](https://caugi.org/reference/plot.caugi.html) function
and its visualization vignette
([`vignette("visualization", "caugi")`](https://caugi.org/articles/visualization.html)).

Here we use the `"fruchterman-reingold"` layout and customize node and
edge styles:

``` r

plot(
  kn,
  layout = "fruchterman-reingold",
  node_style = list(
    fill = "lightblue", # Fill color
    col = "darkblue", # Border color
    lwd = 2, # Border width
    padding = 4, # Text padding (mm)
    size = 1.2 # Size multiplier
  ),
  edge_style = list(
    lwd = 1.5, # Edge width
    arrow_size = 4 # Arrow size (mm)
  ),
  required_col = "blue", # Color for required edges
  forbidden_col = "red" # Color for forbidden edges
)
```

![](visualization_files/figure-html/knowledge-plot-custom-styles-1.png)

Note that to override the colors for required and forbidden edges only
for a specific edge, the edge needs to be targeted explicitly in the
`by_edge` list of the `edge_style` argument. For example, to make the
required edge from `X1` to `X2` orange and the forbidden edge from `X2`
to `Y` yellow, while letting all other edges use the default colors, we
can do:

``` r

plot(
  kn,
  layout = "fruchterman-reingold",
  node_style = list(
    fill = "lightblue", # Fill color
    col = "darkblue", # Border color
    lwd = 2, # Border width
    padding = 4, # Text padding (mm)
    size = 1.2 # Size multiplier
  ),
  edge_style = list(
    lwd = 1.5, # Edge width
    arrow_size = 4, # Arrow size (mm)
    # Per-edge overrides
    by_edge = list(
      X1 = list(
        X2 = list(col = "orange", fill = "orange", lwd = 3)
      ),
      X2 = list(
        Y = list(col = "yellow", fill = "yellow", lwd = 3)
      )
    )
  ),
  required_col = "blue", # Color for required edges
  forbidden_col = "red" # Color for forbidden edges
)
```

![](visualization_files/figure-html/knowledge-plot-edge-by-edge-1.png)

You can also pass a custom layout to
[`plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md):

``` r

my_layout <- data.frame(
  name = c("X1", "X2", "X3", "Y", "Z"),
  x = c(1, 2, 3, 4, 5),
  y = c(1, 2, 1, 2, 1)
)
plot(kn, layout = my_layout)
```

![](visualization_files/figure-html/knowledge-plot-custom-layout-1.png)

#### Plotting Tiered Knowledge

We can also visualize tiered knowledge structures. Here is an example
using a dataset with variables measured at different life stages:

``` r

data(tpc_example)
kn_tiered <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"), # tidyselect helper; equivalent to c("child_x1", "child_x2")
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  ),
  child_x1 %-->% child_x2,
  child_x2 %!-->% youth_x3
)
plot(kn_tiered)
```

![](visualization_files/figure-html/tiered-knowledge-plot-1.png)

Variables are grouped by life stage, reflecting the tiered structure.
This helps visually convey temporal or hierarchical relationships in the
data.

### Plotting Knowledgeable Caugi Objects

Here we run a causal discovery algorithm to get a `Disco` object, which
is the knowledge object alongside the learned causal graph as a
[`caugi::caugi`](https://caugi.org/reference/caugi.html) object. We can
then plot this combined object to see both the prior knowledge and the
learned relationships

``` r

data(num_data)
kn <- knowledge(
  num_data,
  X1 %-->% X2,
  X2 %!-->% X3 + Y,
  Y %!-->% Z
)

pc_bnlearn <- pc(engine = "bnlearn", test = "fisher_z")
pc_result <- disco(num_data, method = pc_bnlearn, knowledge = kn)
plot(pc_result)
```

![](visualization_files/figure-html/knowledgeable-caugi-plot-1.png)

Blue edges indicate required relationships from prior knowledge, black
edges show those learned from the data, and forbidden edges are not
plotted (to avoid confusion and clutter).

With tiered knowledge, the plotting works similarly:

``` r

data(tpc_example)
kn_tiered <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  )
)
cd_tges <- tges(engine = "causalDisco", score = "tbic")
disco_cd_tges <- disco(
  data = tpc_example,
  method = cd_tges,
  knowledge = kn_tiered
)
plot(disco_cd_tges)
```

![](visualization_files/figure-html/knowledgeable-caugi-tiered-plot-1.png)

Where we can see the tiers reflected in the layout of the graph.

## Exporting to TikZ

The
[`make_tikz()`](https://disco-coders.github.io/causalDisco/reference/make_tikz.md)
function exports plots as clean, fully editable TikZ code for inclusion
in LaTeX documents.

Unlike some graph export tools, edges are attached to nodes rather than
positioned using hard-coded coordinates, making the output easier to
modify.

This functionality works for `Knowledge`, `Disco`, and
[`caugi::caugi`](https://caugi.org/reference/caugi.html) objects,
allowing you to customize layouts, styles, and edges further in your
LaTeX document. It calls the underlying
[`causalDisco::plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md)
method (which calls
[`caugi::plot()`](https://caugi.org/reference/plot.caugi.html)) to
generate the initial plot object before converting it to TikZ code.
Thus, you can supply any arguments to
[`make_tikz()`](https://disco-coders.github.io/causalDisco/reference/make_tikz.md)
that are supported by
[`causalDisco::plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md)
and [`caugi::plot()`](https://caugi.org/reference/plot.caugi.html).

### Exporting Knowledge to TikZ

We first demonstrate TikZ export for a `Knowledge` object.

``` r

data(num_data)
kn <- knowledge(
  num_data,
  X1 %-->% X2,
  X2 %!-->% X3 + Y,
  Y %!-->% Z
)

# Full standalone document
tikz_knowledge_code <- make_tikz(kn, scale = 10, full_doc = TRUE)
cat(tikz_knowledge_code)
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
tikz_knowledge_snippet <- make_tikz(kn, scale = 10, full_doc = FALSE)
cat(tikz_knowledge_snippet)
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
```

Setting `full_doc = TRUE` generates a complete standalone LaTeX document
that can be compiled directly. Using `full_doc = FALSE` instead returns
only the tikzpicture environment, which is convenient for inclusion
inside an existing LaTeX document; load
`\usetikzlibrary{arrows.meta, bending, backgrounds, fit, calc}` in its
preamble.

Restyle the figure by editing the named styles at the top of the output
(`var` for nodes, `link` for edges). Use `node_labels` and `tier_labels`
for LaTeX labels, e.g. `node_labels = c(X1 = "$X_1$")`.

Like
[`plot()`](https://disco-coders.github.io/causalDisco/reference/plot.md),
edges that would pass through another node are bent around it. Here
`child_x1 --> oldage_x5` bends around `youth_x3`:

``` r

data(tpc_example)
kn_tiered <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  ),
  child_x1 %-->% oldage_x5
)

plot(kn_tiered)
```

![](visualization_files/figure-html/tikz-bend-edges-1.png)

``` r


tikz_tiered <- make_tikz(kn_tiered, scale = 10, full_doc = FALSE)
cat(tikz_tiered)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   var/.style={draw, circle, fill=lightgray},
#>   link/.style={draw=blue, arrows={[scale=3]}},
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
#> \path (child_x1) edge[link, bend left=18, -Latex] (oldage_x5);
#> \end{tikzpicture}
```

Use `edge_style = list(route = FALSE)` to turn this off. The TikZ plot:

![](tikz-tier-plot.png)

### Exporting Knowledgeable Caugi to TikZ

The output of
[`disco()`](https://disco-coders.github.io/causalDisco/reference/disco.md)
gives a `Disco` object, which can also be exported to TikZ:

``` r

data(tpc_example)
kn_tiered <- knowledge(
  tpc_example,
  tier(
    child ~ starts_with("child"),
    youth ~ starts_with("youth"),
    old ~ starts_with("old")
  )
)

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
cat(tikz_snippet)
#> %%% Generated by causalDisco (version 1.3.0.9000)
#> \tikzset{
#>   var/.style={draw, circle, fill=lightgray},
#>   link/.style={arrows={[scale=3]}},
#>   tier/.style={draw, rectangle, fill=blue!20, rounded corners, inner sep=0.5cm},
#>   tier label/.style={}
#> }
#> \begin{tikzpicture}
#> \node[var] (child_x2) at (0,0) {child\_x2};
#> \node[var] (child_x1) at (0,10) {child\_x1};
#> \node[var] (youth_x4) at (5,0) {youth\_x4};
#> \node[var] (youth_x3) at (5,10) {youth\_x3};
#> \node[var] (oldage_x6) at (10,0) {oldage\_x6};
#> \node[var] (oldage_x5) at (10,10) {oldage\_x5};
#> \begin{scope}[on background layer]
#> \node[tier, fit=(child_x1)(child_x2)] (child) {};
#> \node[tier, fit=(oldage_x5)(oldage_x6)] (old) {};
#> \node[tier, fit=(youth_x3)(youth_x4)] (youth) {};
#> \end{scope}
#> \node[tier label, anchor=south] at ($(child.north)+(0cm,0.2cm)$) {child};
#> \node[tier label, anchor=south] at ($(old.north)+(0cm,0.2cm)$) {old};
#> \node[tier label, anchor=south] at ($(youth.north)+(0cm,0.2cm)$) {youth};
#> \path (child_x1) edge[link, -] (child_x2)
#>       (child_x2) edge[link, -Latex] (oldage_x5)
#>       (child_x2) edge[link, -Latex] (youth_x4)
#>       (oldage_x5) edge[link, -Latex] (oldage_x6)
#>       (youth_x3) edge[link, -Latex] (oldage_x5)
#>       (youth_x4) edge[link, -Latex] (oldage_x6);
#> \end{tikzpicture}
```

### Classic Style

`style = "classic"` gives a minimal look: plain-text nodes, gray tier
bands, and a time axis. Here for a PAG from
[`tfci()`](https://disco-coders.github.io/causalDisco/reference/tfci.md):

``` r

cd_tfci <- tfci(engine = "causalDisco", test = "fisher_z", alpha = 0.05)
disco_cd_tfci <- disco(
  data = tpc_example,
  method = cd_tfci,
  knowledge = kn_tiered
)

tikz_classic <- make_tikz(
  disco_cd_tfci,
  style = "classic",
  node_labels = c(
    child_x1 = "$X_1$",
    child_x2 = "$X_2$",
    youth_x3 = "$X_3$",
    youth_x4 = "$X_4$",
    oldage_x5 = "$X_5$",
    oldage_x6 = "$X_6$"
  ),
  tier_labels = c(child = "Childhood", youth = "Youth", old = "Old age"),
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
#> \node[var] (child_x2) at (-0.15,0) {$X_2$};
#> \node[var] (child_x1) at (0.15,1) {$X_1$};
#> \node[var] (youth_x4) at (0.85,0) {$X_4$};
#> \node[var] (youth_x3) at (1.15,1) {$X_3$};
#> \node[var] (oldage_x6) at (1.85,0) {$X_6$};
#> \node[var] (oldage_x5) at (2.15,1) {$X_5$};
#> \path[link] (child_x2) edge[o-o, bend left=10] (child_x1)
#>       (child_x2) edge[o->, bend left=6] (oldage_x5)
#>       (child_x2) edge[o->, bend right=20] (youth_x4)
#>       (oldage_x5) edge[->, bend right=10] (oldage_x6)
#>       (youth_x3) edge[o->, bend left=30] (oldage_x5)
#>       (youth_x4) edge[->, bend right=10] (oldage_x6);
#> \begin{scope}[on background layer]
#> \node[tier, fit={(child_x2)(child_x1)(0,-0.5)(0,1.5)}] (tier-1) {};
#> \node[tier, fit={(youth_x4)(youth_x3)(1,-0.5)(1,1.5)}] (tier-2) {};
#> \node[tier, fit={(oldage_x6)(oldage_x5)(2,-0.5)(2,1.5)}] (tier-3) {};
#> \end{scope}
#> \draw[time axis] ([xshift=-3mm]tier-1.south west) -- ([xshift=5mm]tier-3.south east);
#> \node[tier label, below=3pt] at (tier-1.south) {Childhood};
#> \node[tier label, below=3pt] at (tier-2.south) {Youth};
#> \node[tier label, below=3pt] at (tier-3.south) {Old age};
#> \end{tikzpicture}
```

![](tikz-classic-plot.png)

### Exporting Caugi Objects to TikZ

The same export mechanism also applies to standard
[`caugi::caugi`](https://caugi.org/reference/caugi.html) objects:

``` r

cg <- caugi::caugi(
  A %-->% B + C
)
plot_obj <- plot(cg, node_style = list(fill = "red"))
tikz_caugi_snippet <- make_tikz(plot_obj, scale = 10, full_doc = FALSE)
```

![](visualization_files/figure-html/tikz-export-caugi-1.png)

``` r

cat(tikz_caugi_snippet)
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
