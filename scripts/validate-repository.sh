#!/usr/bin/env -S -i PATH=/usr/bin:/bin bash
# Validate the bounded ORKS conformance repository without network access.
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
VENDOR_REL='vendor/json-schema-test-suite'
VENDOR_ROOT="$REPO_ROOT/$VENDOR_REL"
MANIFEST="$VENDOR_ROOT/MANIFEST.sha256"
UPSTREAM="$VENDOR_ROOT/UPSTREAM.md"
FAILURES=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

relative_path() {
  printf '%s\n' "${1#"$REPO_ROOT/"}"
}

STATIC_PATHS=(
  AGENTS.md
  LICENSE
  NOTICE
  README.md
  SUPPORTED-STANDARD.md
  docs/README.md
  docs/dependency-policy.md
  docs/fixture-policy.md
  fixtures/README.md
  manifests/README.md
  requirements.in
  requirements.lock
  results/README.md
  schemas/README.md
  scripts/README.md
  scripts/validate-repository.sh
  vendor/json-schema-test-suite/MANIFEST.sha256
  vendor/json-schema-test-suite/UPSTREAM.md
)

SPEC_MARKDOWN=(
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

EXPECTED_MANIFEST_SHA256='ab0c707a9b32f37e99f225f18f4dea5ade8eb929205d0a6bc3b2cdca78117c37'
EXPECTED_UPSTREAM_SHA256='4d87a453c26c71db4c47d805ded588296840ad4741572eca710567225812085b'
EXPECTED_MANIFEST_PATHS_SHA256='bbdb68872285f45b75e16201e8d23e4fb5cdd0f69cf3f6da7084e9b717b90076'
EXPECTED_VENDOR_BYTES=384217

printf '0. Early filesystem safety\n'
EARLY_SAFE=1
for required_directory in \
  "$REPO_ROOT/.git" \
  "$REPO_ROOT/vendor" \
  "$VENDOR_ROOT"; do
  if [ ! -d "$required_directory" ] || [ -L "$required_directory" ]; then
    fail 'required repository directory is missing or symlinked'
    EARLY_SAFE=0
  fi
done
symlink="$(find "$REPO_ROOT" -path "$REPO_ROOT/.git" -prune -o -type l -print -quit)"
if [ -n "$symlink" ]; then
  fail 'repository symlink is not allowed'
  EARLY_SAFE=0
fi
special="$(find "$REPO_ROOT" -path "$REPO_ROOT/.git" -prune -o ! -type d ! -type f ! -type l -print -quit)"
if [ -n "$special" ]; then
  fail 'special repository file is not allowed'
  EARLY_SAFE=0
fi
nested_git="$(find "$REPO_ROOT" -path "$REPO_ROOT/.git" -prune -o -name .git -print -quit)"
if [ -n "$nested_git" ]; then
  fail 'nested Git metadata is not allowed'
  EARLY_SAFE=0
fi
if [ -e "$REPO_ROOT/.gitmodules" ]; then
  fail '.gitmodules is not allowed'
  EARLY_SAFE=0
fi
if [ "$EARLY_SAFE" -ne 1 ]; then
  printf 'Repository validation failed with %d finding(s).\n' "$FAILURES" >&2
  exit 1
fi

printf '1. Pinned upstream manifest\n'
if ! command -v sha256sum >/dev/null 2>&1; then
  fail 'sha256sum is required to verify repository pins'
fi

CONTROL_TRUSTED=1
for control in "$MANIFEST" "$UPSTREAM"; do
  if [ ! -f "$control" ] || [ -L "$control" ]; then
    fail 'missing vendor control file'
    CONTROL_TRUSTED=0
  fi
done

if [ "$CONTROL_TRUSTED" -eq 1 ]; then
  manifest_size="$(stat -c '%s' "$MANIFEST")"
  upstream_size="$(stat -c '%s' "$UPSTREAM")"
  if [ "$manifest_size" -gt 8192 ] || [ "$upstream_size" -gt 4096 ]; then
    fail 'vendor control file exceeds its pre-authentication size bound'
    CONTROL_TRUSTED=0
  fi
fi

if [ "$CONTROL_TRUSTED" -eq 1 ] && command -v sha256sum >/dev/null 2>&1; then
  actual_manifest_sha256="$(sha256sum "$MANIFEST" | awk '{ print $1 }')"
  if [ "$actual_manifest_sha256" != "$EXPECTED_MANIFEST_SHA256" ]; then
    fail 'vendor manifest differs from its approved independent pin'
    CONTROL_TRUSTED=0
  fi
fi
if [ "$CONTROL_TRUSTED" -eq 1 ] && command -v sha256sum >/dev/null 2>&1; then
  actual_upstream_sha256="$(sha256sum "$UPSTREAM" | awk '{ print $1 }')"
  if [ "$actual_upstream_sha256" != "$EXPECTED_UPSTREAM_SHA256" ]; then
    fail 'vendor provenance differs from its approved independent pin'
    CONTROL_TRUSTED=0
  fi
fi
if [ "$CONTROL_TRUSTED" -ne 1 ]; then
  printf 'Repository validation failed with %d finding(s).\n' "$FAILURES" >&2
  exit 1
fi

MANIFEST_PATHS=()
MANIFEST_HASHES=()
declare -A seen_manifest_paths=()
test_count=0
remote_count=0
vendor_bytes=0

if [ "$CONTROL_TRUSTED" -eq 1 ]; then
  mapfile -t manifest_lines < "$MANIFEST"
  [ "${#manifest_lines[@]}" -eq 72 ] || \
    fail 'vendor manifest must contain exactly 5 headers and 67 records'

  expected_headers=(
    '# JSON Schema Test Suite exact ORKS-0202 subset'
    '# Upstream commit: c0b038ad7244712cf73650f44e90d0bc5704e8c7'
    '# Upstream tree: 526897f0ccac9a492082404efe52a18048feca5b'
    '# Upstream license: MIT'
    '# Upstream LICENSE SHA-256: 837402bd25fad9b704265801ca3f92566a98157c1f9a7acd6f446299ba1c305a'
  )
  for header_index in "${!expected_headers[@]}"; do
    [ "${manifest_lines[$header_index]:-}" = "${expected_headers[$header_index]}" ] || \
      fail 'vendor manifest header differs from the approved source identity'
  done

  previous_path=''
  for ((line_index = 5; line_index < ${#manifest_lines[@]}; line_index++)); do
    row="${manifest_lines[$line_index]}"
    if [[ ! "$row" =~ ^([0-9a-f]{64})\ \ ([A-Za-z0-9._/-]+)$ ]]; then
      fail 'vendor manifest record has invalid checksum grammar'
      continue
    fi
    digest="${BASH_REMATCH[1]}"
    manifest_path="${BASH_REMATCH[2]}"

    case "$manifest_path" in
      /*|*//*|*\\*|*%*|*'?'*|*'#'*|.|..|./*|*/./*|*/.|../*|*/../*|*/..|-*)
        fail 'vendor manifest contains a non-canonical path'
        continue
        ;;
    esac
    case "$manifest_path" in
      LICENSE|test-schema.json) ;;
      tests/draft2020-12/*.json)
        if [[ ! "$manifest_path" =~ ^tests/draft2020-12/[A-Za-z0-9._-]+\.json$ ]]; then
          fail 'mandatory test path is not a direct Draft 2020-12 child'
          continue
        fi
        test_count=$((test_count + 1))
        ;;
      remotes/draft2020-12/*.json)
        remote_count=$((remote_count + 1))
        ;;
      *)
        fail 'vendor manifest path is outside the approved subset classes'
        continue
        ;;
    esac

    if [ -n "${seen_manifest_paths[$manifest_path]+present}" ]; then
      fail 'vendor manifest contains a duplicate path'
      continue
    fi
    seen_manifest_paths["$manifest_path"]=1
    if [ -n "$previous_path" ] && [[ ! "$manifest_path" > "$previous_path" ]]; then
      fail 'vendor manifest records are not in ASCII path order'
    fi
    previous_path="$manifest_path"
    MANIFEST_HASHES+=("$digest")
    MANIFEST_PATHS+=("$manifest_path")
  done
fi

[ "${#MANIFEST_PATHS[@]}" -eq 67 ] || \
  fail 'vendor manifest does not authorize exactly 67 upstream files'
[ "$test_count" -eq 46 ] || \
  fail 'vendor manifest does not contain exactly 46 mandatory tests'
[ "$remote_count" -eq 19 ] || \
  fail 'vendor manifest does not contain exactly 19 remote resources'
[ -n "${seen_manifest_paths[LICENSE]+present}" ] || \
  fail 'vendor manifest omits upstream LICENSE'
[ -n "${seen_manifest_paths[test-schema.json]+present}" ] || \
  fail 'vendor manifest omits upstream test-schema.json'

if [ "${#MANIFEST_PATHS[@]}" -gt 0 ] && command -v sha256sum >/dev/null 2>&1; then
  manifest_paths_sha256="$({ printf '%s\n' "${MANIFEST_PATHS[@]}"; } | sha256sum | awk '{ print $1 }')"
  [ "$manifest_paths_sha256" = "$EXPECTED_MANIFEST_PATHS_SHA256" ] || \
    fail 'vendor manifest path inventory differs from the approved subset'
fi

if [ "$FAILURES" -ne 0 ]; then
  printf 'Repository validation failed with %d finding(s).\n' "$FAILURES" >&2
  exit 1
fi

for manifest_index in "${!MANIFEST_PATHS[@]}"; do
  manifest_path="${MANIFEST_PATHS[$manifest_index]}"
  digest="${MANIFEST_HASHES[$manifest_index]}"
  vendored_file="$VENDOR_ROOT/$manifest_path"
  if [ ! -f "$vendored_file" ] || [ -L "$vendored_file" ]; then
    fail 'manifest path is missing or is not a regular file'
    continue
  fi
  resolved_vendor_file="$(realpath -e -- "$vendored_file")"
  if [ "$resolved_vendor_file" != "$vendored_file" ]; then
    fail 'manifest path resolves through an alias or symlinked ancestor'
    continue
  fi
  vendored_size="$(stat -c '%s' "$vendored_file")"
  if [ "$vendored_size" -gt 65536 ]; then
    fail 'manifest path exceeds the approved per-file size bound'
    continue
  fi
  actual_digest="$(sha256sum "$vendored_file" | awk '{ print $1 }')"
  [ "$actual_digest" = "$digest" ] || \
    fail 'vendored upstream bytes differ from the approved manifest'
  vendor_bytes=$((vendor_bytes + vendored_size))
done
[ "$vendor_bytes" -eq "$EXPECTED_VENDOR_BYTES" ] || \
  fail 'vendored upstream byte count differs from the approved subset'

for literal in \
  'c0b038ad7244712cf73650f44e90d0bc5704e8c7' \
  '526897f0ccac9a492082404efe52a18048feca5b' \
  '837402bd25fad9b704265801ca3f92566a98157c1f9a7acd6f446299ba1c305a' \
  'exactly 67 upstream files' \
  'all 46 JSON files' \
  '19-file recursive remote-resource closure' \
  '383 test' \
  '1,299 assertions' \
  'normalize JSON, Unicode, line endings, or terminal newlines' \
  'inert, offline qualification data' \
  'an unknown identifier.'; do
  grep -Fq "$literal" "$UPSTREAM" || \
    fail 'vendor provenance omits an approved source or byte boundary'
done

printf '2. Required and bounded paths\n'
EXPECTED_PATHS=("${STATIC_PATHS[@]}")
for manifest_path in "${MANIFEST_PATHS[@]}"; do
  EXPECTED_PATHS+=("$VENDOR_REL/$manifest_path")
done
mapfile -t EXPECTED_PATHS < <(printf '%s\n' "${EXPECTED_PATHS[@]}" | sort -u)
[ "${#EXPECTED_PATHS[@]}" -eq 85 ] || \
  fail 'approved repository inventory must contain exactly 85 files'

declare -A expected_path_set=()
declare -A expected_directory_set=( [.agents]=1 [.codex]=1 )
for expected in "${EXPECTED_PATHS[@]}"; do
  expected_path_set["$expected"]=1
  parent="$(dirname "$expected")"
  while [ "$parent" != '.' ]; do
    expected_directory_set["$parent"]=1
    parent="$(dirname "$parent")"
  done
done
mapfile -t EXPECTED_DIRECTORIES < <(printf '%s\n' "${!expected_directory_set[@]}" | sort)
[ "${#EXPECTED_DIRECTORIES[@]}" -eq 18 ] || \
  fail 'approved repository inventory must contain exactly 18 directories'

for expected in "${EXPECTED_PATHS[@]}"; do
  [ -f "$REPO_ROOT/$expected" ] && [ ! -L "$REPO_ROOT/$expected" ] || \
    fail 'missing required regular file'
done

while IFS= read -r -d '' file_item; do
  relative="$(relative_path "$file_item")"
  [ -n "${expected_path_set[$relative]+present}" ] || \
    fail 'unexpected file violates the repository content boundary'
done < <(
  find "$REPO_ROOT" \
    -path "$REPO_ROOT/.git" -prune -o \
    -type f -print0 | sort -z
)

while IFS= read -r -d '' directory; do
  [ "$directory" != "$REPO_ROOT" ] || continue
  relative="$(relative_path "$directory")"
  [ -n "${expected_directory_set[$relative]+present}" ] || \
    fail 'unexpected directory violates the repository content boundary'
done < <(
  find "$REPO_ROOT" \
    -path "$REPO_ROOT/.git" -prune -o \
    -type d -print0 | sort -z
)

if ! command -v git >/dev/null 2>&1; then
  fail 'git is required to verify the exact repository index'
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
    fail 'Git index does not contain exactly the approved repository paths'

  while IFS= read -r -d '' entry; do
    metadata="${entry%%$'\t'*}"
    indexed_path="${entry#*$'\t'}"
    mode="${metadata%% *}"
    expected_mode=100644
    [ "$indexed_path" != 'scripts/validate-repository.sh' ] || expected_mode=100755
    [ "$mode" = "$expected_mode" ] || \
      fail 'Git index contains an unexpected file mode'
  done < <(git -C "$REPO_ROOT" ls-files --stage -z)

  for expected in "${EXPECTED_PATHS[@]}"; do
    if ! git -C "$REPO_ROOT" show ":$expected" | cmp -s - "$REPO_ROOT/$expected"; then
      fail 'Git index bytes differ from the validated working tree'
    fi
  done
fi

printf '3. Shell, license, and dependency integrity\n'
if ! bash -n "$REPO_ROOT/scripts/validate-repository.sh" >/dev/null 2>&1; then
  fail 'invalid Bash syntax: scripts/validate-repository.sh'
  printf 'Repository validation failed with %d finding(s).\n' "$FAILURES" >&2
  exit 1
fi
[ -x "$REPO_ROOT/scripts/validate-repository.sh" ] || \
  fail 'validator is not executable: scripts/validate-repository.sh'

EXPECTED_AGENTS_SHA256='56bb676b72f2899ec100ee423f882024619b9886b6b5c191ca1575e4c497ed1a'
EXPECTED_LICENSE_SHA256='cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30'
EXPECTED_NOTICE_SHA256='684b55a0c87ed777a05dfc1cf090e8b8ae03225864399c898f3e177716f98716'
EXPECTED_LOCK_SHA256='299234d5a5ee23e9e46a8f34205fcfc0b884c3610f1b61e474c55f8a493bed22'
EXPECTED_DEPENDENCY_POLICY_SHA256='1e4354fd0064f56ab2b651064b18ccfb42c5d9bb46ad80e9c9c32ec8545a267a'
for pin_spec in \
  "AGENTS.md:$EXPECTED_AGENTS_SHA256" \
  "LICENSE:$EXPECTED_LICENSE_SHA256" \
  "NOTICE:$EXPECTED_NOTICE_SHA256" \
  "docs/dependency-policy.md:$EXPECTED_DEPENDENCY_POLICY_SHA256" \
  "requirements.lock:$EXPECTED_LOCK_SHA256"; do
  pinned_path="${pin_spec%%:*}"
  expected_sha256="${pin_spec#*:}"
  actual_sha256="$(sha256sum "$REPO_ROOT/$pinned_path" | awk '{ print $1 }')"
  [ "$actual_sha256" = "$expected_sha256" ] || \
    fail 'repository control file differs from its approved hash'
done

[ "$(<"$REPO_ROOT/requirements.in")" = 'jsonschema==4.26.0' ] || \
  fail 'direct validation requirement differs from the approved exact pin'
grep -Fq "$EXPECTED_LOCK_SHA256" "$REPO_ROOT/docs/dependency-policy.md" || \
  fail 'dependency policy omits the approved lock digest'
grep -Fqx 'Open Research and Knowledge Standard' "$REPO_ROOT/NOTICE" || \
  fail 'NOTICE does not contain the approved project name'
grep -Fqx 'Copyright 2026 Adam Claassens' "$REPO_ROOT/NOTICE" || \
  fail 'NOTICE does not contain the approved project copyright'
grep -Fq 'JSON Schema Test Suite' "$REPO_ROOT/NOTICE" || \
  fail 'NOTICE omits the vendored suite attribution'
grep -Fq 'Copyright (c) 2012 Julian Berman' "$REPO_ROOT/NOTICE" || \
  fail 'NOTICE omits the upstream copyright attribution'
grep -Fq 'vendor/json-schema-test-suite/LICENSE' "$REPO_ROOT/NOTICE" || \
  fail 'NOTICE omits the vendored MIT license location'
grep -Fq '[LICENSE](LICENSE)' "$REPO_ROOT/README.md" || \
  fail 'README.md does not link to LICENSE'
grep -Fq '[NOTICE](NOTICE)' "$REPO_ROOT/README.md" || \
  fail 'README.md does not link to NOTICE'

printf '4. ASCII and deterministic text\n'
for expected in "${EXPECTED_PATHS[@]}"; do
  file_item="$REPO_ROOT/$expected"
  if ! printf '%s' "$expected" | LC_ALL=C tr -d '\040-\176' | cmp -s - /dev/null; then
    fail 'non-ASCII or control byte in repository path'
  fi
  [ -s "$file_item" ] || fail 'required repository file is empty'

  case "$expected" in
    vendor/json-schema-test-suite/tests/*.json|vendor/json-schema-test-suite/remotes/*.json)
      if ! LC_ALL=C tr -d '\000' < "$file_item" | cmp -s - "$file_item"; then
        fail 'NUL byte in manifest-pinned upstream JSON'
      fi
      if command -v iconv >/dev/null 2>&1 && \
        ! iconv -f UTF-8 -t UTF-8 "$file_item" >/dev/null 2>&1; then
        fail 'invalid UTF-8 in manifest-pinned upstream JSON'
      fi
      ;;
    *)
      if ! LC_ALL=C tr -d '\011\012\040-\176' < "$file_item" | cmp -s - /dev/null; then
        fail 'non-ASCII or disallowed control byte in repository-authored content'
      fi
      if ! tail -c 1 "$file_item" | cmp -s - <(printf '\n'); then
        fail 'repository-authored file does not end with a newline byte'
      fi
      ;;
  esac
done

printf '5. Markdown links\n'
while IFS= read -r -d '' markdown; do
  if grep -Eq '^[[:space:]]*\[[^]]+\]:' "$markdown"; then
    fail 'reference-style Markdown links are not supported'
  fi
  if grep -Eiq '(<[[:space:]]*/?[[:space:]]*(a|img)([[:space:]>])|(href|src)[[:space:]]*=)' "$markdown"; then
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
      http://*) fail 'insecure HTTP Markdown link is not allowed'; continue ;;
      /*|//*|file:*|*://*) fail 'unsupported or absolute Markdown link is not allowed'; continue ;;
    esac
    target="${target%%\#*}"
    target="${target%%\?*}"
    [ -n "$target" ] || continue
    resolved="$(realpath -m -- "$(dirname "$markdown")/$target")"
    case "$resolved" in
      "$REPO_ROOT"|"$REPO_ROOT"/*) ;;
      *) fail 'Markdown link escapes the repository'; continue ;;
    esac
    [ -e "$resolved" ] || fail 'broken local Markdown link'
  done < <(grep -oE '\[[^][]*\]\([^)]*\)' "$markdown" || true)
done < <(find "$REPO_ROOT" -path "$REPO_ROOT/.git" -prune -o -type f -name '*.md' -print0 | sort -z)

printf '6. Placeholders and public-content boundary\n'
PLACEHOLDER_PATTERN="TO""DO|T""BD|FIX""ME|X""XX|CHANGE""ME"
SENSITIVE_PATTERN='-----BEGIN ([A-Z0-9 ]+ )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{30,}|sk-(proj-)?[A-Za-z0-9_-]{20,}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
CREDENTIAL_PATTERN="(api[_ -]?key|access[_ -]?token|client[_ -]?secret|password)[[:space:]]*[:=][[:space:]]*[\"']?[A-Za-z0-9_./+=-]{8,}"
LINUX_HOME_PATTERN='/ho''me/[^/[:space:]]+'
MACOS_HOME_PATTERN='/Us''ers/[^/[:space:]]+'
WINDOWS_HOME_PATTERN='[A-Za-z]:\\Us''ers\\[^\\[:space:]]+'
HOST_PATH_PATTERN="($LINUX_HOME_PATTERN|$MACOS_HOME_PATTERN|$WINDOWS_HOME_PATTERN)"
PRIVATE_PROJECT_PATTERN="Di""rectus|pc-""standards|Probably""Computers"
PRIVATE_PAYLOAD_PATTERN="PRIVATE""_SOURCE_PAYLOAD|RAW""_PROMPT_PAYLOAD|MODEL""_RESPONSE_PAYLOAD|LOCAL""_TELEMETRY_PAYLOAD"

for expected in "${EXPECTED_PATHS[@]}"; do
  file_item="$REPO_ROOT/$expected"
  if LC_ALL=C grep -Eiq "\\b($PLACEHOLDER_PATTERN)\\b" "$file_item"; then
    fail 'unresolved placeholder marker in repository content'
  fi
  if LC_ALL=C grep -Eiq -- "$SENSITIVE_PATTERN" "$file_item" || \
    LC_ALL=C grep -Eiq -- "$CREDENTIAL_PATTERN" "$file_item"; then
    fail 'sensitive-content indicator in repository content'
  fi
  if LC_ALL=C grep -Eiq -- "$HOST_PATH_PATTERN" "$file_item"; then
    fail 'host-local path indicator in repository content'
  fi
  case "$expected" in
    AGENTS.md) ;;
    *)
      if LC_ALL=C grep -Eiq -- "$PRIVATE_PROJECT_PATTERN|$PRIVATE_PAYLOAD_PATTERN" "$file_item"; then
        fail 'private-project or private-payload indicator in repository content'
      fi
      ;;
  esac
done

printf '7. Pinned input and ownership boundaries\n'
PIN='52ffc5c88dc54598f3a48864942dfa505b1287e8'
for record in "$REPO_ROOT/README.md" "$REPO_ROOT/SUPPORTED-STANDARD.md"; do
  count="$(grep -Foc "$PIN" "$record" || true)"
  [ "$count" -ge 1 ] || \
    fail 'exact Standard Kernel source pin is missing from public documentation'
done

mapfile -t observed_versions < <(grep -hEo '[0-9]+\.[0-9]+\.[0-9]+' "${SPEC_MARKDOWN[@]}" | sort -u)
[ "${#observed_versions[@]}" -eq 1 ] && [ "${observed_versions[0]}" = '0.1.0' ] || \
  fail 'specification documentation identifies an inconsistent version'
mapfile -t observed_pins < <(grep -hEo '[0-9a-f]{40}' "${SPEC_MARKDOWN[@]}" | sort -u)
[ "${#observed_pins[@]}" -eq 1 ] && [ "${observed_pins[0]}" = "$PIN" ] || \
  fail 'specification documentation identifies an inconsistent source commit'
mapfile -t observed_schema_generations < <(grep -hEo 'JSON Schema Draft [0-9]{4}-[0-9]{2}' "${SPEC_MARKDOWN[@]}" | sort -u)
[ "${#observed_schema_generations[@]}" -eq 1 ] && \
  [ "${observed_schema_generations[0]}" = 'JSON Schema Draft 2020-12' ] || \
  fail 'specification documentation identifies an inconsistent schema generation'

grep -Fq '| Target specification | Unreleased draft `0.1.0` |' "$REPO_ROOT/SUPPORTED-STANDARD.md" || \
  fail 'supported-standard target is not the exact unreleased draft'
grep -Fq '| Schema generation selected | JSON Schema Draft 2020-12 |' "$REPO_ROOT/SUPPORTED-STANDARD.md" || \
  fail 'selected JSON Schema generation is missing or changed'
grep -Fq '| Generation reverified | 2026-07-20 |' "$REPO_ROOT/SUPPORTED-STANDARD.md" || \
  fail 'JSON Schema generation verification date is missing or changed'
grep -Fq 'fails closed rather than inferring a replacement' "$REPO_ROOT/SUPPORTED-STANDARD.md" || \
  fail 'source-pin fail-closed policy is missing'

for literal in \
  'ORKS-0202 schema' \
  'task-local, hash-locked JSON Schema' \
  'does not yet include an ORKS JSON Schema' \
  'passing result is not an ORKS conformance result.'; do
  grep -Fq "$literal" "$REPO_ROOT/README.md" || \
    fail 'README.md is missing the current implementation boundary'
done

if grep -Eiq '(^|[[:space:]])(may|can|will|should)[[:space:]]+(fetch|download)' \
  "$REPO_ROOT/docs/fixture-policy.md" "$REPO_ROOT/fixtures/README.md"; then
  fail 'fixture policy contains a contradictory fetch allowance'
fi
if grep -Eiq '^[[:space:]]*executable fixture(s| payloads)?[[:space:]]+(is|are|has|have)[[:space:]]+(implemented|present|available|provided)' \
  "${SPEC_MARKDOWN[@]}"; then
  fail 'public documentation claims executable ORKS fixture behavior'
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
    fail 'fixture policy is missing a required boundary'
done

for spec in \
  'schemas/README.md|no schema, compiler output' \
  'fixtures/README.md|no executable fixture payload' \
  'manifests/README.md|No manifest format, field set' \
  'results/README.md|No result format, report schema' \
  'scripts/README.md|It is not the ORKS conformance'; do
  record="${spec%%|*}"
  literal="${spec#*|}"
  grep -Fq "$literal" "$REPO_ROOT/$record" || \
    fail 'ownership index is missing a later-work boundary'
done

NETWORK_COMMAND_PATTERN="(^|[;&|[:space:]])[\"']?([^;&|[:space:]\"']*/)?(cu""rl|wg""et|g""h|s""sh|s""cp|n""c|n""cat|so""cat)[\"']?([;&|[:space:]]|$)|[\"']?([^;&|[:space:]\"']*/)?g""it[\"']?[[:space:]]+([^;&|]*[[:space:]])?(fetch|pull|push|clone)([;&|[:space:]]|$)"
if grep -En -- "$NETWORK_COMMAND_PATTERN" "$REPO_ROOT/scripts/validate-repository.sh" >/dev/null; then
  fail 'repository validator contains a network-capable command'
fi

if [ "$FAILURES" -ne 0 ]; then
  printf 'Repository validation failed with %d finding(s).\n' "$FAILURES" >&2
  exit 1
fi

printf 'Repository validation passed.\n'
