import hashlib
import json
import sys
from pathlib import Path

from jsonschema.validators import Draft202012Validator
from referencing import Registry, Resource
from referencing.exceptions import NoSuchResource, Unresolvable, Unretrievable
from referencing.jsonschema import DRAFT202012

REPO_ROOT = Path(__file__).resolve().parents[1]
SUITE = REPO_ROOT / "vendor" / "json-schema-test-suite"
TESTS = SUITE / "tests" / "draft2020-12"
REMOTES = SUITE / "remotes"
PARTITION = (
    REPO_ROOT
    / "manifests"
    / "orks-schema-dialect-2020-12-portable-v1-partition.json"
)
REMOTE_PREFIX = "http://localhost:1234/"


def deny(uri):
    raise NoSuchResource(ref=uri)


def load_registry():
    registry = Registry(retrieve=deny)
    for path in sorted(REMOTES.rglob("*.json")):
        rel = path.relative_to(REMOTES).as_posix()
        uri = REMOTE_PREFIX + rel
        contents = json.loads(path.read_text(encoding="utf-8"))
        registry = registry.with_resource(
            uri, Resource.from_contents(contents, default_specification=DRAFT202012)
        )
    return registry


def load_in_dialect():
    partition = json.loads(PARTITION.read_text(encoding="utf-8"))
    files = {}
    cases = []
    for group in partition["groups"]:
        if group["disposition"] != "IN_DIALECT":
            continue
        name = group["file"]
        if name not in files:
            files[name] = json.loads((TESTS / name).read_text(encoding="utf-8"))
        body = files[name][group["group"]]
        tests = body.get("tests", [])
        if len(tests) != group["assertions"]:
            raise SystemExit(
                "assertion count mismatch %s %s expected %s got %s"
                % (name, group["group"], group["assertions"], len(tests))
            )
        for ti, test in enumerate(tests):
            cases.append(
                {
                    "file": name,
                    "group": group["group"],
                    "test": ti,
                    "schema": body["schema"],
                    "data": test["data"],
                    "valid": test["valid"],
                }
            )
    return cases, partition


def evaluate(cases, registry, mutate=None):
    checked = match = mismatch = error = 0
    first_fail = None
    for case in cases:
        expected = case["valid"]
        schema = case["schema"]
        data = case["data"]
        if mutate == "flip-first" and checked == 0:
            expected = not expected
        try:
            validator = Draft202012Validator(schema, registry=registry)
            actual = validator.is_valid(data)
        except (NoSuchResource, Unresolvable, Unretrievable, Exception) as exc:
            error += 1
            checked += 1
            if first_fail is None:
                first_fail = {
                    "kind": "error",
                    "file": case["file"],
                    "group": case["group"],
                    "test": case["test"],
                    "exc": type(exc).__name__,
                }
            continue
        checked += 1
        if actual == expected:
            match += 1
        else:
            mismatch += 1
            if first_fail is None:
                first_fail = {
                    "kind": "mismatch",
                    "file": case["file"],
                    "group": case["group"],
                    "test": case["test"],
                    "actual": actual,
                    "expected": expected,
                }
    return {
        "checked": checked,
        "match": match,
        "mismatch": mismatch,
        "error": error,
        "first_fail": first_fail,
    }


def prove_retrieve_raises(registry):
    try:
        registry.get_or_retrieve("http://example.invalid/not-in-registry")
    except (NoSuchResource, Unresolvable, Unretrievable) as exc:
        return type(exc).__name__
    raise SystemExit("retrieve did not raise")


def main():
    registry = load_registry()
    retrieve_exc = prove_retrieve_raises(registry)
    cases, partition = load_in_dialect()
    baseline = evaluate(cases, registry)
    flipped = evaluate(cases, registry, mutate="flip-first")
    partition_sha256 = hashlib.sha256(PARTITION.read_bytes()).hexdigest()
    body = {
        "dialect": partition["dialect"],
        "suite_commit": partition["suite_commit"],
        "classifier_sha256": partition["classifier_sha256"],
        "partition_sha256": partition_sha256,
        "retrieve_raises": retrieve_exc,
        "out_of_dialect_executed": False,
        "baseline": {
            "checked": baseline["checked"],
            "match": baseline["match"],
            "mismatch": baseline["mismatch"],
            "error": baseline["error"],
        },
        "flip_first": {
            "checked": flipped["checked"],
            "match": flipped["match"],
            "mismatch": flipped["mismatch"],
            "error": flipped["error"],
            "first_fail": flipped["first_fail"],
        },
    }
    json.dump(body, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    if (
        baseline["match"] != 541
        or baseline["mismatch"]
        or baseline["error"]
        or baseline["checked"] != 541
    ):
        sys.exit(1)
    if (
        flipped["mismatch"] != 1
        or flipped["match"] != 540
        or flipped["error"] != 0
    ):
        sys.exit(1)


if __name__ == "__main__":
    main()
