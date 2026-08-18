#!/usr/bin/env python3
import copy
import hashlib
import json
import re
import sys
from pathlib import Path
from urllib.parse import urljoin

REPO_ROOT = Path(__file__).resolve().parents[1]
CORPUS = REPO_ROOT / "vendor" / "json-schema-test-suite"
TESTS = CORPUS / "tests" / "draft2020-12"
REMOTES = CORPUS / "remotes"
PARTITION = REPO_ROOT / "manifests" / "orks-schema-dialect-2020-12-portable-v1-partition.json"
SUITE_COMMIT = "c0b038ad7244712cf73650f44e90d0bc5704e8c7"
DIALECT = "orks-schema-dialect:2020-12-portable-v1"
RULE_IDS = {
    "boolean-root": "ORKS-RULE-000589",
    "missing-schema": "ORKS-RULE-000590",
    "custom-metaschema": "ORKS-RULE-000590",
    "unknown-keyword": "ORKS-RULE-000592",
    "excluded-keyword": "ORKS-RULE-000592",
    "uniqueItems-maxItems": "ORKS-RULE-000607",
    "then-else": "ORKS-RULE-000606",
    "type-number": "ORKS-RULE-000601",
    "type-name": "ORKS-RULE-000600",
    "type-array": "ORKS-RULE-000602",
    "type-shape": "ORKS-RULE-000591",
    "unsafe-number": "ORKS-RULE-000599",
    "pattern-not-string": "ORKS-RULE-000614",
    "pattern-too-long": "ORKS-RULE-000613",
    "pattern-non-ascii": "ORKS-RULE-000613",
    "guard-elsewhere": "ORKS-RULE-000632",
    "whole-not-wrapped": "ORKS-RULE-000631",
    "whole-wrapper": "ORKS-RULE-000631",
    "dot": "ORKS-RULE-000615",
    "dangling-escape": "ORKS-RULE-000616",
    "bad-escape": "ORKS-RULE-000616",
    "group-or-alt": "ORKS-RULE-000621",
    "bare-meta": "ORKS-RULE-000615",
    "non-printable": "ORKS-RULE-000613",
    "nested-class": "ORKS-RULE-000620",
    "class-range": "ORKS-RULE-000619",
    "unclosed-class": "ORKS-RULE-000618",
    "empty-class": "ORKS-RULE-000618",
    "star-plus": "ORKS-RULE-000625",
    "bad-rep": "ORKS-RULE-000626",
    "two-repetitions": "ORKS-RULE-000623",
    "rep-target": "ORKS-RULE-000624",
    "count-form": "ORKS-RULE-000626",
    "count-range": "ORKS-RULE-000626",
    "open-rep": "ORKS-RULE-000625",
    "patternProperties-shape": "ORKS-RULE-000591",
    "patternProperties-form": "ORKS-RULE-000629",
    "schema-array-shape": "ORKS-RULE-000611",
    "schema-map-shape": "ORKS-RULE-000610",
    "unresolved-ref": "ORKS-RULE-000642",
    "ref-not-string": "ORKS-RULE-000642",
    "schema-not-object": "ORKS-RULE-000588",
}
STANDARD_SCHEMA = "https://json-schema.org/draft/2020-12/schema"

ADMITTED = {
    "$schema", "$id", "$anchor", "$ref", "$defs",
    "allOf", "anyOf", "oneOf", "not", "if", "then", "else",
    "dependentSchemas", "prefixItems", "items", "properties",
    "patternProperties", "additionalProperties", "propertyNames",
    "type", "enum", "const", "maximum", "exclusiveMaximum",
    "minimum", "exclusiveMinimum", "maxLength", "minLength", "pattern",
    "maxItems", "minItems", "uniqueItems", "maxProperties",
    "minProperties", "required", "dependentRequired",
}
EXCLUDED = {
    "$dynamicAnchor", "$dynamicRef", "$vocabulary", "$comment",
    "$recursiveRef", "$recursiveAnchor",
    "unevaluatedItems", "unevaluatedProperties",
    "contains", "minContains", "maxContains", "multipleOf",
    "format", "contentEncoding", "contentMediaType", "contentSchema",
    "title", "description", "default", "deprecated", "readOnly",
    "writeOnly", "examples",
}
SCHEMA_MAP_KEYS = {"$defs", "properties", "patternProperties", "dependentSchemas"}
SCHEMA_ARRAY_KEYS = {"allOf", "anyOf", "oneOf", "prefixItems"}
SCHEMA_SINGLE_KEYS = {
    "not", "if", "then", "else", "items", "additionalProperties", "propertyNames",
}
INT_BOUND_KEYS = {
    "maximum", "exclusiveMaximum", "minimum", "exclusiveMinimum",
    "maxLength", "minLength", "maxItems", "minItems",
    "maxProperties", "minProperties",
}
TYPE_NAMES = {"null", "boolean", "object", "array", "integer", "string"}
SAFE_MIN = -9007199254740991
SAFE_MAX = 9007199254740991
META = {".", "^", "$", "*", "+", "?", "{", "}", "[", "]", "(", ")", "|", "\\"}
ESC_OK = {".", "^", "$", "*", "+", "?", "{", "}", "[", "]", "(", ")", "|", "\\"}


class ClassifyError(Exception):
    pass


class Out(Exception):
    def __init__(self, rule):
        self.rule = rule


def is_int(n):
    return isinstance(n, int) and not isinstance(n, bool) and SAFE_MIN <= n <= SAFE_MAX


def strip_fragment(uri):
    if not uri:
        return ""
    return uri.split("#", 1)[0]


def join_uri(base, ref):
    if ref is None:
        return base
    if ref.startswith("urn:"):
        return ref
    if ref.startswith("#"):
        return strip_fragment(base) + ref
    if not base:
        return ref
    if base.startswith("urn:"):
        return ref
    return urljoin(base, ref)


def lint_pattern(text, allow_guard=False, allow_whole=False):
    if not isinstance(text, str):
        raise Out("pattern-not-string")
    raw = text.encode("utf-8")
    if len(raw) > 256:
        raise Out("pattern-too-long")
    try:
        raw.decode("ascii")
    except UnicodeDecodeError:
        raise Out("pattern-non-ascii")
    if text == "[^ -~]":
        if allow_guard:
            return "guard"
        raise Out("guard-elsewhere")
    if text.startswith("^") and text.endswith("$") and len(text) >= 2:
        if not allow_whole:
            raise Out("whole-not-wrapped")
        body = text[1:-1]
        lint_sequence(body)
        return "whole"
    if text.startswith("^"):
        lint_sequence(text[1:])
        return "prefix"
    lint_sequence(text)
    return "search"


def lint_sequence(text):
    i = 0
    reps = 0
    n = len(text)
    if n == 0:
        return
    while i < n:
        i, kind = read_atom(text, i)
        if i < n and text[i] in "?*+{":
            reps += 1
            if reps > 1:
                raise Out("two-repetitions")
            if kind == "bad-rep-target":
                raise Out("rep-target")
            i = read_rep(text, i)
    return


def read_atom(text, i):
    c = text[i]
    if c == ".":
        raise Out("dot")
    if c == "\\":
        if i + 1 >= len(text):
            raise Out("dangling-escape")
        nxt = text[i + 1]
        if nxt not in ESC_OK:
            raise Out("bad-escape")
        return i + 2, "esc"
    if c == "[":
        return read_class(text, i), "class"
    if c in "()|+":
        raise Out("group-or-alt")
    if c in META and c not in "^$":
        raise Out("bare-meta")
    if c in "^$" and i != 0 and not (c == "$" and i == len(text) - 1):
        # interior ^/$ treated as literal only if not meta use; treat as bare
        raise Out("bare-meta")
    if ord(c) < 32 or ord(c) > 126:
        raise Out("non-printable")
    return i + 1, "lit"


def read_class(text, i):
    assert text[i] == "["
    i += 1
    if i < len(text) and text[i] == "^":
        i += 1
    items = 0
    n = len(text)
    while i < n and text[i] != "]":
        if text[i] == "[":
            raise Out("nested-class")
        if text[i] == "\\":
            if i + 1 >= n:
                raise Out("dangling-escape")
            if text[i + 1] not in ESC_OK:
                raise Out("bad-escape")
            start = "esc"
            i += 2
        else:
            start = text[i]
            i += 1
        if i < n and text[i] == "-" and i + 1 < n and text[i + 1] != "]":
            i += 1
            if text[i] == "\\":
                raise Out("class-range")
            end = text[i]
            i += 1
            if not isinstance(start, str) or start == "esc":
                raise Out("class-range")
            ok = False
            for a, b in (("0", "9"), ("A", "Z"), ("a", "z")):
                if a <= start <= end <= b:
                    ok = True
            if not ok:
                raise Out("class-range")
        items += 1
    if i >= n or text[i] != "]":
        raise Out("unclosed-class")
    if items == 0:
        raise Out("empty-class")
    return i + 1


def read_rep(text, i):
    c = text[i]
    if c in "*+":
        raise Out("star-plus")
    if c == "?":
        return i + 1
    if c != "{":
        raise Out("bad-rep")
    m = re.match(r"\{(\d+)(,(\d*))?\}", text[i:])
    if not m:
        raise Out("bad-rep")
    lo = m.group(1)
    if lo != str(int(lo)) or (lo.startswith("0") and lo != "0"):
        raise Out("count-form")
    a = int(lo)
    if a > 64:
        raise Out("count-range")
    if m.group(2) is not None:
        if m.group(3) == "":
            raise Out("open-rep")
        hi = m.group(3)
        if hi != str(int(hi)) or (hi.startswith("0") and hi != "0"):
            raise Out("count-form")
        b = int(hi)
        if b > 64 or a > b:
            raise Out("count-range")
    return i + m.end()


class Classifier:
    def __init__(self):
        self.remote_resources = {}
        self._load_remotes()

    def _load_remotes(self):
        seen = set()
        for path in REMOTES.rglob("*.json"):
            rel = path.relative_to(REMOTES).as_posix()
            uri = "http://localhost:1234/" + rel
            doc = json.loads(path.read_text(encoding="utf-8"))
            self.remote_resources[uri] = doc
            if isinstance(doc, dict):
                self.index_node(doc, uri, self.remote_resources, seen)

    def index_node(self, node, base, resources, seen):
        if isinstance(node, bool) or not isinstance(node, dict):
            return
        ident = id(node)
        if ident in seen:
            return
        seen.add(ident)
        if isinstance(node.get("$id"), str):
            base = strip_fragment(join_uri(base, node["$id"]))
            resources[base] = node
        for key in SCHEMA_SINGLE_KEYS:
            if key in node:
                self.index_node(node[key], base, resources, seen)
        for key in SCHEMA_ARRAY_KEYS:
            if key in node and isinstance(node[key], list):
                for child in node[key]:
                    self.index_node(child, base, resources, seen)
        for key in SCHEMA_MAP_KEYS:
            if key in node and isinstance(node[key], dict):
                for child in node[key].values():
                    self.index_node(child, base, resources, seen)

    def classify_schema(
        self,
        schema,
        *,
        is_resource_root,
        corpus_absent_ok,
        tests=None,
        source_uri=None,
        filename=None,
    ):
        self.resources = dict(self.remote_resources)
        if isinstance(schema, dict):
            self.resources.setdefault("", schema)
            self.index_node(schema, "", self.resources, set())
        violations = set()
        visited = set()
        try:
            self.walk(
                schema,
                is_resource_root=is_resource_root,
                corpus_absent_ok=corpus_absent_ok,
                visited=visited,
                violations=violations,
                base="",
                apply_id=True,
            )
        except ClassifyError:
            return "ERROR", sorted(violations)
        except Out as e:
            violations.add(e.rule)
            return "OUT_OF_DIALECT", sorted(violations)
        if violations:
            return "OUT_OF_DIALECT", sorted(violations)
        return "IN_DIALECT", []

    def walk(self, node, *, is_resource_root, corpus_absent_ok, visited, violations, base, apply_id):
        if isinstance(node, bool):
            if is_resource_root:
                raise Out("boolean-root")
            return
        if not isinstance(node, dict):
            raise ClassifyError("schema-not-object")
        ident = (id(node),)
        if ident in visited:
            return
        visited.add(ident)

        if apply_id and isinstance(node.get("$id"), str):
            base = strip_fragment(join_uri(base, node["$id"]))

        if is_resource_root:
            schema = node.get("$schema")
            if schema is None:
                if not corpus_absent_ok:
                    raise Out("missing-schema")
            elif schema != STANDARD_SCHEMA:
                raise Out("custom-metaschema")

        keys = set(node)
        unknown = keys - ADMITTED - EXCLUDED
        if unknown:
            raise Out("unknown-keyword")
        bad = keys & EXCLUDED
        if bad:
            raise Out("excluded-keyword")

        if "uniqueItems" in node and "maxItems" not in node:
            raise Out("uniqueItems-maxItems")
        if "then" in node or "else" in node:
            if "if" not in node:
                raise Out("then-else")

        if "type" in node:
            t = node["type"]
            if isinstance(t, str):
                if t == "number":
                    raise Out("type-number")
                if t not in TYPE_NAMES:
                    raise Out("type-name")
            elif isinstance(t, list):
                if not t or len(t) != len(set(t)) or t != sorted(t):
                    raise Out("type-array")
                if "number" in t:
                    raise Out("type-number")
                if any(x not in TYPE_NAMES for x in t):
                    raise Out("type-name")
            else:
                raise Out("type-shape")

        self.scan_numbers(node)

        if "pattern" in node:
            lint_pattern(node["pattern"], allow_guard=False, allow_whole=False)

        if "patternProperties" in node:
            pp = node["patternProperties"]
            if not isinstance(pp, dict):
                raise Out("patternProperties-shape")
            for name in pp:
                kind = lint_pattern(name, allow_guard=False, allow_whole=False)
                if kind not in ("search", "prefix"):
                    raise Out("patternProperties-form")

        if self.is_exact_wrapper(node):
            lint_pattern(node["allOf"][1]["pattern"], allow_whole=True)
            return
        if "allOf" in node and isinstance(node["allOf"], list) and len(node["allOf"]) == 2:
            a, b = node["allOf"]
            if self.looks_like_guard(a) or self.looks_like_whole(b):
                raise Out("whole-wrapper")

        for key in SCHEMA_SINGLE_KEYS:
            if key in node:
                self.walk(node[key], is_resource_root=False,
                          corpus_absent_ok=corpus_absent_ok, visited=visited,
                          violations=violations, base=base, apply_id=True)
        for key in SCHEMA_ARRAY_KEYS:
            if key in node:
                arr = node[key]
                if not isinstance(arr, list):
                    raise Out("schema-array-shape")
                for child in arr:
                    self.walk(child, is_resource_root=False,
                              corpus_absent_ok=corpus_absent_ok, visited=visited,
                              violations=violations, base=base, apply_id=True)
        for key in SCHEMA_MAP_KEYS:
            if key in node:
                mp = node[key]
                if not isinstance(mp, dict):
                    raise Out("schema-map-shape")
                for child in mp.values():
                    self.walk(child, is_resource_root=False,
                              corpus_absent_ok=corpus_absent_ok, visited=visited,
                              violations=violations, base=base, apply_id=True)

        if "$ref" in node:
            target = node["$ref"]
            if not isinstance(target, str):
                raise ClassifyError("ref-not-string")
            uri = strip_fragment(join_uri(base, target))
            if uri.startswith("https://json-schema.org/"):
                resolved = {"$schema": STANDARD_SCHEMA, "type": "object"}
            else:
                resolved = self.resources.get(uri)
            if resolved is None:
                raise ClassifyError("unresolved-ref")
            self.walk(resolved, is_resource_root=True,
                      corpus_absent_ok=True, visited=visited,
                      violations=violations, base=uri, apply_id=False)

    def scan_numbers(self, node):
        for k, v in node.items():
            if k in ("const", "enum"):
                self.scan_data_numbers(v)
            elif k in INT_BOUND_KEYS:
                if not is_int(v):
                    raise Out("unsafe-number")

    def scan_data_numbers(self, v):
        if isinstance(v, bool):
            return
        if isinstance(v, int):
            if not is_int(v):
                raise Out("unsafe-number")
        elif isinstance(v, float):
            raise Out("unsafe-number")
        elif isinstance(v, list):
            for x in v:
                self.scan_data_numbers(x)
        elif isinstance(v, dict):
            for x in v.values():
                self.scan_data_numbers(x)

    def looks_like_guard(self, node):
        return (
            isinstance(node, dict)
            and set(node) == {"not"}
            and isinstance(node["not"], dict)
            and set(node["not"]) == {"pattern"}
            and node["not"]["pattern"] == "[^ -~]"
        )

    def looks_like_whole(self, node):
        return (
            isinstance(node, dict)
            and set(node) == {"pattern"}
            and isinstance(node["pattern"], str)
            and node["pattern"].startswith("^")
            and node["pattern"].endswith("$")
        )

    def is_exact_wrapper(self, node):
        return (
            isinstance(node, dict)
            and set(node.keys()) <= {"allOf", "$schema", "$id"}
            and "allOf" in node
            and isinstance(node["allOf"], list)
            and len(node["allOf"]) == 2
            and self.looks_like_guard(node["allOf"][0])
            and self.looks_like_whole(node["allOf"][1])
        )

    def is_guard_wrapper(self, node):
        return self.is_exact_wrapper(node)

    def resolve(self, ref, base):
        absolute = join_uri(base, ref)
        uri = strip_fragment(absolute)
        if uri.startswith("https://json-schema.org/"):
            return {"$schema": STANDARD_SCHEMA, "type": "object"}
        return self.resources.get(uri)


POISON_INSTANCE = {"uniqueItems": True}


def classify_corpus(file_order, mutate):
    clf = Classifier()
    groups = []
    for path in file_order:
        data = json.loads(path.read_text(encoding="utf-8"))
        for gi, group in enumerate(data):
            schema = copy.deepcopy(group["schema"])
            tests = copy.deepcopy(group.get("tests", []))
            filename = path.name
            source_uri = "file:%s#%d" % (path.name, gi)
            if mutate == "strip-desc":
                tests = [{k: v for k, v in t.items() if k != "description"} for t in tests]
            elif mutate == "flip-valid":
                for t in tests:
                    if "valid" in t:
                        t["valid"] = not t["valid"]
            elif mutate == "poison-instance":
                for t in tests:
                    t["data"] = copy.deepcopy(POISON_INSTANCE)
            elif mutate == "poison-filename":
                filename = "uniqueItems.json"
                source_uri = "https://example.invalid/uniqueItems.json"
            disp, rules = clf.classify_schema(
                schema,
                is_resource_root=True,
                corpus_absent_ok=True,
                tests=tests,
                source_uri=source_uri,
                filename=filename,
            )
            groups.append({
                "file": path.name,
                "group": gi,
                "assertions": len(tests),
                "disposition": disp,
                "rules": sorted({RULE_IDS.get(r, r) for r in rules}),
            })
    groups.sort(key=lambda g: (g["file"], g["group"]))
    return groups


def main():
    files = sorted(p for p in TESTS.glob("*.json"))
    groups = classify_corpus(files, None)
    key = lambda rows: [(g["file"], g["group"], g["disposition"], tuple(g["rules"])) for g in rows]
    baseline = key(groups)
    noninterference = {
        "stripped_descriptions_equal": baseline == key(classify_corpus(files, "strip-desc")),
        "flipped_expected_equal": baseline == key(classify_corpus(files, "flip-valid")),
        "poisoned_instance_equal": baseline == key(classify_corpus(files, "poison-instance")),
        "poisoned_filename_uri_equal": baseline == key(classify_corpus(files, "poison-filename")),
        "reversed_discovery_equal": baseline == key(classify_corpus(list(reversed(files)), None)),
    }
    g_in = sum(1 for g in groups if g["disposition"] == "IN_DIALECT")
    g_out = sum(1 for g in groups if g["disposition"] == "OUT_OF_DIALECT")
    g_err = sum(1 for g in groups if g["disposition"] == "ERROR")
    a_in = sum(g["assertions"] for g in groups if g["disposition"] == "IN_DIALECT")
    a_out = sum(g["assertions"] for g in groups if g["disposition"] == "OUT_OF_DIALECT")
    a_err = sum(g["assertions"] for g in groups if g["disposition"] == "ERROR")
    source = Path(__file__).read_bytes()
    body = json.dumps(
        {
            "dialect": DIALECT,
            "suite_commit": SUITE_COMMIT,
            "classifier_sha256": hashlib.sha256(source).hexdigest(),
            "groups": groups,
            "summary": {
                "groups": {"IN_DIALECT": g_in, "OUT_OF_DIALECT": g_out, "ERROR": g_err},
                "assertions": {"IN_DIALECT": a_in, "OUT_OF_DIALECT": a_out, "ERROR": a_err},
                "group_count": len(groups),
                "assertion_count": a_in + a_out + a_err,
                "noninterference": noninterference,
            },
        },
        indent=2,
        sort_keys=True,
    ) + "\n"
    PARTITION.write_text(body, encoding="ascii")
    digest = hashlib.sha256(body.encode()).hexdigest()
    print("groups", g_in, g_out, g_err, "total", len(groups))
    print("assertions", a_in, a_out, a_err, "total", a_in + a_out + a_err)
    print("sha256", digest, "bytes", len(body.encode()))
    print("noninterference", json.dumps(noninterference))
    if g_err or not all(noninterference.values()):
        sys.exit(1)


if __name__ == "__main__":
    main()
