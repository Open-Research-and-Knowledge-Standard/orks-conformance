# Script Ownership

- Status: ORKS-0202 repository infrastructure

[validate-repository.sh](validate-repository.sh) is the only executable in the
repository. It is dependency-free project infrastructure that runs offline
and checks the closed repository structure, licensing, source and vendor pins,
dependency records, links, and public-content boundaries.

[classify-dialect.py](classify-dialect.py) is the construct-only dialect
classifier. It is not executable. From the repository root:

```bash
python3 scripts/classify-dialect.py
```

It writes
[the partition record](../manifests/orks-schema-dialect-2020-12-portable-v1-partition.json).
It does not validate instances or call a schema engine.

[run-subset-scoped-incumbent.py](run-subset-scoped-incumbent.py) executes
only the IN_DIALECT partition groups against the admitted incumbent
engine. It is not executable. It requires an already materialized
isolated environment and must not invoke a package manager. It is not
the ORKS conformance command-line interface.

From the repository root, run:

```bash
scripts/validate-repository.sh
```

The script resolves the repository from its own location and therefore also
runs through a relative or absolute path from another working directory.
The executable entry point starts Bash with an empty inherited environment and
a fixed system command path before validation begins. Invoke the executable as
shown rather than passing it to a caller-configured shell.

It validates repository integrity only. It is not the ORKS conformance
command-line interface, a schema validator, a conformance test runner, or a
machine-readable report producer. ORKS-0202 has selected a task-local Python
qualification platform and hash-locked developer-tooling dependency closure,
but no public implementation runtime, language contract, or package. Those
inputs do not form a public conformance interface or production runtime.

See the [pinned standard input](../SUPPORTED-STANDARD.md) and
[documentation index](../docs/README.md).
