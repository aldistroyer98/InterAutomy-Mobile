#!/usr/bin/env python3
"""Valida los assets IA1 versionados que consume la aplicación Flutter."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from schemas import SCHEMA_VERSION, SOURCE_DESKTOP_COMMIT, sha256_files
from validators import CatalogValidationError, validate_catalog_directory


CATALOG_FILES = (
    "clients.json",
    "institutions.json",
    "commercial_lines.json",
    "products.json",
    "comodatos.json",
)


def _manifest(root: Path) -> dict[str, Any]:
    path = root / "catalog_manifest.json"
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CatalogValidationError(
            f"No se pudo leer catalog_manifest.json: {error}"
        ) from error
    if not isinstance(value, dict):
        raise CatalogValidationError("catalog_manifest.json debe ser un objeto.")
    return value


def _require(value: object, label: str) -> None:
    if not isinstance(value, str) or not value.strip():
        raise CatalogValidationError(f"catalog_manifest.json: falta {label}.")


def _validate_options(value: object) -> None:
    if not isinstance(value, dict):
        raise CatalogValidationError("catalog_manifest.json: options debe ser un objeto.")
    for field, values in value.items():
        if not isinstance(field, str) or not field.strip():
            raise CatalogValidationError("catalog_manifest.json: options tiene un campo inválido.")
        if not isinstance(values, list) or not values:
            raise CatalogValidationError(
                f"catalog_manifest.json: options/{field} debe ser una lista no vacía."
            )
        normalized: set[str] = set()
        for option in values:
            if not isinstance(option, str) or not option.strip():
                raise CatalogValidationError(
                    f"catalog_manifest.json: options/{field} contiene un valor inválido."
                )
            key = option.strip().casefold()
            if key in normalized:
                raise CatalogValidationError(
                    f"catalog_manifest.json: options/{field} contiene un duplicado."
                )
            normalized.add(key)


def _validate_unavailable_sources(value: object) -> None:
    if not isinstance(value, dict):
        raise CatalogValidationError(
            "catalog_manifest.json: unavailableSources debe ser un objeto."
        )
    for field, explanation in value.items():
        if not isinstance(field, str) or not field.strip():
            raise CatalogValidationError(
                "catalog_manifest.json: unavailableSources tiene una clave inválida."
            )
        _require(explanation, f"unavailableSources/{field}")


def validate_assets(root: Path) -> dict[str, object]:
    counts = validate_catalog_directory(root)
    manifest = _manifest(root)
    if manifest.get("schemaVersion") != SCHEMA_VERSION:
        raise CatalogValidationError("catalog_manifest.json: schemaVersion inválido.")
    if manifest.get("sourceDesktopCommit") != SOURCE_DESKTOP_COMMIT:
        raise CatalogValidationError(
            "catalog_manifest.json: sourceDesktopCommit no corresponde a IA1."
        )
    _require(manifest.get("generatedAt"), "generatedAt")
    for key, actual in counts.items():
        if manifest.get(key) != actual:
            raise CatalogValidationError(
                f"catalog_manifest.json: {key}={manifest.get(key)!r}, esperado {actual}."
            )
    _validate_options(manifest.get("options"))
    _validate_unavailable_sources(manifest.get("unavailableSources"))
    expected_checksum = sha256_files(root / name for name in CATALOG_FILES)
    if manifest.get("checksum") != expected_checksum:
        raise CatalogValidationError("catalog_manifest.json: checksum no coincide.")
    return {**counts, "checksum": expected_checksum}


def main() -> int:
    repository_root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--catalog-root",
        type=Path,
        default=repository_root / "assets" / "catalogs",
        help="Directorio que contiene los JSON y el manifiesto.",
    )
    args = parser.parse_args()
    result = validate_assets(args.catalog_root.resolve())
    print(json.dumps({"status": "valid", **result}, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except CatalogValidationError as error:
        raise SystemExit(f"Validación de catálogos falló: {error}")
