#!/usr/bin/env python3
"""Regression tests for the ryoko managed-list editor."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("ryoko_selection", HERE.parent / "scripts" / "selection.py")
assert SPEC is not None and SPEC.loader is not None
selection = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(selection)

APPS = """# header
[
  "chrome"
  "edge"
]
"""

PACKAGES = """# header
{ pkgs, ... }:
with pkgs;
[
  # comment
  obsidian
]
"""


class SelectionTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.apps = self.dir / "apps.nix"
        self.apps.write_text(APPS, encoding="utf-8")
        self.packages = self.dir / "packages.nix"
        self.packages.write_text(PACKAGES, encoding="utf-8")

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_read_apps(self) -> None:
        _, apps, _, _ = selection._read_apps(self.apps)
        self.assertEqual(apps, ["chrome", "edge"])

    def test_add_apps_preserves_header_and_dedupes(self) -> None:
        selection.add_apps(self.apps, ["edge", "qq"], {"chrome", "edge", "qq"}, False)
        text = self.apps.read_text(encoding="utf-8")
        self.assertIn("# header", text)
        _, apps, _, _ = selection._read_apps(self.apps)
        self.assertEqual(apps, ["chrome", "edge", "qq"])

    def test_add_unknown_app_rejected(self) -> None:
        with self.assertRaises(selection.SelectionError):
            selection.add_apps(self.apps, ["nope"], {"chrome", "edge"}, False)
        self.assertNotIn('"nope"', self.apps.read_text(encoding="utf-8"))

    def test_remove_apps(self) -> None:
        remaining, missing = selection.remove_apps(self.apps, ["chrome"], False)
        self.assertEqual(remaining, ["edge"])
        self.assertEqual(missing, [])
        _, apps, _, _ = selection._read_apps(self.apps)
        self.assertEqual(apps, ["edge"])

    def test_read_packages_skips_comments(self) -> None:
        _, packages, _, _ = selection._read_packages(self.packages)
        self.assertEqual(packages, ["obsidian"])

    def test_add_packages(self) -> None:
        selection.add_packages(self.packages, ["kdePackages.filelight"], False)
        _, packages, _, _ = selection._read_packages(self.packages)
        self.assertEqual(packages, ["obsidian", "kdePackages.filelight"])
        self.assertIn("# comment", self.packages.read_text(encoding="utf-8"))

    def test_add_invalid_package_rejected(self) -> None:
        with self.assertRaises(selection.SelectionError):
            selection.add_packages(self.packages, ["foo; rm -rf /"], False)

    def test_remove_packages(self) -> None:
        remaining, missing = selection.remove_packages(self.packages, ["obsidian"], False)
        self.assertEqual(remaining, [])
        self.assertEqual(missing, [])
        _, packages, _, _ = selection._read_packages(self.packages)
        self.assertEqual(packages, [])

    def test_dry_run_does_not_write(self) -> None:
        before = self.apps.read_text(encoding="utf-8")
        selection.add_apps(self.apps, ["qq"], {"chrome", "edge", "qq"}, True)
        self.assertEqual(self.apps.read_text(encoding="utf-8"), before)

    def test_bounds_error(self) -> None:
        bad = self.dir / "bad.nix"
        bad.write_text("[]\n", encoding="utf-8")
        with self.assertRaises(selection.SelectionError):
            selection._read_apps(bad)

    def test_cli_has_and_remove_missing(self) -> None:
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(
                selection.main(["apps", "has", "--file", str(self.apps), "edge"]), 0
            )
            self.assertEqual(
                selection.main(["apps", "has", "--file", str(self.apps), "nope"]), 1
            )
            self.assertEqual(
                selection.main(["apps", "remove", "--file", str(self.apps), "nope"]), 4
            )


if __name__ == "__main__":
    unittest.main()
