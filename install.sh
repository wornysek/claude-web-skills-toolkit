#!/usr/bin/env bash
# =============================================================================
#  claude-web-skills-toolkit — install.sh
#
#  Installer for skills, official plugins and MCP servers for Claude Code.
#
#  Usage:
#    ./install.sh                 interactive component selection
#    ./install.sh --all           installs everything without prompts
#    ./install.sh --skills        only copies the markdown skills into ./.claude/skills
#    ./install.sh --help          full help
#
#  Run the script from the root of the project you want to integrate the toolkit
#  into (project-level configuration such as .mcp.json and .claude/skills is
#  created in the current working directory). The script is idempotent — it skips
#  components that are already installed. Compatible with Bash 3.2+ (macOS),
#  Linux and Git Bash / WSL.
#
#  License: MIT — see the LICENSE file.
# =============================================================================

set -euo pipefail

readonly TOOLKIT_VERSION="1.0.0"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
readonly SKILLS_SRC="${SCRIPT_DIR}/skills"
readonly PROJECT_DIR="${PWD}"

readonly MAGIC_MCP_NAME="21st"
readonly MAGIC_MCP_URL="https://21st.dev/api/mcp"
readonly VERCEL_SKILLS_REPO="vercel-labs/agent-skills"
readonly VERCEL_DEFAULT_SKILLS="web-design-guidelines react-best-practices writing-guidelines"

# --- Options -----------------------------------------------------------------
DO_PLUGINS=0
DO_CHROME=0
DO_SHADCN=0
DO_VERCEL=0
DO_MAGIC=0
DO_SKILLS=0
DO_HOOKS=0
SKILLS_GLOBAL=0
FORCE=0
DRY_RUN=0
ASSUME_YES=0
INTERACTIVE=0

# --- Results -----------------------------------------------------------------
RESULTS_OK=()
RESULTS_SKIP=()
RESULTS_FAIL=()

# --- Colors (disabled outside a terminal or with NO_COLOR) -------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  readonly C_RESET=$'\033[0m' C_BOLD=$'\033[1m' C_DIM=$'\033[2m'
  readonly C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_BLUE=$'\033[34m'
else
  readonly C_RESET='' C_BOLD='' C_DIM=''
  readonly C_RED='' C_GREEN='' C_YELLOW='' C_BLUE=''
fi

# =============================================================================
#  Helpers
# =============================================================================

info()    { printf '%s==>%s %s\n' "${C_BLUE}${C_BOLD}" "${C_RESET}" "$*"; }
ok()      { printf '%s  ✔%s %s\n' "${C_GREEN}" "${C_RESET}" "$*"; }
warn()    { printf '%s  ⚠%s %s\n' "${C_YELLOW}" "${C_RESET}" "$*" >&2; }
err()     { printf '%s  ✖%s %s\n' "${C_RED}" "${C_RESET}" "$*" >&2; }
die()     { err "$*"; exit 1; }
section() { printf '\n%s%s%s\n' "${C_BOLD}" "$*" "${C_RESET}"; }

mark_ok()   { RESULTS_OK+=("$1"); }
mark_skip() { RESULTS_SKIP+=("$1"); }
mark_fail() { RESULTS_FAIL+=("$1"); }

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Prints a command and runs it; in --dry-run mode it only prints it.
run() {
  if (( DRY_RUN )); then
    printf '%s     [dry-run]%s' "${C_DIM}" "${C_RESET}"
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  printf '%s     $%s' "${C_DIM}" "${C_RESET}"
  printf ' %q' "$@"
  printf '\n'
  "$@"
}

# Same as run(), but prints the given description instead of the arguments.
# Used for commands that contain secret values (API keys), so they never show up
# in the output or in a CI log, and for long inline scripts.
run_secret() {
  local display="$1"
  shift
  if (( DRY_RUN )); then
    printf '%s     [dry-run]%s %s\n' "${C_DIM}" "${C_RESET}" "${display}"
    return 0
  fi
  printf '%s     $%s %s\n' "${C_DIM}" "${C_RESET}" "${display}"
  "$@"
}

# Checks that the commands a component needs are available.
# In --dry-run mode a missing tool is only reported and the run continues.
require() {
  local component="$1"
  shift
  local cmd
  local missing=0
  for cmd in "$@"; do
    if ! has_cmd "${cmd}"; then
      if (( DRY_RUN )); then
        warn "${component}: '${cmd}' is missing (dry-run continues)."
      else
        err "${component}: command '${cmd}' is missing."
        missing=1
      fi
    fi
  done
  return "${missing}"
}

# Yes/no question. The default answer is NO. With --yes it is always YES.
# Without a terminal (CI, pipe) it returns NO, so the script never waits for input.
confirm() {
  local prompt="$1"
  local reply=""
  if (( ASSUME_YES )); then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    return 1
  fi
  read -r -p "  ? ${prompt} [y/N] " reply || return 1
  case "${reply}" in
    y|Y|yes|Yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

on_interrupt() {
  printf '\n'
  warn "Installation interrupted by the user."
  exit 130
}
trap on_interrupt INT

usage() {
  cat <<EOF
${C_BOLD}claude-web-skills-toolkit${C_RESET} v${TOOLKIT_VERSION} — skills and MCP server installer for Claude Code

${C_BOLD}USAGE${C_RESET}
  ./install.sh [options]

  Without options, an interactive menu is shown in a terminal.

${C_BOLD}COMPONENTS${C_RESET}
  --all             Install everything (implies --yes)
  --plugins         Official plugins: frontend-design, superpowers
  --chrome          chrome-devtools MCP server (scope: user)
  --shadcn          shadcn MCP server (project .mcp.json in the current directory)
  --vercel          Vercel Labs agent skills (${VERCEL_DEFAULT_SKILLS})
  --magic           21st.dev MCP (needs an API key in API_KEY_21ST or entered at the prompt)
  --mcp             Shortcut for --chrome --shadcn --magic
  --skills          Copy the markdown skills into ./.claude/skills
  --hooks           Slop & secrets guard hook (./.claude/hooks + ./.claude/settings.json)

${C_BOLD}MODIFIERS${C_RESET}
  --global          Copy skills into ~/.claude/skills instead of ./.claude/skills
  --force           Overwrite skills that already exist
  -y, --yes         Answer YES to all prompts
  --dry-run         Only print the commands, run nothing
  -h, --help        Show this help
  -v, --version     Show the version

${C_BOLD}ENVIRONMENT VARIABLES${C_RESET}
  API_KEY_21ST      API key for the 21st.dev MCP (https://21st.dev/mcp)
  NO_COLOR          Disable colored output

${C_BOLD}EXAMPLES${C_RESET}
  ./install.sh --all
  ./install.sh --skills --force
  ./install.sh --plugins --chrome --dry-run
  ./install.sh --magic           # without API_KEY_21ST it asks with hidden input
EOF
}

# =============================================================================
#  Argument parsing
# =============================================================================

parse_args() {
  if (( $# == 0 )); then
    INTERACTIVE=1
    return 0
  fi

  while (( $# > 0 )); do
    case "$1" in
      --all)
        DO_PLUGINS=1; DO_CHROME=1; DO_SHADCN=1; DO_VERCEL=1; DO_MAGIC=1; DO_SKILLS=1; DO_HOOKS=1
        ASSUME_YES=1
        ;;
      --plugins) DO_PLUGINS=1 ;;
      --chrome)  DO_CHROME=1 ;;
      --shadcn)  DO_SHADCN=1 ;;
      --vercel)  DO_VERCEL=1 ;;
      --magic)   DO_MAGIC=1 ;;
      --mcp)     DO_CHROME=1; DO_SHADCN=1; DO_MAGIC=1 ;;
      --skills)  DO_SKILLS=1 ;;
      --hooks)   DO_HOOKS=1 ;;
      --global)  SKILLS_GLOBAL=1 ;;
      --force)   FORCE=1 ;;
      -y|--yes)  ASSUME_YES=1 ;;
      --dry-run) DRY_RUN=1 ;;
      -h|--help)
        usage
        exit 0
        ;;
      -v|--version)
        printf '%s\n' "${TOOLKIT_VERSION}"
        exit 0
        ;;
      *)
        err "Unknown option: $1"
        printf '\n' >&2
        usage >&2
        exit 2
        ;;
    esac
    shift
  done

  # Modifiers alone (e.g. just --dry-run) without a component => interactive menu.
  if (( DO_PLUGINS + DO_CHROME + DO_SHADCN + DO_VERCEL + DO_MAGIC + DO_SKILLS + DO_HOOKS == 0 )); then
    INTERACTIVE=1
  fi
}

# =============================================================================
#  Interactive menu
# =============================================================================

interactive_menu() {
  if [[ ! -t 0 ]]; then
    err "No component was given and the input is not a terminal."
    printf '\n' >&2
    usage >&2
    exit 2
  fi

  section "Choose the components to install"
  cat <<EOF
  1) Official plugins         frontend-design, superpowers (Anthropic marketplace)
  2) MCP: chrome-devtools     runtime debugging in Chrome (Google Chrome DevTools)
  3) MCP: shadcn              shadcn/ui component registry (.mcp.json in the project)
  4) Vercel agent skills      web-design-guidelines, react-best-practices, writing-guidelines
  5) MCP: 21st.dev            interactive UI components and animations (API key)
  6) Markdown skills          copy skills/* into ./.claude/skills
  7) Hook: guard              blocks secrets, flags AI writing tells (.claude/settings.json)
  a) All
  q) Quit
EOF
  printf '\n'

  local tokens=()
  read -r -a tokens -p "  Enter numbers separated by spaces (e.g. 1 3 6): " || exit 1

  local token
  for token in ${tokens[@]+"${tokens[@]}"}; do
    case "${token}" in
      1) DO_PLUGINS=1 ;;
      2) DO_CHROME=1 ;;
      3) DO_SHADCN=1 ;;
      4) DO_VERCEL=1 ;;
      5) DO_MAGIC=1 ;;
      6) DO_SKILLS=1 ;;
      7) DO_HOOKS=1 ;;
      a|A) DO_PLUGINS=1; DO_CHROME=1; DO_SHADCN=1; DO_VERCEL=1; DO_MAGIC=1; DO_SKILLS=1; DO_HOOKS=1 ;;
      q|Q) info "Exited without changes."; exit 0 ;;
      *) warn "Unknown choice '${token}' — ignoring." ;;
    esac
  done

  if (( DO_PLUGINS + DO_CHROME + DO_SHADCN + DO_VERCEL + DO_MAGIC + DO_SKILLS + DO_HOOKS == 0 )); then
    info "Nothing selected, exiting."
    exit 0
  fi

  if (( DO_SKILLS && ! SKILLS_GLOBAL )); then
    if confirm "Copy skills globally into ~/.claude/skills (otherwise into ./.claude/skills)?"; then
      SKILLS_GLOBAL=1
    fi
  fi
}

# =============================================================================
#  Environment check
# =============================================================================

check_prereqs() {
  section "Environment check"

  if has_cmd claude; then
    local claude_version
    claude_version="$(claude --version 2>/dev/null || true)"
    ok "claude ${claude_version:-"(unknown version)"}"
  else
    warn "Claude Code CLI ('claude') not found — plugins and MCP registration will not be available."
    warn "Installation: https://claude.com/claude-code"
  fi

  if has_cmd npx; then
    local npx_version
    npx_version="$(npx --version 2>/dev/null || true)"
    ok "npx ${npx_version:-"(unknown version)"}"
  else
    warn "npx not found — install Node.js 20+ (https://nodejs.org)."
  fi

  if has_cmd node; then
    local node_major
    node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || printf '0')"
    if [[ "${node_major}" =~ ^[0-9]+$ ]] && (( node_major < 20 )); then
      warn "Node.js ${node_major} is outdated; chrome-devtools-mcp and shadcn require Node.js 20+."
    else
      ok "node v${node_major}"
    fi
  fi

  if [[ ! -d "${SKILLS_SRC}" ]]; then
    die "Skills folder not found: ${SKILLS_SRC}"
  fi

  info "Toolkit:  ${SCRIPT_DIR}"
  info "Project:  ${PROJECT_DIR}"
  if [[ "${PROJECT_DIR}" == "${SCRIPT_DIR}" ]]; then
    warn "You are running the installer inside the toolkit itself. Project-level configuration"
    warn "(.mcp.json, .claude/skills) will be created in the toolkit repository."
  fi
  if (( DRY_RUN )); then
    warn "--dry-run mode: no command will be run."
  fi
}

# =============================================================================
#  1) Official plugins
# =============================================================================

add_marketplace() {
  local source="$1"
  local name="$2"
  local listing=""

  if (( ! DRY_RUN )); then
    listing="$(claude plugin marketplace list 2>/dev/null || true)"
    if grep -qF -- "${name}" <<<"${listing}"; then
      ok "Marketplace '${name}' is already registered."
      return 0
    fi
  fi

  if run claude plugin marketplace add "${source}"; then
    ok "Marketplace '${name}' added."
  else
    warn "Could not add marketplace '${name}' (it may be pre-registered) — continuing."
  fi
}

install_plugin() {
  local plugin="$1"
  local short_name="${plugin%@*}"
  local listing=""

  if (( ! DRY_RUN )); then
    listing="$(claude plugin list 2>/dev/null || true)"
    if grep -qF -- "${plugin}" <<<"${listing}"; then
      ok "Plugin '${plugin}' is already installed."
      mark_skip "Plugin ${short_name} (already installed)"
      return 0
    fi
  fi

  if run claude plugin install "${plugin}"; then
    ok "Plugin '${plugin}' installed."
    mark_ok "Plugin ${short_name}"
  else
    err "Installing plugin '${plugin}' failed."
    mark_fail "Plugin ${short_name}"
  fi
}

install_plugins() {
  section "1) Official Claude Code plugins"

  if ! require "Plugins" claude; then
    mark_fail "Plugins (claude CLI missing)"
    return 0
  fi

  # Marketplace from the anthropics/claude-code repository (registered as "claude-code-plugins").
  add_marketplace "anthropics/claude-code" "claude-code-plugins"
  # Anthropic's official plugin directory. Newer Claude Code versions have it
  # pre-registered, so this step tolerates an "already exists" error.
  add_marketplace "anthropics/claude-plugins-official" "claude-plugins-official"

  install_plugin "frontend-design@claude-code-plugins"
  install_plugin "superpowers@claude-plugins-official"
}

# =============================================================================
#  2) MCP: chrome-devtools
# =============================================================================

mcp_exists() {
  local name="$1"
  if (( DRY_RUN )); then
    return 1
  fi
  claude mcp get "${name}" >/dev/null 2>&1
}

install_chrome_devtools() {
  section "2) MCP server: chrome-devtools"

  if ! require "chrome-devtools" claude npx; then
    mark_fail "MCP chrome-devtools (claude/npx missing)"
    return 0
  fi

  if mcp_exists "chrome-devtools"; then
    ok "MCP server 'chrome-devtools' is already registered."
    mark_skip "MCP chrome-devtools (already registered)"
    return 0
  fi

  if run claude mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest; then
    ok "MCP server 'chrome-devtools' registered (scope: user)."
    mark_ok "MCP chrome-devtools"
  else
    err "Registering the 'chrome-devtools' MCP server failed."
    mark_fail "MCP chrome-devtools"
  fi
}

# =============================================================================
#  3) MCP: shadcn
# =============================================================================

install_shadcn() {
  section "3) MCP server: shadcn (project-level)"

  if ! require "shadcn" npx; then
    mark_fail "MCP shadcn (npx missing)"
    return 0
  fi

  if [[ -f "${PROJECT_DIR}/.mcp.json" ]] && grep -qF -- '"shadcn"' "${PROJECT_DIR}/.mcp.json"; then
    ok "Server 'shadcn' is already in ${PROJECT_DIR}/.mcp.json."
    mark_skip "MCP shadcn (already in .mcp.json)"
    return 0
  fi

  if [[ ! -f "${PROJECT_DIR}/package.json" ]]; then
    warn "There is no package.json in ${PROJECT_DIR} — the shadcn MCP belongs in the root of a web project."
    if ! confirm "Write .mcp.json into the current directory anyway?"; then
      mark_skip "MCP shadcn (not a web project)"
      return 0
    fi
  fi

  if run npx --yes shadcn@latest mcp init --client claude; then
    ok "shadcn MCP configuration written to ${PROJECT_DIR}/.mcp.json."
    mark_ok "MCP shadcn"
  else
    err "Initializing the shadcn MCP failed."
    mark_fail "MCP shadcn"
  fi
}

# =============================================================================
#  4) Vercel Labs agent skills
# =============================================================================

install_vercel_skills() {
  section "4) Vercel Labs agent skills"

  if ! require "Vercel skills" npx; then
    mark_fail "Vercel agent skills (npx missing)"
    return 0
  fi

  local status=0
  if (( INTERACTIVE && ! ASSUME_YES )); then
    # Interactive mode: the 'skills' CLI lets the user choose the skills and the target.
    run npx --yes skills add "${VERCEL_SKILLS_REPO}" || status=$?
  else
    # Non-interactive mode: the recommended set of skills for Claude Code, no prompts.
    # shellcheck disable=SC2086
    run npx --yes skills add "${VERCEL_SKILLS_REPO}" \
      --skill ${VERCEL_DEFAULT_SKILLS} \
      --agent claude-code \
      --yes || status=$?
  fi

  if (( status == 0 )); then
    ok "Vercel agent skills installed."
    mark_ok "Vercel agent skills"
  else
    err "Installing Vercel agent skills failed (exit ${status})."
    mark_fail "Vercel agent skills"
  fi
}

# =============================================================================
#  5) MCP: 21st.dev (Magic)
# =============================================================================

install_magic() {
  section "5) MCP server: 21st.dev (Magic)"

  if ! require "21st.dev" claude; then
    mark_fail "MCP 21st.dev (claude CLI missing)"
    return 0
  fi

  if mcp_exists "${MAGIC_MCP_NAME}"; then
    ok "MCP server '${MAGIC_MCP_NAME}' is already registered."
    mark_skip "MCP 21st.dev (already registered)"
    return 0
  fi

  local api_key="${API_KEY_21ST:-${TWENTYFIRST_TOKEN:-}}"
  if [[ -z "${api_key}" ]]; then
    if [[ -t 0 ]] && (( ! DRY_RUN )); then
      info "Get an API key at https://21st.dev/mcp (input is hidden)."
      read -r -s -p "  ? 21st.dev API key (Enter = skip): " api_key || api_key=""
      printf '\n'
    fi
  fi

  if [[ -z "${api_key}" ]]; then
    if (( DRY_RUN )); then
      api_key="<API_KEY_21ST>"
    else
      warn "No API key given — skipping 21st.dev. Run later: ./install.sh --magic"
      mark_skip "MCP 21st.dev (API key missing)"
      return 0
    fi
  fi

  if [[ "${api_key}" =~ [[:space:]] ]]; then
    err "The API key contains whitespace — check that you copied all of it correctly."
    mark_fail "MCP 21st.dev (invalid API key)"
    return 0
  fi

  # The key is stored only in Claude Code's user configuration (~/.claude.json),
  # never in the repository. It is masked in the output.
  if run_secret \
    "claude mcp add --transport http --scope user ${MAGIC_MCP_NAME} ${MAGIC_MCP_URL} --header 'x-api-key: ****'" \
    claude mcp add --transport http --scope user "${MAGIC_MCP_NAME}" "${MAGIC_MCP_URL}" \
    --header "x-api-key: ${api_key}"; then
    ok "MCP server '${MAGIC_MCP_NAME}' registered (scope: user)."
    mark_ok "MCP 21st.dev"
  else
    err "Registering the 21st.dev MCP failed. Alternative: npx @21st-dev/cli@latest init --client claude --write"
    mark_fail "MCP 21st.dev"
  fi

  api_key=""
}

# =============================================================================
#  6) Markdown skills
# =============================================================================

copy_skills() {
  section "6) Markdown skills"

  local dest_root
  if (( SKILLS_GLOBAL )); then
    dest_root="${HOME}/.claude/skills"
  else
    dest_root="${PROJECT_DIR}/.claude/skills"
  fi
  info "Target: ${dest_root}"

  if (( ! DRY_RUN )); then
    mkdir -p -- "${dest_root}"
  fi

  local copied=0
  local skipped=0
  local failed=0
  local src name dest

  for src in "${SKILLS_SRC}"/*/; do
    src="${src%/}"
    [[ -f "${src}/SKILL.md" ]] || continue
    name="${src##*/}"
    dest="${dest_root}/${name}"

    # Safety check: the target path must be inside dest_root and have a non-empty name.
    if [[ -z "${name}" || "${dest}" != "${dest_root}/"* ]]; then
      err "Invalid target path for skill '${name}' — skipping."
      failed=$((failed + 1))
      continue
    fi

    if [[ -e "${dest}" ]]; then
      if (( FORCE )) || { (( ! ASSUME_YES )) && confirm "Skill '${name}' already exists. Overwrite?"; }; then
        if (( ! DRY_RUN )); then
          rm -rf -- "${dest}"
        fi
      else
        printf '%s     – %s (exists, skipped; use --force)%s\n' "${C_DIM}" "${name}" "${C_RESET}"
        skipped=$((skipped + 1))
        continue
      fi
    fi

    if run cp -R -- "${src}" "${dest}"; then
      ok "${name}"
      copied=$((copied + 1))
    else
      err "Copying skill '${name}' failed."
      failed=$((failed + 1))
    fi
  done

  if (( failed > 0 )); then
    mark_fail "Markdown skills (${failed} failed)"
  fi
  if (( copied > 0 )); then
    mark_ok "Markdown skills: ${copied} copied to ${dest_root}"
  fi
  if (( skipped > 0 )); then
    mark_skip "Markdown skills: ${skipped} already exist"
  fi
  if (( copied + skipped + failed == 0 )); then
    warn "No SKILL.md was found in ${SKILLS_SRC}."
    mark_fail "Markdown skills (nothing to install)"
  fi
}

# =============================================================================
#  7) Hook: slop & secrets guard
# =============================================================================

# Adds the guard to an existing .claude/settings.json without touching other settings.
# Tries node, then python; returns 1 if neither is available or the file isn't valid JSON.
merge_hook_settings() {
  local settings="$1"
  local node_merge='
const fs = require("fs");
const file = process.argv[1];
const settings = JSON.parse(fs.readFileSync(file, "utf8"));
settings.hooks = settings.hooks || {};
for (const [event, mode] of [["PreToolUse", "secrets"], ["PostToolUse", "slop"]]) {
  const list = (settings.hooks[event] = settings.hooks[event] || []);
  if (JSON.stringify(list).includes("slop-secrets-guard.sh")) continue;
  list.push({
    matcher: "Write|Edit|MultiEdit",
    hooks: [{ type: "command", command: `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/slop-secrets-guard.sh" ${mode}`, timeout: 15 }],
  });
}
fs.writeFileSync(file, JSON.stringify(settings, null, 2) + "\n");
'
  local python_merge='
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    settings = json.load(f)
hooks = settings.setdefault("hooks", {})
for event, mode in (("PreToolUse", "secrets"), ("PostToolUse", "slop")):
    entries = hooks.setdefault(event, [])
    if "slop-secrets-guard.sh" in json.dumps(entries):
        continue
    entries.append({
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [{"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/slop-secrets-guard.sh\" " + mode, "timeout": 15}],
    })
with open(path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")
'
  if has_cmd node; then
    run_secret "node -e <merge hook config> ${settings}" node -e "${node_merge}" "${settings}" && return 0
    return 1
  fi
  local py
  for py in python3 python; do
    if has_cmd "${py}" && "${py}" -c "import json" >/dev/null 2>&1; then
      run_secret "${py} -c <merge hook config> ${settings}" "${py}" -c "${python_merge}" "${settings}" && return 0
      return 1
    fi
  done
  return 1
}

install_hooks() {
  section "7) Hook: slop & secrets guard"

  local src="${SCRIPT_DIR}/hooks/slop-secrets-guard.sh"
  local example="${SCRIPT_DIR}/hooks/settings.example.json"
  local hooks_dir="${PROJECT_DIR}/.claude/hooks"
  local dest="${hooks_dir}/slop-secrets-guard.sh"
  local settings="${PROJECT_DIR}/.claude/settings.json"

  if [[ ! -f "${src}" || ! -f "${example}" ]]; then
    err "Hook files not found in ${SCRIPT_DIR}/hooks."
    mark_fail "Hook (files missing)"
    return 0
  fi

  # 1. The script itself (owned by the toolkit, refreshed when it changed).
  if [[ -f "${dest}" ]] && cmp -s "${src}" "${dest}"; then
    ok "Hook script is up to date: ${dest}"
  elif [[ -f "${dest}" ]] && ! (( FORCE )) && ! confirm "A different ${dest} exists. Overwrite it?"; then
    warn "Keeping the existing hook script (use --force to overwrite)."
  else
    if (( ! DRY_RUN )); then mkdir -p -- "${hooks_dir}"; fi
    if ! run cp -- "${src}" "${dest}"; then
      err "Copying the hook script failed."
      mark_fail "Hook (copy failed)"
      return 0
    fi
    if (( ! DRY_RUN )); then chmod +x "${dest}" 2>/dev/null || true; fi
    ok "Hook script installed: ${dest}"
  fi

  # 2. Registration in .claude/settings.json.
  if [[ -f "${settings}" ]] && grep -qF 'slop-secrets-guard.sh' "${settings}"; then
    ok "Hook is already registered in ${settings}."
    mark_skip "Hook (already registered)"
    return 0
  fi

  if [[ ! -f "${settings}" ]]; then
    if run cp -- "${example}" "${settings}"; then
      ok "Created ${settings} with the hook configuration."
      mark_ok "Hook: slop & secrets guard"
    else
      err "Writing ${settings} failed."
      mark_fail "Hook (settings not written)"
    fi
    return 0
  fi

  if (( ! DRY_RUN )); then cp -- "${settings}" "${settings}.bak"; fi
  if merge_hook_settings "${settings}"; then
    ok "Hook registered in ${settings} (backup: settings.json.bak)."
    mark_ok "Hook: slop & secrets guard"
  else
    warn "Could not merge ${settings} automatically (needs node or python, and valid JSON)."
    warn "Add the \"hooks\" block from ${example} to it by hand."
    mark_fail "Hook (manual merge needed)"
  fi
}

# =============================================================================
#  Summary
# =============================================================================

print_summary() {
  section "Summary"

  local item
  if (( ${#RESULTS_OK[@]} > 0 )); then
    for item in "${RESULTS_OK[@]}"; do ok "${item}"; done
  fi
  if (( ${#RESULTS_SKIP[@]} > 0 )); then
    for item in "${RESULTS_SKIP[@]}"; do
      printf '%s  –%s %s\n' "${C_DIM}" "${C_RESET}" "${item}"
    done
  fi
  if (( ${#RESULTS_FAIL[@]} > 0 )); then
    for item in "${RESULTS_FAIL[@]}"; do err "${item}"; done
  fi

  printf '\n'
  info "Next steps:"
  printf '     1. Restart Claude Code so it loads the new plugins, skills and MCP servers.\n'
  printf '     2. In Claude Code, check the status with /plugin, /mcp and /skills.\n'
  printf '     3. Commit the project files (.mcp.json, .claude/skills) to the project repository.\n'
  printf '        Secret values (API keys) never belong in the repository.\n'

  if (( ${#RESULTS_FAIL[@]} > 0 )); then
    return 1
  fi
  return 0
}

# =============================================================================
#  main
# =============================================================================

main() {
  parse_args "$@"

  printf '%sclaude-web-skills-toolkit%s v%s\n' "${C_BOLD}" "${C_RESET}" "${TOOLKIT_VERSION}"

  if (( INTERACTIVE )); then
    interactive_menu
  fi

  check_prereqs

  if (( DO_PLUGINS )); then install_plugins;        fi
  if (( DO_CHROME ));  then install_chrome_devtools; fi
  if (( DO_SHADCN ));  then install_shadcn;          fi
  if (( DO_VERCEL ));  then install_vercel_skills;   fi
  if (( DO_MAGIC ));   then install_magic;           fi
  if (( DO_SKILLS ));  then copy_skills;             fi
  if (( DO_HOOKS ));   then install_hooks;           fi

  if print_summary; then
    printf '\n'
    ok "Done."
  else
    printf '\n'
    err "Finished with errors — see the summary above."
    exit 1
  fi
}

main "$@"
