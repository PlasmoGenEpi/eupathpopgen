#!/usr/bin/env bash
# Resolve and run a PGEcore exec/ CLI.
# Prefer PGECORE_HOME/exec (pgecore_local), else system.file("exec", package="PGEcore").
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: pgecore_cli.sh <cli_name> [args...]" >&2
    exit 1
fi

CLI_NAME="$1"
shift

# Prefer work-dir library for module installs (docker -u / Suggests), but keep any
# existing R_LIBS_USER (e.g. PGECORE_HOME/.r_libs from -profile pgecore_local).
mkdir -p "${PWD}/r_libs"
export R_LIBS_USER="${PWD}/r_libs${R_LIBS_USER:+:${R_LIBS_USER}}"
export R_LIBS="${R_LIBS_USER}${R_LIBS:+:${R_LIBS}}"

resolve_cli() {
    if [[ -n "${PGECORE_HOME:-}" && -f "${PGECORE_HOME}/exec/${CLI_NAME}" ]]; then
        echo "${PGECORE_HOME}/exec/${CLI_NAME}"
        return
    fi
    local exec_dir
    exec_dir="$(Rscript -e 'cat(system.file("exec", package = "PGEcore"))')"
    if [[ -n "${exec_dir}" && -f "${exec_dir}/${CLI_NAME}" ]]; then
        echo "${exec_dir}/${CLI_NAME}"
        return
    fi
    echo "ERROR: Could not find PGEcore CLI '${CLI_NAME}'." >&2
    echo "Install PGEcore or set PGECORE_HOME to a source checkout." >&2
    exit 1
}

CLI_PATH="$(resolve_cli)"
exec Rscript "${CLI_PATH}" "$@"
