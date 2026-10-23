"""Apply VERSION to the Flutter manifest before building either platform."""

import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1]
version = (root / "VERSION").read_text(encoding="utf-8").strip()
if not re.fullmatch(r"\d+\.\d+\.\d+\+[1-9]\d*", version):
    raise SystemExit("VERSION must contain major.minor.patch+build")
manifest = root / "apps/mobile/pubspec.yaml"
content, count = re.subn(r"(?m)^version: .+$", f"version: {version}", manifest.read_text(encoding="utf-8"))
if count != 1:
    raise SystemExit("Expected exactly one version in the application manifest")
manifest.write_text(content, encoding="utf-8")
print(version)
