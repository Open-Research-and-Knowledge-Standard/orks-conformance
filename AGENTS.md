# ORKS Conformance Instructions

You are working in `orks-conformance`, the public executable conformance
repository for the Open Research and Knowledge Standard.

## Required Startup

1. Read the shared-parent `AGENTS.md`.
2. Read this file.
3. Read `orks-planning/sessions/current.md` and the active backlog contract.
4. Read the pinned public `orks-standard` contract required by the task.
5. Check Git status for every repository mounted in the session.
6. Identify the approved task, dependencies, exclusions, and exact
   repository-local verification command before changing files.

## Authority and Ownership

- `orks-planning` owns accepted product decisions, delivery state, risks, and
  repository boundaries.
- `orks-standard` owns normative ORKS language, examples, versioning,
  compatibility, and migrations.
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
- Use ASCII for repository documentation and metadata unless an approved
  fixture explicitly tests Unicode behavior.

## Work Rules

- Work only on an approved ORKS backlog task and preserve its later-task
  exclusions.
- Record costly-to-reverse runtime, dependency, schema, manifest, or result-
  format choices in `orks-planning` before implementation.
- Keep deterministic checks offline and runnable from any working directory.
- Test parsers, canonicalization, identity bytes, resource ceilings,
  diagnostics, privacy boundaries, and failure ordering before relying on
  them.
- Sign public commits under Developer Certificate of Origin 1.1.
- Do not add workflows, secrets, apps, webhooks, Pages, external services, or
  package publication without explicit approval and review.
- Do not load Directus, `pc-standards`, ProbablyComputers project authority,
  unrelated repositories, host-global MCP servers, plugins, apps, or agents.

## Closeout

Run the repository-local validator and task-specific fixture tests, run
`git diff --check`, inspect the complete public diff for licensing, secrets,
private content, unsafe fixtures, and ownership mistakes, update the ORKS
planning handoff, and follow `orks-planning/runbooks/session-end.md`.
