# ORKS Conformance Rules

You are working in `orks-conformance`, the public executable conformance
repository for the Open Research and Knowledge Standard.

This file carries only what is true of this repository alone. Session start,
session close, and every project-wide rule are owned elsewhere and are named
below rather than restated here.

## Startup Addition

Session start is owned by the Orca canon and by
`orks-planning/runbooks/session-start.md`. One step is specific to this
repository and is not carried by either:

- Read the pinned public `orks-standard` contract required by the task before
  changing any schema, fixture, vector, manifest, or report.

## Authority and Ownership

Repository roles, access, and the ownership boundaries between `orks-planning`,
`orks-standard`, and this repository are declared in
`orks-planning/.orca/project-profile.md` and rendered into this repository's
generated entry point. They are not restated here.

The boundaries below are specific to this repository:

- This repository owns JSON Schemas, executable positive and negative
  fixtures, canonical-byte vectors, compatibility fixtures, conformance
  manifests and reports, and conformance tooling.
- A schema, fixture, validator, or report MUST NOT create, weaken, reinterpret,
  or silently repair normative behavior absent from the pinned standard.
- Keep production storage/query logic, Rust harness implementation, profiles,
  provider evaluation, models, and installation-local behavior out of this
  repository.

## Fixture and Public-Content Rules

- Use only complete synthetic or safely licensed fixtures with explicit
  provenance and expected outcomes.
- Do not fetch fixture content during deterministic validation.
- Do not commit private corpora, unlicensed or unauthorized third-party
  copyrighted material, credentials, raw prompts or responses, model files,
  generated indexes, telemetry, host paths, local bindings, or installation
  profiles.
- Keep positive, negative, boundary, hostile, and compatibility expectations
  explicit. Never use redaction or normalization to turn an invalid input into
  a passing fixture unless the pinned standard requires that exact behavior.
- Pin supported standard versions and compatibility profiles exactly. Do not
  infer support from a branch name, nearby version, or latest upstream state.

The project-wide character-set rule, and the bounded exception that admits the
vendored capability set under `.agents/skills/` and `.claude/skills/`, are in
`orks-planning/charter/working-rules.md`.

## Work Rules

Project-wide work rules are in `orks-planning/charter/working-rules.md`. They
apply here unchanged and are not restated: Developer Certificate of Origin 1.1
sign-off on public commits, the refusal of workflows, secrets, apps, webhooks,
Pages, external services, and package publication without explicit approval and
review, and the refusal of unrelated project authority, unrelated repositories,
host-global Model Context Protocol servers, plugins, apps, and agents.

The rules below are this repository's own additions to them:

- Work only on an approved ORKS backlog task and preserve its later-task
  exclusions.
- Record costly-to-reverse runtime, dependency, schema, manifest, or result-
  format choices in `orks-planning` before implementation.
- Keep deterministic checks offline and runnable from any working directory.
- Test parsers, canonicalization, identity bytes, resource ceilings,
  diagnostics, privacy boundaries, and failure ordering before relying on
  them.

## Closeout Addition

Session close is owned by the Orca canon and by
`orks-planning/runbooks/session-end.md`. Two steps are specific to this
repository and are not carried by either:

- Run `scripts/validate-repository.sh` and the task-specific fixture tests.
- Inspect the complete public diff for licensing, secrets, private content,
  unsafe fixtures, and ownership mistakes before any publication.

## Installed Capability Set

The fourteen Orca project capabilities are vendored into this repository under
`.agents/skills/` and `.claude/skills/`, as real tracked files in both roots,
and are accounted for by `skills-lock.json`. Nothing under either root is
edited here: an edit breaks the recorded content hash that proves the copy
unmodified. Both roots are updated together or not at all.
