# Regenerates man/figures/algorithms-table-{light,dark}.svg.
# Requires `pdflatex` and `dvisvgm` on PATH (both ship with any TeX Live / MiKTeX install).
#
#   Rscript tools/render-algorithms-table.R

if (Sys.which("pdflatex") == "") {
  stop("pdflatex not found on PATH")
}
if (Sys.which("dvisvgm") == "") {
  stop("dvisvgm not found on PATH")
}

tools_dir <- "tools"
out_dir <- "man/figures"
variants <- c("light", "dark")

build_dir <- tempfile("algo-table-")
dir.create(build_dir)
on.exit(unlink(build_dir, recursive = TRUE), add = TRUE)

for (variant in variants) {
  tex_file <- file.path(
    tools_dir,
    sprintf("algorithms-table-%s.tex", variant)
  )
  content_file <- file.path(tools_dir, "algorithms-table-content.tex")

  file.copy(tex_file, build_dir, overwrite = TRUE)
  file.copy(content_file, build_dir, overwrite = TRUE)

  status <- system2(
    "pdflatex",
    c(
      "-interaction=nonstopmode",
      sprintf("-output-directory=%s", build_dir),
      file.path(build_dir, basename(tex_file))
    ),
    stdout = FALSE,
    stderr = FALSE
  )
  if (status != 0) {
    stop(sprintf("pdflatex failed for %s variant", variant))
  }

  pdf_file <- file.path(
    build_dir,
    sprintf("algorithms-table-%s.pdf", variant)
  )
  svg_file <- file.path(
    out_dir,
    sprintf("algorithms-table-%s.svg", variant)
  )

  status <- system2(
    "dvisvgm",
    c(
      "--pdf",
      "--no-fonts",
      "--exact",
      sprintf("--output=%s", svg_file),
      pdf_file
    ),
    stdout = FALSE,
    stderr = FALSE
  )
  if (status != 0) {
    stop(sprintf("dvisvgm failed for %s variant", variant))
  }

  message(sprintf("Wrote %s", svg_file))
}
