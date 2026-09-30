#!/usr/bin/env python3
"""Bake saved in-game route edits into the matching dungeon Data/*.lua file."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import stat
import sys
import tempfile

NUMBER = re.compile(r"-?(?:\d+\.\d*|\d+|\.\d+)(?:[eE][+-]?\d+)?")
IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")
SECTIONS = ("tipOverrides", "customSteps", "routeOrder")
FIELDS = ("number", "mapID", "journalEncounterID", "linkedMapID", "entranceLink",
          "x", "y", "labelX", "labelY", "labelDX", "labelDY", "title", "tip", "roles")


class ParseError(ValueError):
    pass


class LuaTableParser:
    """Parse literal Lua tables without executing SavedVariables or addon code."""

    def __init__(self, source: str, offset: int = 0):
        self.source, self.offset = source, offset

    def error(self, message: str) -> ParseError:
        return ParseError(f"line {self.source.count(chr(10), 0, self.offset) + 1}: {message}")

    def skip_space(self) -> None:
        while self.offset < len(self.source):
            if self.source[self.offset].isspace():
                self.offset += 1
            elif self.source.startswith("--[[", self.offset):
                end = self.source.find("]]", self.offset + 4)
                if end < 0: raise self.error("unterminated block comment")
                self.offset = end + 2
            elif self.source.startswith("--", self.offset):
                end = self.source.find("\n", self.offset)
                self.offset = len(self.source) if end < 0 else end + 1
            else:
                break

    def take(self, character: str) -> bool:
        self.skip_space()
        if self.source.startswith(character, self.offset):
            self.offset += len(character)
            return True
        return False

    def expect(self, character: str) -> None:
        if not self.take(character): raise self.error(f"expected {character!r}")

    def identifier(self) -> str | None:
        self.skip_space()
        match = IDENTIFIER.match(self.source, self.offset)
        if not match: return None
        self.offset = match.end()
        return match.group()

    def string(self) -> str:
        quote = self.source[self.offset]
        self.offset += 1
        result: list[str] = []
        escapes = {"a": "\a", "b": "\b", "f": "\f", "n": "\n", "r": "\r",
                   "t": "\t", "v": "\v", "\\": "\\", '"': '"', "'": "'"}
        while self.offset < len(self.source):
            char = self.source[self.offset]
            self.offset += 1
            if char == quote: return "".join(result)
            if char != "\\":
                result.append(char)
                continue
            if self.offset >= len(self.source): raise self.error("unterminated string escape")
            escaped = self.source[self.offset]
            self.offset += 1
            if escaped in escapes:
                result.append(escapes[escaped])
            elif escaped == "z":
                while self.offset < len(self.source) and self.source[self.offset].isspace(): self.offset += 1
            elif escaped == "x":
                digits = self.source[self.offset:self.offset + 2]
                if len(digits) != 2 or not re.fullmatch(r"[0-9a-fA-F]{2}", digits):
                    raise self.error("invalid hexadecimal string escape")
                number = int(digits, 16)
                result.append(chr(number if number < 128 else 0xDC00 + number))
                self.offset += 2
            elif escaped.isdigit():
                digits = escaped
                while len(digits) < 3 and self.offset < len(self.source) and self.source[self.offset].isdigit():
                    digits += self.source[self.offset]
                    self.offset += 1
                number = int(digits)
                if number > 255: raise self.error("invalid decimal string escape")
                result.append(chr(number if number < 128 else 0xDC00 + number))
            elif escaped == "\n": result.append("\n")
            else: raise self.error(f"unsupported string escape \\{escaped}")
        raise self.error("unterminated string")

    def value(self):
        self.skip_space()
        if self.offset >= len(self.source): raise self.error("expected value")
        char = self.source[self.offset]
        if char == "{": return self.table()
        if char in ('"', "'"): return self.string()
        match = NUMBER.match(self.source, self.offset)
        if match:
            self.offset = match.end()
            raw = match.group()
            value = float(raw) if any(c in raw for c in ".eE") else int(raw)
            if isinstance(value, float) and not math.isfinite(value): raise self.error("non-finite number")
            return value
        word = self.identifier()
        if word == "true": return True
        if word == "false": return False
        if word == "nil": return None
        raise self.error(f"unsupported value {word!r}")

    def table(self) -> dict:
        self.expect("{")
        result: dict = {}
        implicit_index = 1
        while not self.take("}"):
            if self.take("["):
                key = self.value()
                if type(key) not in (int, str): raise self.error("table keys must be strings or integers")
                self.expect("]")
                self.expect("=")
                value = self.value()
            else:
                start = self.offset
                name = self.identifier()
                if name is not None and self.take("="):
                    key, value = name, self.value()
                else:
                    self.offset = start
                    key, value = implicit_index, self.value()
                    implicit_index += 1
            if value is not None: result[key] = value
            if self.take("}"): return result
            if not (self.take(",") or self.take(";")):
                raise self.error("expected comma, semicolon, or closing brace")
        return result

    def document(self) -> dict:
        if self.source.startswith("\ufeff"): self.offset = 1
        if self.identifier() != "BDSMDB": raise self.error("expected BDSMDB assignment")
        self.expect("=")
        data = self.value()
        if not isinstance(data, dict): raise self.error("BDSMDB must be a table")
        self.take(";")
        self.skip_space()
        if self.offset != len(self.source): raise self.error("unexpected code after BDSMDB table")
        return data


def quote_lua(value: str) -> str:
    escaped = []
    for character in value:
        code = ord(character)
        if character == "\\": escaped.append("\\\\")
        elif character == '"': escaped.append('\\"')
        elif character == "\n": escaped.append("\\n")
        elif character == "\r": escaped.append("\\r")
        elif character == "\t": escaped.append("\\t")
        elif 0xDC80 <= code <= 0xDCFF: escaped.append(f"\\{code - 0xDC00:03d}")
        elif code < 32 or code == 127: escaped.append(f"\\{code:03d}")
        else: escaped.append(character)
    return '"' + "".join(escaped) + '"'


def lua_literal(value) -> str:
    if isinstance(value, dict):
        return "{ " + ", ".join(
            f"{key if isinstance(key, str) and IDENTIFIER.fullmatch(key) else '[' + (str(key) if type(key) is int else quote_lua(key)) + ']'} = {lua_literal(item)}"
            for key, item in value.items()) + " }"
    if isinstance(value, str): return quote_lua(value)
    if isinstance(value, bool): return "true" if value else "false"
    if isinstance(value, (int, float)) and math.isfinite(value): return str(value)
    raise ValueError(f"unsupported value {value!r}")


def find_source(repo: Path) -> Path:
    client = repo.parent.parent.parent
    candidates = sorted((client / "WTF" / "Account").glob("*/SavedVariables/bdsm.lua"))
    if len(candidates) != 1:
        raise ValueError(f"found {len(candidates)} account-wide bdsm.lua files; pass --source")
    return candidates[0]


def table_bounds(source: str, pattern: str, start: int = 0) -> tuple[int, int]:
    match = re.search(pattern, source[start:])
    if not match: raise ValueError(f"cannot find {pattern!r} in dungeon data")
    opening = start + match.end() - 1
    if source[opening] != "{": raise ValueError("expected opening brace")
    depth, offset, quote = 0, opening, None
    while offset < len(source):
        char = source[offset]
        if quote:
            if char == "\\": offset += 2; continue
            if char == quote: quote = None
        elif source.startswith("--[[", offset):
            end = source.find("]]", offset + 4)
            if end < 0: raise ValueError("unterminated block comment")
            offset = end + 2; continue
        elif source.startswith("--", offset):
            end = source.find("\n", offset)
            offset = len(source) if end < 0 else end + 1; continue
        elif char in ('"', "'"): quote = char
        elif char == "{": depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0: return opening, offset + 1
        offset += 1
    raise ValueError("unterminated dungeon data table")


def dungeon_file(repo: Path, instance_id: int) -> Path:
    matches = []
    for path in (repo / "Data").glob("*.lua"):
        if path.name == "ImportedEdits.lua": continue
        source = path.read_text(encoding="utf-8")
        if re.search(rf"(?:addon\.dungeons\s*\[\s*{instance_id}\s*\]|\[\s*{instance_id}\s*\])\s*=\s*\{{", source):
            matches.append(path)
    if len(matches) != 1: raise ValueError(f"dungeon {instance_id}: expected one Data/*.lua file, found {len(matches)}")
    return matches[0]


def numbered(table: dict, label: str) -> list:
    if not isinstance(table, dict): raise ValueError(f"{label} must be a table")
    keys = sorted(table)
    if keys != list(range(1, len(keys) + 1)): raise ValueError(f"{label} must be an array")
    return [table[key] for key in keys]


def render_dungeon(source: str, instance_id: int, edits: dict) -> str:
    steps_start, steps_end = table_bounds(source, r"\bsteps\s*=\s*\{")
    old_steps = numbered(LuaTableParser(source[steps_start:steps_end]).value(), "steps")
    if not all(isinstance(step, dict) for step in old_steps): raise ValueError("steps must contain tables")
    for index, step in enumerate(old_steps, 1):
        if step.get("number") != index: raise ValueError(f"source step {index} has inconsistent number")
    overrides = edits["tipOverrides"]
    custom = numbered(edits["customSteps"], "customSteps")
    order = numbered(edits["routeOrder"], "routeOrder")
    known = {}
    for index, step in enumerate(old_steps, 1):
        merged = dict(step)
        changes = overrides.get(index, {})
        if not isinstance(changes, dict): raise ValueError(f"override {index} must be a table")
        for key, value in changes.items():
            if key == "roles":
                if not isinstance(value, dict): raise ValueError("roles override must be a table")
                merged["roles"] = {**merged.get("roles", {}), **value}
            elif key != "number": merged[key] = value
        known[f"b{index}"] = merged
    if set(overrides) - set(range(1, len(old_steps) + 1)):
        raise ValueError("saved override refers to an unknown source step")
    for step in custom:
        if not isinstance(step, dict) or type(step.get("customID")) is not int:
            raise ValueError("custom step requires an integer customID")
        key = f"c{step['customID']}"
        if key in known: raise ValueError(f"duplicate custom step {key}")
        known[key] = {field: value for field, value in step.items()
                      if field not in ("customID", "after", "number")}
    children = {}
    for step in custom:
        after = step.get("after")
        if after and after in known:
            children.setdefault(after, []).append(f"c{step['customID']}")
    initial, seen = [], set()
    def append(key):
        if key in seen: return
        seen.add(key); initial.append(key)
        for child in children.get(key, []): append(child)
    for index in range(1, len(old_steps) + 1): append(f"b{index}")
    for step in custom: append(f"c{step['customID']}")
    if order:
        selected = []
        for key in order:
            if key not in known: raise ValueError(f"route order refers to unknown step {key!r}")
            if key not in selected: selected.append(key)
        selected.extend(key for key in initial if key not in selected)
    else: selected = initial
    new_positions = {key: index for index, key in enumerate(selected, 1)}
    rendered = []
    for index, key in enumerate(selected, 1):
        step = {**known[key], "number": index}
        ordered_fields = [field for field in FIELDS if field in step]
        ordered_fields += [field for field in step if field not in FIELDS]
        metadata_fields = [field for field in ordered_fields if field not in ("title", "tip", "roles")]
        lines = ["        { " + ", ".join(f"{field} = {lua_literal(step[field])}" for field in metadata_fields)]
        for field in ("title", "tip", "roles"):
            if field in step:
                lines.append(f"          {field} = {lua_literal(step[field])}")
        rendered.append(",\n".join(lines) + " },")
    replacement = "{\n" + "\n".join(rendered) + "\n    }"
    source = source[:steps_start] + replacement + source[steps_end:]
    # Encounter warnings point into the source step array, so move their indices with it.
    trigger_pattern = r"\bencounterStart\s*=\s*\{"
    try:
        trigger_start, trigger_end = table_bounds(source, trigger_pattern)
    except ValueError:
        trigger_start = trigger_end = None
    if trigger_start is not None:
        triggers = LuaTableParser(source[trigger_start:trigger_end]).value()
        if triggers:
            bosses = [index for index, step in enumerate(old_steps, 1) if "journalEncounterID" in step]
            sorted_triggers = sorted(triggers, key=lambda encounter: triggers[encounter])
            invalid = [encounter for encounter, target in triggers.items()
                       if target not in range(1, len(old_steps) + 1) or
                       (bosses and target not in bosses)]
            if invalid and len(bosses) == len(triggers):
                # Older route data may have stale indices; match warnings to bosses in route order.
                old_targets = dict(zip(sorted_triggers, bosses))
            elif invalid:
                raise ValueError(f"encounter warnings have non-boss/invalid step indices: {invalid}")
            else: old_targets = triggers
            updated = {encounter: new_positions[f"b{old_targets[encounter]}"] for encounter in triggers}
            source = source[:trigger_start] + lua_literal(updated) + source[trigger_end:]
    digest = hashlib.sha256(json.dumps(edits, sort_keys=True, ensure_ascii=True).encode()).hexdigest()[:16]
    revision = hashlib.sha256(replacement.encode()).hexdigest()[:16]
    metadata = f'importRevision = "{revision}",\n    importedEditsHash = "{digest}",'
    if re.search(r'\bimportRevision\s*=\s*"[0-9a-f]+",\s*importedEditsHash\s*=\s*"[0-9a-f]+",', source):
        source = re.sub(r'\bimportRevision\s*=\s*"[0-9a-f]+",\s*importedEditsHash\s*=\s*"[0-9a-f]+",', metadata, source, count=1)
    else:
        source = re.sub(r'(\bsteps\s*=\s*\{)', metadata + '\n    ' + r'\1', source, count=1)
    return source


def import_routes(repo: Path, saved: dict, check: bool, dungeon_filter: int | None = None) -> int:
    sections = {}
    for section in SECTIONS:
        value = saved.get(section, {})
        if not isinstance(value, dict): raise ValueError(f"BDSMDB.{section} must be a table")
        sections[section] = value
    instance_ids = set().union(*(value.keys() for value in sections.values()))
    if any(type(key) is not int for key in instance_ids): raise ValueError("dungeon IDs must be integers")
    if dungeon_filter is not None:
        instance_ids &= {dungeon_filter}
    changes = []
    for instance_id in sorted(instance_ids):
        edits = {section: sections[section].get(instance_id, {}) for section in SECTIONS}
        if not any(edits.values()): continue
        path = dungeon_file(repo, instance_id)
        current = path.read_text(encoding="utf-8")
        digest = hashlib.sha256(json.dumps(edits, sort_keys=True, ensure_ascii=True).encode()).hexdigest()[:16]
        if f'importedEditsHash = "{digest}"' in current:
            print(f"Already imported: {path}")
            continue
        generated = render_dungeon(current, instance_id, edits)
        if generated != current: changes.append((path, generated))
    if check:
        for path, _ in changes: print(f"Pending edits: {path}", file=sys.stderr)
        return 1 if changes else 0
    for path, generated in changes:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent,
                                         prefix=f".{path.stem}.", suffix=".tmp", delete=False) as temp:
            temp.write(generated)
            temp_path = Path(temp.name)
        os.chmod(temp_path, stat.S_IMODE(path.stat().st_mode))
        os.replace(temp_path, path)
        print(f"Updated {path}")
    if not changes: print("No new route edits to import")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, help="account-wide WTF/.../SavedVariables/bdsm.lua")
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1],
                        help="addon repository (default: parent of tools)")
    parser.add_argument("--dungeon", type=int, help="import only this instance ID")
    parser.add_argument("--check", action="store_true", help="report pending edits without writing")
    args = parser.parse_args(argv)
    try:
        source = args.source or find_source(args.repo)
        if source.stat().st_size > 16 * 1024 * 1024: raise ValueError("SavedVariables file exceeds 16 MiB")
        saved = LuaTableParser(source.read_text(encoding="utf-8-sig")).document()
        return import_routes(args.repo, saved, args.check, args.dungeon)
    except (OSError, ValueError) as error:
        print(f"Import failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__": raise SystemExit(main())
