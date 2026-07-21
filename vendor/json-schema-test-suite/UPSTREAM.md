# JSON Schema Test Suite Provenance

- Classification: Informative upstream provenance record
- Scope: ORKS-0202 validator qualification only

## Exact Source

The vendored files in this directory come from the official
[JSON Schema Test Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite)
at exact commit
`c0b038ad7244712cf73650f44e90d0bc5704e8c7` and Git tree
`526897f0ccac9a492082404efe52a18048feca5b`.

The upstream commit is dated `2026-07-14T02:49:22+05:30`. ORKS selected and
materialized the subset from a clean detached checkout on `2026-07-21`. The
upstream MIT license is preserved in [LICENSE](LICENSE); that file has SHA-256
`837402bd25fad9b704265801ca3f92566a98157c1f9a7acd6f446299ba1c305a`
and upstream Git blob `c28adbadd9114a30a302fef37c3d14f490645c1c`.
Upstream `test-schema.json` has SHA-256
`4727b2d096462b7fdfdde3e31d88fee8f7d69f98231e653947c1a24859f15a07`
and Git blob `0087c5e3da6330ecfcadf45003c08121e1791a1a`.

[MANIFEST.sha256](MANIFEST.sha256) records every selected upstream path and
its exact SHA-256. The repository validator independently pins the provenance
record and manifest, then verifies every manifest path and byte sequence.

## Selected Mandatory Subset

The subset contains exactly 67 upstream files and 384,217 upstream bytes:

- all 46 JSON files directly in `tests/draft2020-12/`, comprising 383 test
  groups and 1,299 assertions;
- the exact 19-file recursive remote-resource closure needed by those tests;
- upstream `LICENSE`; and
- upstream `test-schema.json`.

The selection excludes `tests/draft2020-12/optional/`, proposal tests,
`latest`, every other draft and version directory, nested Git metadata,
submodules, generated or cache content, symlinks, executable files, and all
other upstream content. Selected upstream paths are retained unchanged below
this vendor directory.

## Remote Closure

Closure calculation traverses schema-bearing values and resolves `$schema`,
`$ref`, `$dynamicRef`, and `$recursiveRef` against active `$id` bases.
Embedded resource identifiers are retained as resources within their
containing document rather than treated as new files. Only exact URIs under
`http://localhost:1234/<path>` map to `remotes/<path>`; traversal continues to
a fixed point. Official `json-schema.org` Draft 2020-12 metaschema and
vocabulary resources remain provided by the qualified validation engine and
are not vendored as localhost remotes.

Unresolved localhost references, references outside the selected remote root,
path traversal, absolute paths, backslashes, case or percent-decoding aliases,
and normalization-based substitutions fail closed.

## Byte Preservation

All 67 selected upstream files are preserved byte for byte. ORKS does not
normalize JSON, Unicode, line endings, or terminal newlines. This is material:
seven mandatory tests contain non-ASCII data, and two selected remote files do
not end in a newline. The narrow repository-validator exception for those
bytes applies only to files authenticated by the independently pinned
manifest.

The subset is inert, offline qualification data. ORKS does not execute
upstream content, invoke upstream package tooling, start a local HTTP server,
or fetch a missing resource. Qualification code must preload the selected
remotes under their exact localhost retrieval identifiers and fail closed on
an unknown identifier.
