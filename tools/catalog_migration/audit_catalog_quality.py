#!/usr/bin/env python3
"""Audita completitud IA1 sin modificar ni inferir valores de catálogo."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Iterable


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CATALOG_DIR = ROOT / "assets" / "catalogs"
DEFAULT_REPORT_DIR = ROOT / "build" / "reports"


def _text(value: Any) -> str:
    return str(value).strip() if value is not None else ""


def _normalized(value: Any) -> str:
    return " ".join(_text(value).casefold().split())


def _first_text(item: dict[str, Any], *keys: str) -> str:
    for key in keys:
        value = _text(item.get(key))
        if value:
            return value
    return ""


def _positive_number(value: Any) -> bool:
    try:
        return float(value) > 0
    except (TypeError, ValueError):
        return False


def _load_catalog(path: Path) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    document = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(document, dict) or not isinstance(document.get("items"), list):
        raise ValueError(f"{path.name}: se esperaba un objeto con una lista items")
    items = document["items"]
    if any(not isinstance(item, dict) for item in items):
        raise ValueError(f"{path.name}: todos los items deben ser objetos")
    return items, document


def _duplicate_count(items: Iterable[dict[str, Any]], key: Callable[[dict[str, Any]], str]) -> int:
    counts = Counter(value for item in items if (value := key(item)))
    return sum(count - 1 for count in counts.values() if count > 1)


def _percent(count: int, total: int) -> float:
    return round((count * 100 / total), 2) if total else 0.0


def _with_percentages(metrics: dict[str, int], total_key: str = "total") -> dict[str, Any]:
    total = metrics[total_key]
    return {
        **metrics,
        "percentages": {
            key: _percent(value, total)
            for key, value in metrics.items()
            if key != total_key and isinstance(value, int)
        },
    }


def _extract_comodato(value: Any) -> str:
    if isinstance(value, dict):
        return _first_text(value, "code", "codigo", "id", "name", "nombre")
    return _text(value)


def _iter_client_comodatos(client: dict[str, Any]) -> Iterable[tuple[str, str]]:
    mappings = client.get("comodatosByLine", client.get("comodatosPorLinea", {}))
    if not isinstance(mappings, dict):
        return
    for line, values in mappings.items():
        if not isinstance(values, list):
            continue
        for value in values:
            code = _extract_comodato(value)
            if code:
                yield _text(line), code


def build_report(catalog_dir: Path = DEFAULT_CATALOG_DIR) -> dict[str, Any]:
    names = ("clients", "institutions", "commercial_lines", "products", "comodatos")
    loaded = {name: _load_catalog(catalog_dir / f"{name}.json") for name in names}
    clients, _ = loaded["clients"]
    institutions, _ = loaded["institutions"]
    lines, _ = loaded["commercial_lines"]
    products, _ = loaded["products"]
    comodatos, _ = loaded["comodatos"]
    manifest = json.loads((catalog_dir / "catalog_manifest.json").read_text(encoding="utf-8"))

    line_ids = {_first_text(line, "id") for line in lines if _first_text(line, "id")}
    product_line_ids = [_first_text(product, "lineId", "line_id") for product in products]
    products_by_line = Counter(product_line_ids)

    client_with_name = sum(bool(_first_text(item, "name", "nombre")) for item in clients)
    client_with_institution = sum(
        bool(_first_text(item, "institutionId", "institution", "institucion"))
        for item in clients
    )
    client_with_location = sum(
        all(
            _first_text(item, *keys)
            for keys in (
                ("department", "departamento"),
                ("province", "provincia"),
                ("district", "distrito"),
                ("address", "direccion"),
            )
        )
        for item in clients
    )
    client_with_contact = sum(bool(_first_text(item, "contact", "contacto")) for item in clients)
    client_with_phone = sum(bool(_first_text(item, "phone", "telefono")) for item in clients)
    client_complete = sum(
        bool(_first_text(item, "id"))
        and bool(_first_text(item, "name", "nombre"))
        and bool(_first_text(item, "institutionId", "institution", "institucion"))
        and all(
            _first_text(item, *keys)
            for keys in (
                ("department", "departamento"),
                ("province", "provincia"),
                ("district", "distrito"),
                ("address", "direccion"),
            )
        )
        and bool(_first_text(item, "contact", "contacto"))
        and bool(_first_text(item, "phone", "telefono"))
        for item in clients
    )
    client_duplicates = max(
        _duplicate_count(clients, lambda item: _normalized(item.get("id"))),
        _duplicate_count(clients, lambda item: _normalized(_first_text(item, "name", "nombre"))),
    )
    client_metrics = _with_percentages(
        {
            "total": len(clients),
            "withName": client_with_name,
            "withInstitution": client_with_institution,
            "withLocation": client_with_location,
            "withContact": client_with_contact,
            "withPhone": client_with_phone,
            "duplicates": client_duplicates,
            "complete": client_complete,
            "incomplete": len(clients) - client_complete,
        }
    )

    def product_fields(item: dict[str, Any]) -> tuple[bool, bool, bool, bool, bool, bool]:
        code = bool(_first_text(item, "commercialCode", "code", "codigo"))
        name = bool(_first_text(item, "name", "nombre"))
        line_id = _first_text(item, "lineId", "line_id")
        line = bool(line_id and line_id in line_ids)
        price = _positive_number(item.get("price", item.get("precio")))
        presentation = bool(_first_text(item, "presentation", "presentacion"))
        category = bool(_first_text(item, "category", "categoria"))
        return code, name, line, price, presentation, category

    product_presence = [product_fields(item) for item in products]
    product_with_code = sum(fields[0] for fields in product_presence)
    product_with_name = sum(fields[1] for fields in product_presence)
    product_with_line = sum(fields[2] for fields in product_presence)
    product_with_price = sum(fields[3] for fields in product_presence)
    product_with_presentation = sum(fields[4] for fields in product_presence)
    product_with_category = sum(fields[5] for fields in product_presence)
    ready_for_order = sum(fields[1] and fields[2] for fields in product_presence)
    ready_for_execution = sum(all(fields) for fields in product_presence)
    product_duplicates = max(
        _duplicate_count(products, lambda item: _normalized(item.get("id"))),
        _duplicate_count(
            products,
            lambda item: "|".join(
                (
                    _normalized(_first_text(item, "lineId", "line_id")),
                    _normalized(_first_text(item, "name", "nombre")),
                )
            ),
        ),
    )
    product_metrics = _with_percentages(
        {
            "total": len(products),
            "withCommercialCode": product_with_code,
            "withName": product_with_name,
            "withLine": product_with_line,
            "withPrice": product_with_price,
            "withPresentation": product_with_presentation,
            "withCategory": product_with_category,
            "duplicates": product_duplicates,
            "readyForOrder": ready_for_order,
            "readyForExecution": ready_for_execution,
            "incomplete": len(products) - ready_for_execution,
        }
    )

    line_metrics = _with_percentages(
        {
            "total": len(lines),
            "withoutProducts": sum(products_by_line.get(line_id, 0) == 0 for line_id in line_ids),
            "duplicates": max(
                _duplicate_count(lines, lambda item: _normalized(item.get("id"))),
                _duplicate_count(lines, lambda item: _normalized(_first_text(item, "name", "nombre"))),
            ),
        }
    )

    inferred_institutions: dict[str, set[str]] = defaultdict(set)
    for client in clients:
        name = _first_text(client, "institution", "institucion", "institutionName")
        institution_id = _first_text(client, "institutionId")
        if name:
            inferred_institutions[_normalized(name)].add(institution_id)
    institution_metrics = _with_percentages(
        {
            "total": len(institutions),
            "inferableFromClients": len(inferred_institutions),
            "duplicates": max(
                _duplicate_count(institutions, lambda item: _normalized(item.get("id"))),
                _duplicate_count(
                    institutions,
                    lambda item: _normalized(_first_text(item, "name", "nombre")),
                ),
            ),
            "ambiguous": sum(len({value for value in ids if value}) > 1 for ids in inferred_institutions.values()),
        }
    )

    inferred_comodatos: set[str] = set()
    associated_clients: set[tuple[str, str]] = set()
    associated_lines: set[tuple[str, str]] = set()
    for client in clients:
        client_id = _first_text(client, "id")
        for line_id, code in _iter_client_comodatos(client):
            normalized = _normalized(code)
            inferred_comodatos.add(normalized)
            associated_clients.add((client_id, normalized))
            if line_id:
                associated_lines.add((_normalized(line_id), normalized))
    for product in products:
        code = _extract_comodato(product.get("comodato", product.get("comodatoCode")))
        if code:
            normalized = _normalized(code)
            inferred_comodatos.add(normalized)
            line_id = _first_text(product, "lineId", "line_id")
            if line_id:
                associated_lines.add((_normalized(line_id), normalized))
    comodato_metrics = _with_percentages(
        {
            "total": len(comodatos),
            "inferable": len(inferred_comodatos),
            "associatedToClient": len(associated_clients),
            "associatedToLine": len(associated_lines),
            "duplicates": max(
                _duplicate_count(comodatos, lambda item: _normalized(item.get("id"))),
                _duplicate_count(
                    comodatos,
                    lambda item: _normalized(_first_text(item, "code", "codigo", "name", "nombre")),
                ),
            ),
        }
    )

    expected_counts = {
        "clients": len(clients),
        "institutions": len(institutions),
        "lines": len(lines),
        "products": len(products),
        "comodatos": len(comodatos),
    }
    manifest_mismatches = {
        key: {"manifest": manifest.get(key), "actual": actual}
        for key, actual in expected_counts.items()
        if manifest.get(key) != actual
    }
    source_files = {}
    for name in (*names, "catalog_manifest"):
        path = catalog_dir / f"{name}.json"
        source_files[path.name] = {
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "bytes": path.stat().st_size,
        }

    return {
        "reportVersion": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "catalogDirectory": str(catalog_dir.resolve()),
        "definitions": {
            "withLocation": "department, province, district y address presentes",
            "withCommercialCode": "campo explícito commercialCode/code; no se analiza el nombre",
            "readyForOrder": "nombre y referencia a línea maestra válidos",
            "readyForExecution": "código, nombre, línea, precio > 0, presentación y categoría presentes",
            "duplicates": "registros adicionales por ID o clave semántica normalizada",
            "inferable": "valor explícito encontrado fuera del maestro; no significa fuente autorizada",
        },
        "clients": client_metrics,
        "products": product_metrics,
        "lines": line_metrics,
        "institutions": institution_metrics,
        "comodatos": comodato_metrics,
        "manifest": {"counts": expected_counts, "mismatches": manifest_mismatches},
        "sourceFiles": source_files,
    }


def _metrics_table(title: str, metrics: dict[str, Any]) -> str:
    percentages = metrics.get("percentages", {})
    rows = [f"## {title}", "", "| Métrica | Cantidad | Porcentaje |", "|---|---:|---:|"]
    for key, value in metrics.items():
        if key == "percentages":
            continue
        percentage = "—" if key == "total" else f"{percentages.get(key, 0):.2f}%"
        rows.append(f"| `{key}` | {value} | {percentage} |")
    return "\n".join(rows)


def render_markdown(report: dict[str, Any]) -> str:
    sections = [
        "# IA1 catalog quality report",
        "",
        f"Generado: `{report['generatedAt']}`",
        "",
        "Este informe es de solo lectura. No convierte prefijos incluidos en nombres de "
        "producto en códigos comerciales ni infiere precios, instituciones o comodatos.",
        "",
    ]
    for key, title in (
        ("clients", "Clientes"),
        ("products", "Productos"),
        ("lines", "Líneas"),
        ("institutions", "Instituciones"),
        ("comodatos", "Comodatos"),
    ):
        sections.extend([_metrics_table(title, report[key]), ""])
    sections.extend(
        [
            "## Integridad del manifiesto",
            "",
            f"Diferencias: `{json.dumps(report['manifest']['mismatches'], ensure_ascii=False)}`",
            "",
            "## Criterios",
            "",
            *[f"- `{key}`: {value}" for key, value in report["definitions"].items()],
            "",
        ]
    )
    return "\n".join(sections)


def write_reports(
    report: dict[str, Any], report_dir: Path = DEFAULT_REPORT_DIR
) -> tuple[Path, Path]:
    report_dir.mkdir(parents=True, exist_ok=True)
    json_path = report_dir / "catalog_quality_report.json"
    markdown_path = report_dir / "catalog_quality_report.md"
    json_path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    markdown_path.write_text(render_markdown(report), encoding="utf-8")
    return json_path, markdown_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog-dir", type=Path, default=DEFAULT_CATALOG_DIR)
    parser.add_argument("--report-dir", type=Path, default=DEFAULT_REPORT_DIR)
    args = parser.parse_args()
    report = build_report(args.catalog_dir)
    paths = write_reports(report, args.report_dir)
    print("\n".join(str(path) for path in paths))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
