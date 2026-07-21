# Conformance Documentation

- Classification: Informative
- Status: ORKS-0202 foundation index

These documents describe repository boundaries, the pinned Standard Kernel
input, task-local dependency qualification, upstream validator-qualification
data, and ownership reserved for later conformance work. They do not define
ORKS requirements or executable schema, fixture, manifest, result, report, or
public tooling formats.

## Documents

- [Pinned standard input](../SUPPORTED-STANDARD.md)
- [Fixture policy](fixture-policy.md)
- [Dependency policy](dependency-policy.md)
- [JSON Schema Test Suite provenance](../vendor/json-schema-test-suite/UPSTREAM.md)
- [JSON Schema Test Suite manifest](../vendor/json-schema-test-suite/MANIFEST.sha256)
- [Schema ownership](../schemas/README.md)
- [Fixture ownership](../fixtures/README.md)
- [Manifest ownership](../manifests/README.md)
- [Result ownership](../results/README.md)
- [Script ownership](../scripts/README.md)
- [Repository overview](../README.md)

The dependency lock and qualification corpus are developer-tooling inputs.
Reserved directories and index files do not imply that ORKS schemas,
executable fixtures, manifest formats, report formats, or conformance tooling
have been implemented.

Normative ORKS behavior remains in the exact public source tree identified by
the pinned standard input. Informative repository documentation cannot create,
change, waive, or repair a conformance requirement.
