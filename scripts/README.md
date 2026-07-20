# Script Ownership

- Status: Repository scaffold infrastructure

[validate-repository.sh](validate-repository.sh) is the only executable in the
current scaffold. It is dependency-free project infrastructure that runs
offline and checks the fixed repository structure, licensing, source pin,
links, and public-content boundaries.

From the repository root, run:

```bash
scripts/validate-repository.sh
```

The script resolves the repository from its own location and therefore also
runs through a relative or absolute path from another working directory.
The executable entry point starts Bash with an empty inherited environment and
a fixed system command path before validation begins. Invoke the executable as
shown rather than passing it to a caller-configured shell.

It validates scaffold integrity only. It is not the ORKS conformance
command-line interface, a schema validator, a conformance test runner, or a
machine-readable report producer. No implementation runtime, language,
package manager, or dependency stack for later conformance tooling has been
selected.

See the [pinned standard input](../SUPPORTED-STANDARD.md) and
[documentation index](../docs/README.md).
