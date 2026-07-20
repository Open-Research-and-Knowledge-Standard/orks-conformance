# Fixture Policy

- Classification: Repository policy
- Status: Applies to future committed fixtures

No executable fixture is present in this repository scaffold. Later approved
fixture work is governed by the following public-content boundary.

## Source and Licensing

Future committed fixtures must be complete synthetic material or safely
licensed material. Each fixture must have an explicit provenance label and an
explicit expected outcome. Later approved manifest and fixture work will
define how those facts are serialized; this policy does not pre-empt that
contract.

Fixtures must not contain private corpora, unlicensed or unauthorized
third-party copyrighted material, credentials, raw prompts or model responses,
model files, generated indexes, telemetry, host paths, local bindings,
installation profiles, or installation-local state.

## Deterministic and Faithful Behavior

Future committed fixtures are non-fetching by default. Deterministic
validation must not fetch fixture content. Positive, negative, boundary,
hostile, and compatibility expectations remain explicit.

Redaction, normalization, or repair cannot turn an invalid input into a
passing case unless the pinned standard requires that exact behavior. A schema,
fixture, or tool cannot create, weaken, or reinterpret normative behavior
absent from the pinned source tree.

ASCII is the default for repository documentation and fixture metadata unless
an approved fixture explicitly tests Unicode behavior.

See the [pinned standard input](../SUPPORTED-STANDARD.md),
[fixture ownership index](../fixtures/README.md), and
[documentation index](README.md).
