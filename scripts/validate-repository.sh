#!/usr/bin/env -S -i PATH=/usr/bin:/bin bash
# Validate the bounded ORKS conformance repository scaffold without network access.
set -euo pipefail

if [ -n "${BASH_ENV:-}" ] || [ -n "${ENV:-}" ]; then
  printf 'FAIL: shell startup injection variables are not allowed.\n' >&2
  exit 1
fi

unset BASH_ENV ENV CDPATH
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR
while IFS='=' read -r variable _; do
  case "$variable" in
    GIT_CONFIG|GIT_CONFIG_*|GIT_ATTR_NOSYSTEM|GIT_CEILING_DIRECTORIES|GIT_DISCOVERY_ACROSS_FILESYSTEM)
      unset "$variable"
      ;;
  esac
done < <(env)
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
FAILURES=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

relative_path() {
  printf '%s\n' "${1#"$REPO_ROOT/"}"
}

EXPECTED_PATHS=(
  AGENTS.md
  LICENSE
  NOTICE
  README.md
  SUPPORTED-STANDARD.md
  docs/README.md
  docs/fixture-policy.md
  fixtures/README.md
  manifests/README.md
  results/README.md
  schemas/README.md
  scripts/README.md
  scripts/validate-repository.sh
)

EXPECTED_DIRECTORIES=(
  .agents
  .codex
  docs
  fixtures
  manifests
  results
  schemas
  scripts
)

PUBLIC_MARKDOWN=(
  "$REPO_ROOT/README.md"
  "$REPO_ROOT/SUPPORTED-STANDARD.md"
  "$REPO_ROOT/docs/README.md"
  "$REPO_ROOT/docs/fixture-policy.md"
  "$REPO_ROOT/fixtures/README.md"
  "$REPO_ROOT/manifests/README.md"
  "$REPO_ROOT/results/README.md"
  "$REPO_ROOT/schemas/README.md"
  "$REPO_ROOT/scripts/README.md"
)

is_expected_path() {
  local candidate="$1"
  local expected
  for expected in "${EXPECTED_PATHS[@]}"; do
    [ "$candidate" != "$expected" ] || return 0
  done
  return 1
}

is_expected_directory() {
  local candidate="$1"
  local expected
  for expected in "${EXPECTED_DIRECTORIES[@]}"; do
    [ "$candidate" != "$expected" ] || return 0
  done
  return 1
}

printf '1. Required and bounded paths\n'
for path in "${EXPECTED_PATHS[@]}"; do
  [ -f "$REPO_ROOT/$path" ] && [ ! -L "$REPO_ROOT/$path" ] || \
    fail "missing required regular file: $path"
done

while IFS= read -r -d '' path; do
  relative="$(relative_path "$path")"
  is_expected_path "$relative" || \
    fail 'unexpected file violates the repository content boundary'
done < <(
  find "$REPO_ROOT" \
    -path "$REPO_ROOT/.git" -prune -o \
    -type f -print0 | sort -z
)

while IFS= read -r -d '' directory; do
  [ "$directory" != "$REPO_ROOT" ] || continue
  relative="$(relative_path "$directory")"
  is_expected_directory "$relative" || \
    fail 'unexpected directory violates the repository content boundary'
done < <(
  find "$REPO_ROOT" \
    -path "$REPO_ROOT/.git" -prune -o \
    -type d -print0 | sort -z
)

symlink="$(
  find "$REPO_ROOT" \
    -path "$REPO_ROOT/.git" -prune -o \
    -type l -print -quit
)"
[ -z "$symlink" ] || \
  fail 'repository symlink is not allowed'

special="$(
  find "$REPO_ROOT" \
    -path "$REPO_ROOT/.git" -prune -o \
    ! -type d ! -type f ! -type l -print -quit
)"
[ -z "$special" ] || \
  fail 'special repository file is not allowed'

nested_git="$(
  find "$REPO_ROOT" \
    -path "$REPO_ROOT/.git" -prune -o \
    -name .git -print -quit
)"
[ -z "$nested_git" ] || \
  fail 'nested Git metadata is not allowed'
[ ! -e "$REPO_ROOT/.gitmodules" ] || fail '.gitmodules is not allowed'

if ! command -v git >/dev/null 2>&1; then
  fail 'git is required to verify the exact scaffold index'
elif ! actual_root="$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null)"; then
  fail 'repository Git metadata is unavailable'
elif [ "$actual_root" != "$REPO_ROOT" ]; then
  fail 'validator resolved outside the Git repository root'
else
  mapfile -d '' -t tracked_paths < <(git -C "$REPO_ROOT" ls-files -z)
  index_exact=1
  if [ "${#tracked_paths[@]}" -ne "${#EXPECTED_PATHS[@]}" ]; then
    index_exact=0
  else
    for index in "${!EXPECTED_PATHS[@]}"; do
      if [ "${tracked_paths[$index]}" != "${EXPECTED_PATHS[$index]}" ]; then
        index_exact=0
        break
      fi
    done
  fi
  [ "$index_exact" -eq 1 ] || \
    fail 'Git index does not contain exactly the required scaffold paths'

  while IFS= read -r -d '' entry; do
    metadata="${entry%%$'\t'*}"
    path="${entry#*$'\t'}"
    mode="${metadata%% *}"
    expected_mode=100644
    [ "$path" != 'scripts/validate-repository.sh' ] || expected_mode=100755
    [ "$mode" = "$expected_mode" ] || \
      fail 'Git index contains an unexpected file mode'
  done < <(git -C "$REPO_ROOT" ls-files --stage -z)

  for path in "${EXPECTED_PATHS[@]}"; do
    if ! git -C "$REPO_ROOT" show ":$path" | cmp -s - "$REPO_ROOT/$path"; then
      fail 'Git index bytes differ from the validated working tree'
    fi
  done
fi

printf '2. Shell and license integrity\n'
if ! bash -n "$REPO_ROOT/scripts/validate-repository.sh" >/dev/null 2>&1; then
  fail 'invalid Bash syntax: scripts/validate-repository.sh'
  printf 'Repository validation failed with %d finding(s).\n' "$FAILURES" >&2
  exit 1
fi
[ -x "$REPO_ROOT/scripts/validate-repository.sh" ] || \
  fail 'validator is not executable: scripts/validate-repository.sh'

EXPECTED_AGENTS_SHA256='56bb676b72f2899ec100ee423f882024619b9886b6b5c191ca1575e4c497ed1a'
EXPECTED_LICENSE_SHA256='cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30'
EXPECTED_NOTICE_SHA256='847bf37dbaafba412451ace635f27b83a679fcbe899265253de34d4e8b481b50'
if command -v sha256sum >/dev/null 2>&1; then
  actual_agents_sha256="$(sha256sum "$REPO_ROOT/AGENTS.md" | awk '{ print $1 }')"
  [ "$actual_agents_sha256" = "$EXPECTED_AGENTS_SHA256" ] || \
    fail 'AGENTS.md differs from the approved repository seed'
  actual_license_sha256="$(sha256sum "$REPO_ROOT/LICENSE" | awk '{ print $1 }')"
  [ "$actual_license_sha256" = "$EXPECTED_LICENSE_SHA256" ] || \
    fail 'LICENSE is not the pinned canonical Apache License 2.0 text'
  actual_notice_sha256="$(sha256sum "$REPO_ROOT/NOTICE" | awk '{ print $1 }')"
  [ "$actual_notice_sha256" = "$EXPECTED_NOTICE_SHA256" ] || \
    fail 'NOTICE differs from the approved attribution bytes'
else
  fail 'sha256sum is required to verify repository pins'
fi

grep -Fqx 'Open Research and Knowledge Standard' "$REPO_ROOT/NOTICE" || \
  fail 'NOTICE does not contain the approved project name'
grep -Fqx 'Copyright 2026 Adam Claassens' "$REPO_ROOT/NOTICE" || \
  fail 'NOTICE does not contain the approved copyright notice'
if grep -Eiq 'Apache Software Foundation|third[- ]party' "$REPO_ROOT/NOTICE"; then
  fail 'NOTICE contains an unapproved attribution claim'
fi
grep -Fq '[LICENSE](LICENSE)' "$REPO_ROOT/README.md" || \
  fail 'README.md does not link to LICENSE'
grep -Fq '[NOTICE](NOTICE)' "$REPO_ROOT/README.md" || \
  fail 'README.md does not link to NOTICE'

printf '3. ASCII and deterministic text\n'
while IFS= read -r -d '' path; do
  relative="$(relative_path "$path")"
  if ! printf '%s' "$relative" | LC_ALL=C tr -d '\040-\176' | cmp -s - /dev/null; then
    fail 'non-ASCII or control byte in repository path'
  fi
  if ! LC_ALL=C tr -d '\011\012\040-\176' < "$path" | cmp -s - /dev/null; then
    fail 'non-ASCII or disallowed control byte in repository content'
  fi
  [ -s "$path" ] || fail 'required repository file is empty'
  if [ -s "$path" ] && ! tail -c 1 "$path" | cmp -s - <(printf '\n'); then
    fail 'repository file does not end with one newline byte'
  fi
done < <(
  find "$REPO_ROOT" \
    -path "$REPO_ROOT/.git" -prune -o \
    -type f -print0 | sort -z
)

printf '4. Markdown links\n'
while IFS= read -r -d '' markdown; do
  if grep -Eq '^[[:space:]]*\[[^]]+\]:' "$markdown"; then
    fail 'reference-style Markdown links are not supported'
  fi
  if grep -Eiq \
    '(<[[:space:]]*/?[[:space:]]*(a|img)([[:space:]>])|(href|src)[[:space:]]*=)' \
    "$markdown"; then
    fail 'HTML link syntax is not supported'
  fi
  if grep -Eiq '<([A-Za-z][A-Za-z0-9+.-]*:|//)[^>]*>' "$markdown"; then
    fail 'Markdown autolinks are not supported'
  fi

  while IFS= read -r raw_link; do
    target="${raw_link#*(}"
    target="${target%)}"
    target="${target#<}"
    target="${target%>}"

    case "$target" in
      ''|\#*|https://*|mailto:*) continue ;;
      http://*)
        fail 'insecure HTTP Markdown link is not allowed'
        continue
        ;;
      /*|//*|file:*|*://*)
        fail 'unsupported or absolute Markdown link is not allowed'
        continue
        ;;
    esac

    target="${target%%\#*}"
    target="${target%%\?*}"
    [ -n "$target" ] || continue

    resolved="$(realpath -m -- "$(dirname "$markdown")/$target")"
    case "$resolved" in
      "$REPO_ROOT"|"$REPO_ROOT"/*) ;;
      *)
        fail 'Markdown link escapes the repository'
        continue
        ;;
    esac
    [ -e "$resolved" ] || fail 'broken local Markdown link'
  done < <(grep -oE '\[[^][]*\]\([^)]*\)' "$markdown" || true)
done < <(
  find "$REPO_ROOT" \
    -path "$REPO_ROOT/.git" -prune -o \
    -type f -name '*.md' -print0 | sort -z
)

printf '5. Placeholders and public-content boundary\n'
PLACEHOLDER_PATTERN="TO""DO|T""BD|FIX""ME|X""XX|CHANGE""ME"
SENSITIVE_PATTERN='-----BEGIN ([A-Z0-9 ]+ )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{30,}|sk-(proj-)?[A-Za-z0-9_-]{20,}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
CREDENTIAL_PATTERN="(api[_ -]?key|access[_ -]?token|client[_ -]?secret|password)[[:space:]]*[:=][[:space:]]*[\"']?[A-Za-z0-9_./+=-]{8,}"
LINUX_HOME_PATTERN='/ho''me/[^/[:space:]]+'
MACOS_HOME_PATTERN='/Us''ers/[^/[:space:]]+'
WINDOWS_HOME_PATTERN='[A-Za-z]:\\Us''ers\\[^\\[:space:]]+'
HOST_PATH_PATTERN="($LINUX_HOME_PATTERN|$MACOS_HOME_PATTERN|$WINDOWS_HOME_PATTERN)"
PRIVATE_PROJECT_PATTERN="Di""rectus|pc-""standards|Probably""Computers"
PRIVATE_PAYLOAD_PATTERN="PRIVATE""_SOURCE_PAYLOAD|RAW""_PROMPT_PAYLOAD|MODEL""_RESPONSE_PAYLOAD|LOCAL""_TELEMETRY_PAYLOAD"

while IFS= read -r -d '' path; do
  relative="$(relative_path "$path")"
  if LC_ALL=C grep -Eiq "\\b($PLACEHOLDER_PATTERN)\\b" "$path"; then
    fail 'unresolved placeholder marker in repository content'
  fi
  if LC_ALL=C grep -Eiq -- "$SENSITIVE_PATTERN" "$path" || \
    LC_ALL=C grep -Eiq -- "$CREDENTIAL_PATTERN" "$path"; then
    fail 'sensitive-content indicator in repository content'
  fi
  if LC_ALL=C grep -Eiq -- "$HOST_PATH_PATTERN" "$path"; then
    fail 'host-local path indicator in repository content'
  fi
  case "$relative" in
    AGENTS.md) ;;
    *)
      if LC_ALL=C grep -Eiq -- "$PRIVATE_PROJECT_PATTERN|$PRIVATE_PAYLOAD_PATTERN" "$path"; then
        fail 'private-project or private-payload indicator in repository content'
      fi
      ;;
  esac
done < <(
  find "$REPO_ROOT" \
    -path "$REPO_ROOT/.git" -prune -o \
    -type f -print0 | sort -z
)

printf '6. Pinned input and ownership boundaries\n'
PIN='52ffc5c88dc54598f3a48864942dfa505b1287e8'
for record in "$REPO_ROOT/README.md" "$REPO_ROOT/SUPPORTED-STANDARD.md"; do
  count="$(grep -Foc "$PIN" "$record" || true)"
  [ "$count" -ge 1 ] || \
    fail 'exact Standard Kernel source pin is missing from public documentation'
done

mapfile -t observed_versions < <(
  grep -hEo '[0-9]+\.[0-9]+\.[0-9]+' "${PUBLIC_MARKDOWN[@]}" | sort -u
)
[ "${#observed_versions[@]}" -eq 1 ] && [ "${observed_versions[0]}" = '0.1.0' ] || \
  fail 'public documentation identifies an inconsistent specification version'

mapfile -t observed_pins < <(
  grep -hEo '[0-9a-f]{40}' "${PUBLIC_MARKDOWN[@]}" | sort -u
)
[ "${#observed_pins[@]}" -eq 1 ] && [ "${observed_pins[0]}" = "$PIN" ] || \
  fail 'public documentation identifies an inconsistent source commit'

mapfile -t observed_schema_generations < <(
  grep -hEo 'JSON Schema Draft [0-9]{4}-[0-9]{2}' "${PUBLIC_MARKDOWN[@]}" | sort -u
)
[ "${#observed_schema_generations[@]}" -eq 1 ] && \
  [ "${observed_schema_generations[0]}" = 'JSON Schema Draft 2020-12' ] || \
  fail 'public documentation identifies an inconsistent schema generation'
grep -Fq '| Target specification | Unreleased draft `0.1.0` |' \
  "$REPO_ROOT/SUPPORTED-STANDARD.md" || \
  fail 'supported-standard target is not the exact unreleased draft'
grep -Fq '| Schema generation selected for later work | JSON Schema Draft 2020-12 |' \
  "$REPO_ROOT/SUPPORTED-STANDARD.md" || \
  fail 'selected JSON Schema generation is missing or changed'
grep -Fq '| Generation reverified | 2026-07-20 |' \
  "$REPO_ROOT/SUPPORTED-STANDARD.md" || \
  fail 'JSON Schema generation verification date is missing or changed'
grep -Fq 'does not make' "$REPO_ROOT/SUPPORTED-STANDARD.md" || \
  fail 'source-pin dependency boundary is missing'
grep -Fq 'fails closed rather than inferring a replacement' \
  "$REPO_ROOT/SUPPORTED-STANDARD.md" || \
  fail 'source-pin fail-closed policy is missing'

for literal in \
  'bounded public repository' \
  'It does not yet provide' \
  'No JSON Schema, executable fixture' \
  'A passing result is not an ORKS conformance result.'; do
  grep -Fq "$literal" "$REPO_ROOT/README.md" || \
    fail "README.md is missing scaffold boundary: $literal"
done

if grep -Eiq \
  '(^|[[:space:]])(may|can|will|should)[[:space:]]+(fetch|download)' \
  "$REPO_ROOT/docs/fixture-policy.md" "$REPO_ROOT/fixtures/README.md"; then
  fail 'fixture policy contains a contradictory fetch allowance'
fi
if grep -Eiq \
  '^[[:space:]]*executable fixture(s| payloads)?[[:space:]]+(is|are|has|have)[[:space:]]+(implemented|present|available|provided)' \
  "${PUBLIC_MARKDOWN[@]}"; then
  fail 'public documentation claims executable fixture behavior'
fi

for literal in \
  'complete synthetic material or safely' \
  'explicit provenance label' \
  'explicit expected outcome' \
  'non-fetching by default' \
  'must not fetch fixture content' \
  'private corpora, unlicensed or unauthorized' \
  'credentials, raw prompts or model responses' \
  'generated indexes, telemetry, host paths, local bindings' \
  'No executable fixture is present'; do
  grep -Fq "$literal" "$REPO_ROOT/docs/fixture-policy.md" || \
    fail "fixture policy is missing required boundary: $literal"
done

for spec in \
  'schemas/README.md|no schema, compiler, schema-validation behavior' \
  'fixtures/README.md|no executable fixture payload' \
  'manifests/README.md|No manifest format, field set' \
  'results/README.md|No result format, report schema' \
  'scripts/README.md|It is not the ORKS conformance'; do
  record="${spec%%|*}"
  literal="${spec#*|}"
  grep -Fq "$literal" "$REPO_ROOT/$record" || \
    fail "ownership index is missing later-work boundary: $record"
done

NETWORK_COMMAND_PATTERN="(^|[;&|[:space:]])[\"']?([^;&|[:space:]\"']*/)?(cu""rl|wg""et|g""h|s""sh|s""cp|n""c|n""cat|so""cat)[\"']?([;&|[:space:]]|$)|[\"']?([^;&|[:space:]\"']*/)?g""it[\"']?[[:space:]]+([^;&|]*[[:space:]])?(fetch|pull|push|clone)([;&|[:space:]]|$)"
if grep -En -- "$NETWORK_COMMAND_PATTERN" "$REPO_ROOT/scripts/validate-repository.sh" >/dev/null; then
  fail 'repository validator contains a network-capable command'
fi

if [ "$FAILURES" -ne 0 ]; then
  printf 'Repository validation failed with %d finding(s).\n' "$FAILURES" >&2
  exit 1
fi

printf 'Repository scaffold validation passed.\n'
