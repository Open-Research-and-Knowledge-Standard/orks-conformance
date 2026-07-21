# ORKS-0202 Dependency Policy

- Classification: Informative
- Status: Accepted task-local developer-tooling dependency record
- Scope: ORKS-0202 schema compilation and validation only

## Boundary

ORKS-0202 uses the dependencies in this record only as local developer tooling.
They are not part of the ORKS portable format, a production runtime, or a full
conformance claim. The direct requirement is exactly `jsonschema==4.26.0`
without extras. The complete active closure is the five distributions in
`requirements.lock`.

Wheels and raw resolver, SBOM, ELF, and vulnerability payloads are disposable
verification evidence and are not repository content. This record does not
authorize wheel vendoring, redistribution, container bundling, package
publication, a source build, a Rust toolchain, ORKS-authored Rust, optional
format extras, another dependency, or a second native artifact. Any such
change requires a new review and, where applicable, a new planning decision.

## Qualification Platform

| Property | Accepted value |
|---|---|
| Python implementation | CPython `3.14.6` |
| Python executable SHA-256 | `f14781fc2d1dc0906fde82448c806981a6d978aa71591ed70fca0880225b174c` |
| SOABI | `cpython-314-x86_64-linux-gnu` |
| Operating system and machine | glibc Linux `x86_64` |
| Observed glibc | `2.43` |
| Wheel ABI | `cp314` |
| Wheel platform | `manylinux_2_17_x86_64` |
| Resolver and installer | pip `26.1.2` |

The exact executable is resolved by absolute path and hash before each use.
That installation-local path remains private verification evidence and is not
portable repository content. Invocation removes `PYTHONPATH` and `PYTHONHOME`,
sets `PYTHONNOUSERSITE=1`, and uses isolated mode:

```text
env -u PYTHONPATH -u PYTHONHOME PYTHONNOUSERSITE=1 <exact-python> -I
```

An interpreter, ABI, platform, libc, pip, or executable-hash mismatch fails
closed.

## Resolution Record

The accepted resolution used the official PyPI index, pip `26.1.2`, exact
CPython `3.14.6`, target implementation `cp`, Python `3.14.6`, ABI `cp314`,
platform `manylinux_2_17_x86_64`, final non-yanked binary wheels only, no
cache, no extras, and candidate upload cutoff `2026-07-20T15:17:25Z`.
The disposable JSON resolution report has SHA-256
`f5c5b30ce945421fd917be331f301cbd22463340a4f7b98503e08bec6b3ed410`.
The reviewed `requirements.lock` candidate has SHA-256
`299234d5a5ee23e9e46a8f34205fcfc0b884c3610f1b61e474c55f8a493bed22`.

The reproducible resolution shape is:

```text
env -u PYTHONPATH -u PYTHONHOME PYTHONNOUSERSITE=1 <exact-python> -I \
  -m pip install --isolated --dry-run --ignore-installed \
  --disable-pip-version-check --no-cache-dir --only-binary=:all: \
  --index-url https://pypi.org/simple \
  --implementation cp --python-version 3.14.6 --abi cp314 \
  --platform manylinux_2_17_x86_64 \
  --report <scratch-report> --requirement requirements.in
```

The report is reviewed and converted to the sorted `--require-hashes` lock;
the raw report is not committed.

## Locked Artifacts

| Distribution | Artifact source | Upstream project | Selected wheel | SHA-256 | Wheel license |
|---|---|---|---|---|---|
| `attrs==26.1.0` | [PyPI release](https://pypi.org/project/attrs/26.1.0/) | [python-attrs/attrs](https://github.com/python-attrs/attrs) | `attrs-26.1.0-py3-none-any.whl` | `c647aa4a12dfbad9333ca4e71fe62ddc36f4e63b2d260a37a8b83d2f043ac309` | `MIT` |
| `jsonschema==4.26.0` | [PyPI release](https://pypi.org/project/jsonschema/4.26.0/) | [python-jsonschema/jsonschema](https://github.com/python-jsonschema/jsonschema) | `jsonschema-4.26.0-py3-none-any.whl` | `d489f15263b8d200f8387e64b4c3a75f06629559fb73deb8fdfb525f2dab50ce` | `MIT` |
| `jsonschema-specifications==2025.9.1` | [PyPI release](https://pypi.org/project/jsonschema-specifications/2025.9.1/) | [python-jsonschema/jsonschema-specifications](https://github.com/python-jsonschema/jsonschema-specifications) | `jsonschema_specifications-2025.9.1-py3-none-any.whl` | `98802fee3a11ee76ecaca44429fda8a41bff98b00a0f2838151b113f210cc6fe` | `MIT` |
| `referencing==0.37.0` | [PyPI release](https://pypi.org/project/referencing/0.37.0/) | [python-jsonschema/referencing](https://github.com/python-jsonschema/referencing) | `referencing-0.37.0-py3-none-any.whl` | `381329a9f99628c9069361716891d34ad94af76e461dcb0335825aecc7692231` | `MIT` |
| `rpds-py==2026.6.3` | [PyPI release](https://pypi.org/project/rpds-py/2026.6.3/) | [crate-py/rpds](https://github.com/crate-py/rpds) | `rpds_py-2026.6.3-cp314-cp314-manylinux_2_17_x86_64.manylinux2014_x86_64.whl` | `dc319e5a1de4b6913aac94bf6a2f9e847371e0a140a43dd4991db1a09bc2d504` | `MIT` |

Artifact provenance is the versioned project release record and exact wheel at
the official PyPI service. Hash agreement is required before an artifact may
enter the disposable local artifact set.

The active CPython `3.14` dependency edges are exactly:

- `jsonschema` to `attrs`;
- `jsonschema` to `jsonschema-specifications`;
- `jsonschema` to `referencing`;
- `jsonschema` to `rpds-py`;
- `jsonschema-specifications` to `referencing`;
- `referencing` to `attrs`; and
- `referencing` to `rpds-py`.

The `referencing` dependency on `typing-extensions` applies only before Python
`3.13` and is inactive on the qualification platform. `attrs` and `rpds-py`
have no active dependency in this environment.

## Attribution and Notice Evidence

| Distribution | Wheel member | SHA-256 |
|---|---|---|
| `attrs` | `attrs-26.1.0.dist-info/licenses/LICENSE` | `882115c95dfc2af1eeb6714f8ec6d5cbcabf667caff8729f42420da63f714e9f` |
| `jsonschema` | `jsonschema-4.26.0.dist-info/licenses/COPYING` | `4f92a015a13c4d1a040bef018aa13430b4f1bc73b41b16bb846c346766de7439` |
| `jsonschema-specifications` | `jsonschema_specifications-2025.9.1.dist-info/licenses/COPYING` | `42dcd63495f87b4eb7c7757afa379bb55a53f94afd7a5f657d9adf57236e515c` |
| `referencing` | `referencing-0.37.0.dist-info/licenses/COPYING` | `42dcd63495f87b4eb7c7757afa379bb55a53f94afd7a5f657d9adf57236e515c` |
| `rpds-py` | `rpds_py-2026.6.3.dist-info/licenses/LICENSE` | `314e4e91be3baa93c0fb4bccc9e4e97cd643eb839b065af921782c2175fe9909` |

All five selected wheels contain the listed license member and no separate
notice member. No wheel-specific attribution is added to the project `NOTICE`
because these artifacts are not redistributed. The separate JSON Schema Test
Suite attribution does not apply to the wheels. A wheel-redistribution
proposal requires a separate notice-completeness review.

## Native Artifact Admission

The exact `rpds-py` wheel above is the only native wheel in the closure. It
contains one native member,
`rpds/rpds.cpython-314-x86_64-linux-gnu.so`, with SHA-256
`7963c4036c8ac51c7033fd08c9d460bcff614db2e985e40630608a791f3468ee`.
The member is an ELF 64-bit `x86-64` shared object for `cp314`. Review found no
RPATH, RUNPATH, TEXTREL, or executable stack and found the expected
GNU_RELRO and BIND_NOW controls.

The embedded CycloneDX `1.5` SBOM member is
`rpds_py-2026.6.3.dist-info/sboms/rpds-py.cyclonedx.json`, with SHA-256
`80a3bfbae1607e51b2569566a469b8a6d9a984d4923c0824086418a6c8a3e763`.
Its complete third-party native component inventory is:

| Component | Version | License expression |
|---|---|---|
| `archery` | `1.2.2` | `MIT` |
| `heck` | `0.5.0` | `MIT OR Apache-2.0` |
| `libc` | `0.2.177` | `MIT OR Apache-2.0` |
| `once_cell` | `1.21.3` | `MIT OR Apache-2.0` |
| `proc-macro2` | `1.0.103` | `MIT OR Apache-2.0` |
| `pyo3` | `0.29.0` | `MIT OR Apache-2.0` |
| `pyo3-build-config` | `0.29.0` | `MIT OR Apache-2.0` |
| `pyo3-ffi` | `0.29.0` | `MIT OR Apache-2.0` |
| `pyo3-macros` | `0.29.0` | `MIT OR Apache-2.0` |
| `pyo3-macros-backend` | `0.29.0` | `MIT OR Apache-2.0` |
| `quote` | `1.0.42` | `MIT OR Apache-2.0` |
| `rpds` | `1.2.1` | `MIT` |
| `smallvec` | `1.15.1` | `MIT OR Apache-2.0` |
| `syn` | `2.0.111` | `MIT OR Apache-2.0` |
| `target-lexicon` | `0.13.3` | `Apache-2.0 WITH LLVM-exception` |
| `triomphe` | `0.1.15` | `MIT OR Apache-2.0` |
| `unicode-ident` | `1.0.22` | `(MIT OR Apache-2.0) AND Unicode-3.0` |

The complete native license-expression set is therefore exactly `MIT`,
`MIT OR Apache-2.0`, `Apache-2.0 WITH LLVM-exception`, and
`(MIT OR Apache-2.0) AND Unicode-3.0`. It must not be collapsed to MIT-only.

## Materialization

Materialization is separate from resolution and validation. It uses only a
hash-verified disposable artifact set, an isolated virtual environment with
system site packages disabled, binary wheels, the exact lock, and no index:

```text
<exact-venv-python> -I -m pip install --isolated \
  --disable-pip-version-check --no-cache-dir --no-index \
  --find-links <verified-wheel-directory> --only-binary=:all: \
  --require-hashes --requirement requirements.lock
```

Validation runs offline from the already materialized environment. It must
not invoke a package manager, retrieve a schema, or fall back to an ambient
Python package.

## Vulnerability Evidence

The accepted 2026-07-20 pre-edit evidence covered 24 exact PyPI and
`crates.io` package/version queries. Its request SHA-256 was
`760eba08d7aaf57271ae6ea5de8177b3b5e519b6bc685c7b65ba75db617fa349`;
its raw OSV batch-response SHA-256 was
`8da816bf833b9d8a08a47dcc0b8b8a95f33552d1c2639b82f1ea4f828394efb5`.
All 24 results contained no advisory.

The public lock candidate was refreshed on `2026-07-21T07:38:45Z`. Its five
PyPI identities come from the hash-matching wheels. Its 19 `crates.io` root,
target, and component identities are reconstructed from the hash-matching
embedded SBOM. Because the historical request bytes and tuple inventory were
intentionally disposable, this record does not claim byte or semantic identity
with the 2026-07-20 request.

The refresh uses the following exact query order:

| Position | Ecosystem | Package | Version | Inventory source |
|---:|---|---|---|---|
| 1 | `PyPI` | `attrs` | `26.1.0` | Selected wheel |
| 2 | `PyPI` | `jsonschema` | `4.26.0` | Selected wheel |
| 3 | `PyPI` | `jsonschema-specifications` | `2025.9.1` | Selected wheel |
| 4 | `PyPI` | `referencing` | `0.37.0` | Selected wheel |
| 5 | `PyPI` | `rpds-py` | `2026.6.3` | Selected wheel |
| 6 | `crates.io` | `archery` | `1.2.2` | SBOM component |
| 7 | `crates.io` | `heck` | `0.5.0` | SBOM component |
| 8 | `crates.io` | `libc` | `0.2.177` | SBOM component |
| 9 | `crates.io` | `once_cell` | `1.21.3` | SBOM component |
| 10 | `crates.io` | `proc-macro2` | `1.0.103` | SBOM component |
| 11 | `crates.io` | `pyo3` | `0.29.0` | SBOM component |
| 12 | `crates.io` | `pyo3-build-config` | `0.29.0` | SBOM component |
| 13 | `crates.io` | `pyo3-ffi` | `0.29.0` | SBOM component |
| 14 | `crates.io` | `pyo3-macros` | `0.29.0` | SBOM component |
| 15 | `crates.io` | `pyo3-macros-backend` | `0.29.0` | SBOM component |
| 16 | `crates.io` | `quote` | `1.0.42` | SBOM component |
| 17 | `crates.io` | `rpds` | `1.2.1` | SBOM component |
| 18 | `crates.io` | `rpds` | `2026.6.3` | SBOM target component |
| 19 | `crates.io` | `rpds-py` | `2026.6.3` | SBOM metadata root |
| 20 | `crates.io` | `smallvec` | `1.15.1` | SBOM component |
| 21 | `crates.io` | `syn` | `2.0.111` | SBOM component |
| 22 | `crates.io` | `target-lexicon` | `0.13.3` | SBOM component |
| 23 | `crates.io` | `triomphe` | `0.1.15` | SBOM component |
| 24 | `crates.io` | `unicode-ident` | `1.0.22` | SBOM component |

The request is an ASCII-subset UTF-8 JSON object with LF line endings and one
terminal LF. It uses two-space indentation for the `queries` member and four-
space indentation for each query. Every query is one line with keys in exact
`package`, `version` order and nested keys in exact `ecosystem`, `name` order;
all but position 24 end in a comma. This deterministic request has SHA-256
`eaa9ecc5a9891a75da33c00572b4fa514fc38b3ac32816fc56a80ba772358fcf`.
OSV returned 24 results, no pagination token, and zero advisories. The raw
HTTP response body contained no terminal LF and independently reproduced
SHA-256
`8da816bf833b9d8a08a47dcc0b8b8a95f33552d1c2639b82f1ea4f828394efb5`.
The disposable evidence file adds one storage LF and is not itself identified
by that body hash.

The historical request bytes were intentionally disposable and are not
available for serialization comparison; the prior request hash remains
historical evidence rather than being rewritten. The refresh query and
response also remain disposable and are not repository files. Any future
advisory, pagination, version, filename, hash, license, SBOM, native member,
ABI, platform, provenance, dependency-edge, or query-inventory drift stops
publication for review.
