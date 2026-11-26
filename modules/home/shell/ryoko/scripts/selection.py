#!/usr/bin/env python3
"""Edit the managed Nix lists used by ryoko.

The files are intentionally simple: a flat list of quoted application names, or
a flat list of package expressions. Adding and removing only touches the list
body, so comments and blank lines survive edits.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

PACKAGE_RE = re.compile(r"^[A-Za-z0-9_][A-Za-z0-9_.-]*$")
APP_LINE_RE = re.compile(r'^\s*"([^"]*)"\s*,?\s*(?:#.*)?$')


class SelectionError(Exception):
    pass


def _read_lines(path: Path) -> list[str]:
    try:
        return path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise SelectionError(f"无法读取 {path}: {exc}") from exc


def _write_lines(path: Path, lines: list[str]) -> None:
    try:
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    except OSError as exc:
        raise SelectionError(f"无法写入 {path}: {exc}") from exc


def _list_bounds(lines: list[str]) -> tuple[int, int]:
    start = None
    for index, line in enumerate(lines):
        stripped = line.strip()
        if start is None:
            if stripped.startswith("["):
                start = index
            continue
        if stripped.startswith("]"):
            return start, index
    raise SelectionError("找不到列表边界（需要一行 '[' 和一行 ']'）")


def _app_payload(line: str) -> str | None:
    match = APP_LINE_RE.match(line)
    return match.group(1) if match else None


def _package_payload(line: str) -> str | None:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return None
    if "#" in stripped:
        stripped = stripped.split("#", 1)[0].strip()
    return stripped or None


def _read_apps(path: Path) -> tuple[list[str], list[str], int, int]:
    lines = _read_lines(path)
    start, end = _list_bounds(lines)
    apps: list[str] = []
    for line in lines[start + 1 : end]:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        payload = _app_payload(line)
        if payload is None:
            raise SelectionError(f"无法解析应用行: {line!r}")
        apps.append(payload)
    return lines, apps, start, end


def _read_packages(path: Path) -> tuple[list[str], list[str], int, int]:
    lines = _read_lines(path)
    start, end = _list_bounds(lines)
    packages: list[str] = []
    for line in lines[start + 1 : end]:
        payload = _package_payload(line)
        if payload is not None:
            packages.append(payload)
    return lines, packages, start, end


def _append_before_end(lines: list[str], end: int, body: list[str]) -> list[str]:
    return lines[:end] + body + lines[end:]


def add_apps(path: Path, names: list[str], catalog: set[str], dry_run: bool) -> list[str]:
    lines, apps, start, end = _read_apps(path)
    unknown = [name for name in names if name not in catalog]
    if unknown:
        raise SelectionError("未知应用: " + ", ".join(unknown))
    seen = set(apps)
    additions: list[str] = []
    for name in names:
        if name not in seen:
            seen.add(name)
            additions.append(name)
    if additions and not dry_run:
        _write_lines(path, _append_before_end(lines, end, [f'  "{name}"' for name in additions]))
    return apps + additions


def remove_apps(path: Path, names: list[str], dry_run: bool) -> tuple[list[str], list[str]]:
    lines, apps, start, end = _read_apps(path)
    drop = set(names)
    missing = [name for name in names if name not in apps]
    kept: list[str] = []
    for index, line in enumerate(lines):
        if start < index < end and _app_payload(line) in drop:
            continue
        kept.append(line)
    if not dry_run:
        _write_lines(path, kept)
    remaining = [app for app in apps if app not in drop]
    return remaining, missing


def add_packages(path: Path, exprs: list[str], dry_run: bool) -> list[str]:
    invalid = [expr for expr in exprs if not PACKAGE_RE.match(expr)]
    if invalid:
        raise SelectionError(
            "只接受简单的 Nix 属性路径（例如 obsidian、kdePackages.filelight）: "
            + ", ".join(invalid)
        )
    lines, packages, start, end = _read_packages(path)
    seen = set(packages)
    additions: list[str] = []
    for expr in exprs:
        if expr not in seen:
            seen.add(expr)
            additions.append(expr)
    if additions and not dry_run:
        _write_lines(path, _append_before_end(lines, end, [f"  {expr}" for expr in additions]))
    return packages + additions


def remove_packages(path: Path, exprs: list[str], dry_run: bool) -> tuple[list[str], list[str]]:
    lines, packages, start, end = _read_packages(path)
    drop = set(exprs)
    missing = [expr for expr in exprs if expr not in packages]
    kept: list[str] = []
    for index, line in enumerate(lines):
        if start < index < end and _package_payload(line) in drop:
            continue
        kept.append(line)
    if not dry_run:
        _write_lines(path, kept)
    remaining = [package for package in packages if package not in drop]
    return remaining, missing


def _catalog(value: str) -> set[str]:
    if not value:
        return set()
    try:
        data = json.loads(value)
    except json.JSONDecodeError as exc:
        raise SelectionError(f"RYOKO_APPS_JSON 无效: {exc}") from exc
    return {item["name"] for item in data}


def _print_items(items: list[str]) -> None:
    if items:
        print("\n".join(items))


def _common_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--file", required=True, type=Path)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--catalog", default=os.environ.get("RYOKO_APPS_JSON", ""))
    return parser


def _build_parser() -> argparse.ArgumentParser:
    common = _common_parser()
    parser = argparse.ArgumentParser(prog="ryoko-selection", description=__doc__)
    kinds = parser.add_subparsers(dest="kind", required=True)

    for kind in ("apps", "packages"):
        kind_parser = kinds.add_parser(kind)
        actions = kind_parser.add_subparsers(dest="action", required=True)
        actions.add_parser("list", parents=[common])
        actions.add_parser("has", parents=[common]).add_argument("items", nargs=1)
        actions.add_parser("add", parents=[common]).add_argument("items", nargs="+")
        actions.add_parser("remove", parents=[common]).add_argument("items", nargs="+")

    return parser


def _run(args: argparse.Namespace) -> int:
    path: Path = args.file
    dry_run: bool = args.dry_run
    catalog = _catalog(args.catalog)

    if args.kind == "apps":
        if args.action == "list":
            _, apps, _, _ = _read_apps(path)
            _print_items(apps)
            return 0
        if args.action == "has":
            _, apps, _, _ = _read_apps(path)
            return 0 if args.items[0] in apps else 1
        if args.action == "add":
            apps = add_apps(path, args.items, catalog, dry_run)
            _print_items(apps)
            return 0
        if args.action == "remove":
            remaining, missing = remove_apps(path, args.items, dry_run)
            _print_items(remaining)
            if missing:
                print("未启用: " + ", ".join(missing), file=sys.stderr)
                return 4 if len(missing) == len(args.items) else 0
            return 0

    if args.kind == "packages":
        if args.action == "list":
            _, packages, _, _ = _read_packages(path)
            _print_items(packages)
            return 0
        if args.action == "has":
            _, packages, _, _ = _read_packages(path)
            return 0 if args.items[0] in packages else 1
        if args.action == "add":
            packages = add_packages(path, args.items, dry_run)
            _print_items(packages)
            return 0
        if args.action == "remove":
            remaining, missing = remove_packages(path, args.items, dry_run)
            _print_items(remaining)
            if missing:
                print("未受管: " + ", ".join(missing), file=sys.stderr)
                return 4 if len(missing) == len(args.items) else 0
            return 0

    raise SelectionError("未知操作")


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    try:
        return _run(args)
    except SelectionError as exc:
        print(f"ryoko-selection: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
