#!/usr/bin/env bash
# =============================================================================
#  slop-secrets-guard.sh — Claude Code hook from claude-web-skills-toolkit
#
#  secrets  (PreToolUse,  Write|Edit|MultiEdit)
#      Blocks the edit when the new text looks like it contains a secret
#      (API keys, tokens, private keys, credentials in connection strings).
#      Local .env files are skipped; .env.example / .env.sample are checked.
#
#  slop     (PostToolUse, Write|Edit|MultiEdit)
#      Reports typical AI writing tells (English, Czech, German) in the new text of
#      prose and UI files back to Claude, so it can rewrite them with the
#      deslop-en / deslop-cs / deslop-de skills. The edit itself is not undone.
#
#  Exit codes follow the Claude Code hook contract:
#      0  nothing found
#      2  finding — stderr is shown to Claude (PreToolUse: the edit is blocked)
#
#  False positives: put "guard:allow" on the same line. A file containing
#  "slop-guard: off" is skipped by the slop check. SKILL.md files are skipped
#  by the slop check because skills quote anti-patterns on purpose.
#
#  Secret values are never printed — only the type and a masked preview.
#  Requires only bash 3.2+, grep and awk (works in Git Bash on Windows).
#
#  License: MIT — see LICENSE in claude-web-skills-toolkit.
# =============================================================================

set -uo pipefail
export LC_ALL=C

readonly MODE="${1:-}"
readonly MAX_REPORTED=10

if [[ "${MODE}" != "secrets" && "${MODE}" != "slop" ]]; then
  echo "usage: slop-secrets-guard.sh secrets|slop  (reads the hook JSON from stdin)" >&2
  exit 1
fi

# --- Parse the hook payload with a single awk process (no jq needed) ----------
# Output: line 1 = tool_name, line 2 = file_path, rest = the new text
# (the first "content" value plus every distinct "new_string" value).
EXTRACTED="$(awk '
  function unescape(v) {
    gsub(/\\\\/, "\001", v); gsub(/\\n/, "\n", v); gsub(/\\r/, "", v); gsub(/\\t/, "\t", v)
    gsub(/\\"/, "\"", v); gsub(/\\\//, "/", v); gsub(/\001/, "\\", v)
    return v
  }
  function extract(key, first_only,    s, re, out, v, n, seen) {
    s = buf; out = ""; n = 0
    re = "\"" key "\"[ \t\r\n]*:[ \t\r\n]*\""
    while (match(s, re)) {
      s = substr(s, RSTART + RLENGTH - 1)
      if (!match(s, /^"([^"\\]|\\.)*"/)) break
      v = substr(s, 2, RLENGTH - 2)
      s = substr(s, RLENGTH + 1)
      if (!(v in seen)) { seen[v] = 1; out = out (n++ ? "\n" : "") unescape(v) }
      if (first_only) break
    }
    return out
  }
  BEGIN { RS = "\001" }
  { buf = buf $0 }
  END {
    text = extract("content", 1)
    edits = extract("new_string", 0)
    if (text != "" && edits != "") text = text "\n"
    printf "%s\n%s\n%s", extract("tool_name", 1), extract("file_path", 1), text edits
  }
')"

TOOL_NAME="${EXTRACTED%%$'\n'*}"
REST="${EXTRACTED#*$'\n'}"
FILE_PATH="${REST%%$'\n'*}"
NEW_TEXT="${REST#*$'\n'}"
[[ "${REST}" == *$'\n'* ]] || NEW_TEXT=""

[[ -n "${FILE_PATH}" && -n "${NEW_TEXT}" ]] || exit 0

BASENAME="${FILE_PATH##*/}"
BASENAME="${BASENAME##*\\}"

# =============================================================================
#  secrets
# =============================================================================

check_secrets() {
  # Local env files are meant to hold secrets (and are gitignored); templates are not.
  if [[ "${BASENAME}" =~ ^\.env(\..+)?$ && ! "${BASENAME}" =~ ^\.env\.(example|sample|template|dist)$ ]]; then
    exit 0
  fi

  # name | grep flags | ERE
  local patterns=(
    "private key|-E|-----BEGIN ([A-Z0-9]+ )?PRIVATE KEY-----"
    "AWS access key ID|-E|(^|[^A-Za-z0-9])(AKIA|ASIA)[0-9A-Z]{16}([^A-Za-z0-9]|$)"
    "GitHub token|-E|gh[pousr]_[A-Za-z0-9]{36,}"
    "GitHub fine-grained token|-E|github_pat_[A-Za-z0-9_]{50,}"
    "GitLab token|-E|glpat-[A-Za-z0-9_-]{20,}"
    "Slack token|-E|xox[abposr]-[A-Za-z0-9-]{10,}"
    "Stripe live secret key|-E|(sk|rk)_live_[A-Za-z0-9]{20,}"
    "Stripe webhook secret|-E|whsec_[A-Za-z0-9]{24,}"
    "Google API key|-E|AIza[0-9A-Za-z_-]{35}"
    "OpenAI / Anthropic style API key|-E|sk-(ant-|proj-)?[A-Za-z0-9_-]{32,}"
    "SendGrid API key|-E|SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}"
    "npm token|-E|npm_[A-Za-z0-9]{36}"
    "Discord bot token|-E|[MNO][A-Za-z0-9_-]{23,27}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27,}"
    "JSON Web Token|-E|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"
    "password in a connection string|-iE|[a-z][a-z0-9+.-]*://[^/:@[:space:]\"']+:[^@/[:space:]\"']{6,}@"
    "hard-coded credential|-iE|(api[_-]?key|secret|token|passw(or)?d|client[_-]?secret|private[_-]?key)[\"']?[[:space:]]*[:=][[:space:]]*[\"'][A-Za-z0-9_+/=.-]{20,}[\"']"
  )
  # Obvious placeholders in docs and examples are not secrets.
  local placeholder='(x{4,}|X{4,}|\*{4,}|0{8,}|1234567890|example|your|placeholder|dummy|fake|redacted|changeme|<[^>]*>|\$\{[^}]*\}|:(password|pass|secret|postgres|root|user)@)'

  local lines
  lines="$(printf '%s\n' "${NEW_TEXT}" | grep -v 'guard:allow')"

  # Fast path: one case-insensitive grep over all patterns (a superset of the detailed checks).
  local combined="" entry
  for entry in "${patterns[@]}"; do
    combined="${combined:+${combined}|}(${entry#*|*|})"
  done
  printf '%s\n' "${lines}" | grep -qiE -- "${combined}" || exit 0

  # Slow path: collect candidate matches once, drop placeholders, then classify each
  # candidate in-process with [[ =~ ]] (spawning a process per pattern is slow on Windows).
  local candidates
  candidates="$(printf '%s\n' "${lines}" | grep -oiE -- "${combined}" | grep -viE -- "${placeholder}" | head -n "${MAX_REPORTED}")"

  local name flags regex match preview matched
  local findings=()
  while IFS= read -r match; do
    [[ -n "${match}" ]] || continue
    matched=""
    for entry in "${patterns[@]}"; do
      name="${entry%%|*}"
      flags="${entry#*|}"; flags="${flags%%|*}"
      regex="${entry#*|*|}"
      [[ "${flags}" == *i* ]] && shopt -s nocasematch
      if [[ "${match}" =~ ${regex} ]]; then matched="${name}"; fi
      shopt -u nocasematch
      [[ -n "${matched}" ]] && break
    done
    [[ -n "${matched}" ]] || continue
    preview="${match#"${match%%[A-Za-z0-9-]*}"}"
    findings+=("${matched}: ${preview:0:4}…(${#match} chars)")
  done <<<"${candidates}"

  (( ${#findings[@]} > 0 )) || exit 0
  {
    echo "secrets-guard: blocked writing to ${FILE_PATH} — the new text looks like it contains a secret:"
    printf '  - %s\n' "${findings[@]}" | head -n "${MAX_REPORTED}"
    echo "Move the value to an environment variable (a gitignored .env.local or the host's secret store)"
    echo "and read it from process.env. Never commit secrets. If this is a false positive (test fixture,"
    echo "documentation placeholder), add 'guard:allow' to that line or use an obvious placeholder."
  } >&2
  exit 2
}

# =============================================================================
#  slop
# =============================================================================

check_slop() {
  local prose=0
  shopt -s nocasematch
  case "${BASENAME}" in
    SKILL.md) exit 0 ;;
    *.md|*.mdx|*.markdown|*.txt|*.html|*.htm|*.rst|*.adoc) prose=1 ;;
    *.tsx|*.jsx|*.ts|*.js|*.vue|*.svelte|*.astro|*.json|*.yml|*.yaml|*.po|*.properties) prose=0 ;;
    *) exit 0 ;;
  esac
  shopt -u nocasematch

  # Patterns are lowercase; matching lowercases the text (ASCII only, so Czech bytes are untouched).
  # Multi-word phrases are precise enough for code files with UI strings.
  local phrases_en="in today'?s (fast-paced|digital|ever-changing)|ever-evolving|it'?s (worth noting|important to note)|let'?s (dive|delve)|dive (deep )?into|delve|game[- ]changer|cutting-edge|unlock (the|your) (full )?potential|take (it|your [a-z]+) to the next level|elevate your|supercharge your|revolutioni[sz]e (the way|your|how)|look no further|whether you'?re an? |in conclusion|i hope this helps|happy coding|a testament to|rich tapestry|in the realm of|harness the power|seamless experience|navigate the complexities"
  local phrases_cs="v dnešní (rychle se měnící|digitální|moderní)|pojďme se (ponořit|podívat)|ponořme se|na další úroveň|stojí za zmínku|je důležité (zmínit|poznamenat)|závěrem lze|neváhejte nás|doufám, že (vám )?to pomohlo|odemkněte|odemkni |pozvedněte|bezproblémov|bezešv|širokou škálu|v neposlední řadě|adresovat (problém|otázk)"
  # Single words only in prose files — code has identifiers like "unlock" or "robust".
  local words_en="leverag(e|es|ed|ing)|utiliz(e|es|ed|ing)|seamless(ly)?|robust|synerg(y|ies)|holistic|transformative|empower(s|ing)?|streamlin(e|es|ed|ing)|myriad|plethora|tapestry|pivotal|meticulous(ly)?|unleash"
  local words_cs="revoluční|inovativní|nepostradateln|realizova|za účelem|dochází k"
  local phrases_de="in der heutigen (schnelllebigen|digitalen)|tauchen wir ein|lassen sie uns eintauchen|auf das nächste level|zögern sie nicht|zusammenfassend lässt sich|es ist wichtig zu beachten|von entscheidender bedeutung|integraler bestandteil|macht sinn|sinn machen|am ende des tages|einen unterschied machen|erschließen sie das volle potenzial"
  local words_de="bahnbrechend|revolutionär|nahtlos|ganzheitlich|maßgeschneidert|synergien"

  local pattern="${phrases_en}|${phrases_cs}|${phrases_de}"
  if (( prose )); then
    pattern="${pattern}|(^|[^a-z])(${words_en})([^a-z]|$)|${words_cs}|${words_de}"
  fi

  printf '%s\n' "${NEW_TEXT}" | grep -iqE -- "${pattern}" || exit 0
  if [[ -f "${FILE_PATH}" ]] && grep -q 'slop-guard: off' "${FILE_PATH}" 2>/dev/null; then
    exit 0
  fi

  local report
  report="$(printf '%s\n' "${NEW_TEXT}" | awk -v pat="${pattern}" -v max="${MAX_REPORTED}" -v tool="${TOOL_NAME}" '
    index($0, "guard:allow") { next }
    {
      line = tolower($0)
      if (!match(line, pat)) next
      term = substr($0, RSTART, RLENGTH)
      gsub(/^[ \t"(<>.,;:!?-]+|[ \t")<>.,;:!?-]+$/, "", term)
      text = $0; sub(/^[ \t]+/, "", text)
      if (length(text) > 110) text = substr(text, 1, 110) "…"
      where = (tool == "Write") ? "line " NR : "edited text, line " NR
      printf "  - %s: \"%s\" — %s\n", where, term, text
      if (++count >= max) exit
    }
  ')"
  [[ -n "${report}" ]] || exit 0

  {
    echo "slop-guard: possible AI writing tells in ${FILE_PATH}:"
    printf '%s\n' "${report}"
    echo "Rewrite these with the deslop-en / deslop-cs / deslop-de skill (keep facts, links and code unchanged)."
    echo "If a use is legitimate (a technical term, a quote), keep it and add 'guard:allow' to the line."
  } >&2
  exit 2
}

if [[ "${MODE}" == "secrets" ]]; then
  check_secrets
else
  check_slop
fi
