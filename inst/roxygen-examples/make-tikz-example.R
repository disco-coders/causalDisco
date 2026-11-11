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

# Only the tikzpicture environment
tikz_kn_snippet <- make_tikz(kn, full_doc = FALSE)
cat(tikz_kn_snippet)

# With bent edges
tikz_bent <- make_tikz(
  kn,
  full_doc = FALSE,
  bend = 25
)
cat(tikz_bent)

# With a color not supported by default TikZ colors; will fall back to RGB
tikz_darkblue <- make_tikz(
  kn,
  node_style = list(fill = "darkblue"),
  full_doc = FALSE
)
cat(tikz_darkblue)

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

# Classic style with LaTeX labels
tikz_classic <- make_tikz(
  kn_tiered,
  style = "classic",
  node_labels = c(child_x1 = "$X_1$", child_x2 = "$X_2$"),
  tier_labels = c(child = "Childhood", old = "Old age"),
  full_doc = FALSE
)
cat(tikz_classic)

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

# Draw every edge exactly with the requested bend instead
tikz_exact <- make_tikz(
  cg_line,
  layout = layout_line,
  style = "classic",
  edge_style = list(route = FALSE),
  full_doc = FALSE
)
cat(tikz_exact)

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

################# Convert caugi objects to Tikz ################

cg <- caugi::caugi(A %-->% B + C)

tikz_snippet <- make_tikz(
  cg,
  node_style = list(fill = "red"),
  scale = 10,
  full_doc = FALSE
)
cat(tikz_snippet)
