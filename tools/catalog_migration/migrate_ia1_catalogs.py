#!/usr/bin/env python3
"""Migra los maestros versionados de IA1 a assets JSON para Flutter.

No modifica los Excel fuente. Solo exporta columnas comprobables; campos sin
fuente, como precio, instituciones y comodatos, no se fabrican.
"""

from __future__ import annotations

import argparse
from datetime import UTC, datetime
import json
from pathlib import Path
from typing import Iterable

import openpyxl

from schemas import SCHEMA_VERSION, SOURCE_DESKTOP_COMMIT, normalize_text, sha256_files, stable_id, write_json
from validators import CatalogValidationError, require_unique, validate_catalog_directory


CLIENT_FILE = "AutoDataClientes.xlsx"
PRODUCT_FILE = "AutoDataProductos.xlsx"
OPTIONS_FILE = "AutomyDataMineOtro.xlsx"


def _records(path: Path, sheet_name: str) -> Iterable[dict[str, object]]:
    workbook = openpyxl.load_workbook(path, read_only=True, data_only=True)
    try:
        sheet = workbook[sheet_name]
        rows = sheet.iter_rows(values_only=True)
        headers = [normalize_text(value) for value in next(rows)]
        for row in rows:
            yield dict(zip(headers, row, strict=True))
    finally:
        workbook.close()


def _unique_text(values: Iterable[object], label: str) -> list[str]:
    normalized: dict[str, str] = {}
    for value in values:
        text = normalize_text(value)
        if not text:
            raise CatalogValidationError(f"{label}: se encontró un valor obligatorio vacío.")
        key = text.casefold()
        existing = normalized.get(key)
        if existing is not None and existing != text:
            raise CatalogValidationError(
                f"{label}: colisión por normalización entre {existing!r} y {text!r}."
            )
        normalized[key] = text
    return sorted(normalized.values(), key=str.casefold)


def _catalog(items: list[dict[str, object]], source: str) -> dict[str, object]:
    return {
        "schemaVersion": SCHEMA_VERSION,
        "source": source,
        "items": items,
    }


def _read_options(path: Path) -> dict[str, list[str]]:
    grouped: dict[str, list[object]] = {}
    for row in _records(path, "Listas"):
        field = normalize_text(row["campo"])
        option = row["opcion"]
        if field and normalize_text(option):
            grouped.setdefault(field, []).append(option)
    return {field: _unique_text(values, f"opciones/{field}") for field, values in grouped.items()}


def migrate(desktop_root: Path, output_root: Path, generated_at: str) -> dict[str, object]:
    client_path = desktop_root / CLIENT_FILE
    product_path = desktop_root / PRODUCT_FILE
    options_path = desktop_root / OPTIONS_FILE
    sources = (client_path, product_path, options_path)
    missing = [str(path) for path in sources if not path.is_file()]
    if missing:
        raise CatalogValidationError(f"No se encontraron fuentes: {', '.join(missing)}")

    client_names = _unique_text(
        (row["cliente"] for row in _records(client_path, "Clientes")), "clientes"
    )
    clients = [
        {"id": stable_id("ia1-client", name), "name": name}
        for name in client_names
    ]
    require_unique(clients, "id", "clients")

    line_names = _unique_text(
        (row["linea_pedido"] for row in _records(product_path, "LineasPedido")),
        "lineas",
    )
    lines = [
        {"id": stable_id("ia1-line", name), "name": name}
        for name in line_names
    ]
    line_ids = {item["name"]: item["id"] for item in lines}

    seen_pairs: set[tuple[str, str]] = set()
    products: list[dict[str, object]] = []
    for row in _records(product_path, "ProductosPorLinea"):
        line_name = normalize_text(row["linea_pedido"])
        product_name = normalize_text(row["producto"])
        if not line_name or not product_name:
            raise CatalogValidationError("products: línea o producto vacío.")
        if line_name not in line_ids:
            raise CatalogValidationError(f"products: línea sin maestro: {line_name}")
        key = (line_name.casefold(), product_name.casefold())
        if key in seen_pairs:
            raise CatalogValidationError(
                f"products: par línea-producto duplicado: {line_name} / {product_name}"
            )
        seen_pairs.add(key)
        products.append(
            {
                "id": stable_id("ia1-product", line_name, product_name),
                "lineId": line_ids[line_name],
                "name": product_name,
            }
        )
    products.sort(key=lambda item: (str(item["lineId"]), str(item["name"]).casefold()))
    require_unique(products, "id", "products")

    options = _read_options(options_path)
    write_json(output_root / "clients.json", _catalog(clients, CLIENT_FILE))
    write_json(output_root / "institutions.json", _catalog([], "No existe maestro versionado IA1"))
    write_json(output_root / "commercial_lines.json", _catalog(lines, PRODUCT_FILE))
    write_json(output_root / "products.json", _catalog(products, PRODUCT_FILE))
    write_json(output_root / "comodatos.json", _catalog([], "No existe maestro versionado IA1"))

    counts = validate_catalog_directory(output_root)
    catalog_files = [
        output_root / "clients.json",
        output_root / "institutions.json",
        output_root / "commercial_lines.json",
        output_root / "products.json",
        output_root / "comodatos.json",
    ]
    manifest = {
        "schemaVersion": SCHEMA_VERSION,
        "sourceDesktopCommit": SOURCE_DESKTOP_COMMIT,
        "generatedAt": generated_at,
        **counts,
        "options": options,
        "unavailableSources": {
            "institutions": "Los maestros IA1 versionados no contienen instituciones.",
            "comodatos": "Los maestros IA1 versionados no contienen comodatos por cliente/línea.",
            "productDetails": "No hay precios, códigos, presentación, categoría o expiración por producto.",
        },
        "checksum": sha256_files(catalog_files),
    }
    write_json(output_root / "catalog_manifest.json", manifest)
    return manifest


def main() -> int:
    repository_root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--desktop-root",
        type=Path,
        required=True,
        help="Raíz del checkout Desktop IA1; nunca se escribe en ella.",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=repository_root / "assets" / "catalogs",
    )
    parser.add_argument(
        "--generated-at",
        default=datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        help="Marca UTC ISO-8601; úsala fija para una regeneración byte a byte.",
    )
    args = parser.parse_args()
    manifest = migrate(args.desktop_root.resolve(), args.output_root.resolve(), args.generated_at)
    print(json.dumps(manifest, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
