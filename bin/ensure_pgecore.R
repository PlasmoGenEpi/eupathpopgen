#!/usr/bin/env Rscript
# Ensure PGEcore is installed from the configured GitHub ref unless PGECORE_HOME is set.
# Always install into ./r_libs in the task work directory so docker -u uid:gid can write
# (default ~/R/... expands to a non-writable path inside nf-core containers).
args <- commandArgs(trailingOnly = TRUE)
repo <- if (length(args) >= 1) args[[1]] else "PlasmoGenEpi/PGEcore"
ref  <- if (length(args) >= 2) args[[2]] else "HEAD"

libs_user <- file.path(getwd(), "r_libs")
Sys.setenv(R_LIBS_USER = libs_user)
dir.create(libs_user, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(libs_user, .libPaths()))

if (nzchar(Sys.getenv("PGECORE_HOME"))) {
  message("PGECORE_HOME is set; skipping GitHub install of PGEcore.")
  quit(save = "no", status = 0)
}

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", lib = libs_user, repos = "https://cloud.r-project.org")
}

if (!requireNamespace("PGEcore", quietly = TRUE)) {
  message("Installing PGEcore from GitHub ", repo, "@", ref, " into ", libs_user)
  remotes::install_github(
    paste0(repo, "@", ref),
    lib = libs_user,
    upgrade = "never",
    dependencies = TRUE,
    quiet = FALSE
  )
} else {
  message("PGEcore already installed: ", as.character(utils::packageVersion("PGEcore")))
}
