# ORKS Conformance

## Repository Status

This repository contains the bounded public foundation for executable Open
Research and Knowledge Standard (ORKS) conformance work. ORKS-0202 schema
compilation and validation work is in progress.

It targets the accepted, unreleased ORKS `0.1.0` draft at the exact
`orks-standard` source commit
`52ffc5c88dc54598f3a48864942dfa505b1287e8`. It does not yet provide
executable conformance behavior or claim conformance to a released ORKS
specification.

The repository now includes a task-local, hash-locked JSON Schema validation
dependency closure and an exact mandatory Draft 2020-12 JSON Schema Test Suite
qualification subset. It does not yet include an ORKS JSON Schema, executable
ORKS fixture, canonical-byte vector, conformance manifest, result or report
format, public conformance command-line interface, continuous-integration
workflow, package, or release artifact.

## Repository Scope

This repository reserves ownership of JSON Schemas, executable positive and
negative fixtures, boundary and hostile fixtures, canonical-byte vectors,
compatibility fixtures, conformance manifests and results, and executable
conformance tooling. Each requires separately approved later work.

Normative behavior remains owned by the exact pinned `orks-standard` source
tree. A schema, fixture, validator, or report in this repository cannot create,
weaken, reinterpret, or silently repair behavior absent from that contract.

Production storage and query logic, implementation-specific tests, user
profiles, private knowledge, provider behavior, models, prompts, generated
indexes, telemetry, and installation-local state are outside this repository.

## Documentation

- [Pinned standard input](SUPPORTED-STANDARD.md)
- [Documentation and ownership index](docs/README.md)
- [Fixture policy](docs/fixture-policy.md)
- [Dependency policy](docs/dependency-policy.md)
- [JSON Schema Test Suite provenance](vendor/json-schema-test-suite/UPSTREAM.md)

The ownership index links the reserved schema, fixture, manifest, result, and
script areas without defining their later contracts.

## Scaffold Verification

From the repository root, run:

```bash
scripts/validate-repository.sh
```

The validator resolves the repository from its own path, so it can also be
invoked through a relative or absolute path from another working directory.
It runs offline and checks repository integrity, the exact dependency records,
the pinned upstream qualification subset, and public-content boundaries. A
passing result is not an ORKS conformance result.

## Contributions and License

Contributions require Developer Certificate of Origin 1.1 sign-off.
ORKS-authored content is licensed under the Apache License, Version 2.0; see
[LICENSE](LICENSE) and [NOTICE](NOTICE). The pinned JSON Schema Test Suite
subset retains its upstream [MIT License](vendor/json-schema-test-suite/LICENSE).
