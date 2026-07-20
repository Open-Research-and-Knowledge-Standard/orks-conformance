# ORKS Conformance

## Repository Status

This repository currently contains only the bounded public repository
scaffold for executable Open Research and Knowledge Standard (ORKS)
conformance work.

It targets the accepted, unreleased ORKS `0.1.0` draft at the exact
`orks-standard` source commit
`52ffc5c88dc54598f3a48864942dfa505b1287e8`. It does not yet provide
executable conformance behavior or claim conformance to a released ORKS
specification.

No JSON Schema, executable fixture, canonical-byte vector, conformance
manifest, result or report format, conformance command-line interface,
package, dependency stack, continuous-integration workflow, or release
artifact is present in this scaffold.

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

The ownership index links the reserved schema, fixture, manifest, result, and
script areas without defining their later contracts.

## Scaffold Verification

From the repository root, run:

```bash
scripts/validate-repository.sh
```

The validator resolves the repository from its own path, so it can also be
invoked through a relative or absolute path from another working directory.
It runs offline and checks repository-scaffold integrity and public-content
boundaries only. A passing result is not an ORKS conformance result.

## Contributions and License

Contributions require Developer Certificate of Origin 1.1 sign-off. This
repository is licensed under the Apache License, Version 2.0. See
[LICENSE](LICENSE) and [NOTICE](NOTICE).
