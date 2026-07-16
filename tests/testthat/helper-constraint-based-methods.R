# ──────────────────────────────────────────────────────────────────────────────
# Helpers for testing constraint-based methods (pc, fci) across engines
# ──────────────────────────────────────────────────────────────────────────────

method_registry_constraint <- list(
  pc = list(fn = pc, engines = c("tetrad", "pcalg", "bnlearn")),
  fci = list(fn = fci, engines = c("tetrad", "pcalg"))
)

method_args <- function(method_name, engine) {
  list(test = "fisher_z", alpha = 0.05)
}

toy_knowledge <- function(df) {
  knowledge(
    df,
    X1 %-->% X2,
    X3 %-->% Z
  )
}
