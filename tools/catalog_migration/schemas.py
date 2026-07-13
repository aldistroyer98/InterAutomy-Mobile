"""Primitivas deterministas para la migración de catálogos IA1."""

from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from pathlib import Path
from typing import Any, Iterable


SOURCE_DESKTOP_COMMIT = "e238e4788e40d96c7d3f2387dcc60d51123159b0"
SCHEMA_VERSION = 1


def normalize_text(value: object) -> str:
    """Conserva acentos, pero normaliza espacios y forma Unicode."""
    text = unicodedata.normalize("NFC", str(value or ""))
    return re.sub(r"\s+", " ", text).strip()


def identity_key(*values: object) -> str:
    return "|".join(normalize_text(value).casefold() for value in values)


def stable_id(prefix: str, *values: object) -> str:
    digest = hashlib.sha256(identity_key(*values).encode("utf-8")).hexdigest()
    return f"{prefix}-{digest[:20]}"


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(
        value,
        ensure_ascii=False,
        indent=2,
        sort_keys=True,
        separators=(",", ": "),
    )
    path.write_text(f"{payload}\n", encoding="utf-8", newline="\n")


def sha256_files(paths: Iterable[Path]) -> str:
    digest = hashlib.sha256()
    for path in sorted(paths, key=lambda item: item.name):
        digest.update(path.name.encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()
