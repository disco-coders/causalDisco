# ──────────────────────────────────────────────────────────────────────────────
# Helper functions for tests
# ──────────────────────────────────────────────────────────────────────────────

ges_registry <- list(
  ges = list(fn = ges, engines = c("tetrad", "pcalg"))
)

ges_args <- function(engine) {
  list(score = "sem_bic")
}
