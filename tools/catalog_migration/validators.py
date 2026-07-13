"""Validación explícita de los catálogos que consume Flutter."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Iterable

from schemas import SCHEMA_VERSION


class CatalogValidationError(ValueError):
    pass


def load_catalog(path: Path) -> list[dict[str, Any]]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CatalogValidationError(f"No se pudo leer {path.name}: {error}") from error
    if not isinstance(payload, dict) or not isinstance(payload.get("items"), list):
        raise CatalogValidationError(f"{path.name} debe contener un objeto con items.")
    if payload.get("schemaVersion") != SCHEMA_VERSION:
        raise CatalogValidationError(f"{path.name} tiene schemaVersion inválido.")
    source = payload.get("source")
    if not isinstance(source, str) or not source.strip():
        raise CatalogValidationError(f"{path.name} debe declarar source.")
    items = payload["items"]
    if not all(isinstance(item, dict) for item in items):
        raise CatalogValidationError(f"{path.name} contiene un item no estructurado.")
    return items


def require_unique(items: Iterable[dict[str, Any]], key: str, label: str) -> None:
    seen: set[str] = set()
    for item in items:
        value = item.get(key)
        if not isinstance(value, str) or not value.strip():
            raise CatalogValidationError(f"{label}: falta {key}.")
        normalized = value.casefold().strip()
        if normalized in seen:
            raise CatalogValidationError(f"{label}: {key} duplicado ({value}).")
        seen.add(normalized)


def require_text(items: Iterable[dict[str, Any]], key: str, label: str) -> None:
    for item in items:
        value = item.get(key)
        if not isinstance(value, str) or not value.strip():
            raise CatalogValidationError(f"{label}: falta {key}.")


def validate_catalog_directory(root: Path) -> dict[str, int]:
    clients = load_catalog(root / "clients.json")
    institutions = load_catalog(root / "institutions.json")
    lines = load_catalog(root / "commercial_lines.json")
    products = load_catalog(root / "products.json")
    comodatos = load_catalog(root / "comodatos.json")

    for label, items in (
        ("clients", clients),
        ("institutions", institutions),
        ("commercial_lines", lines),
        ("products", products),
        ("comodatos", comodatos),
    ):
        require_unique(items, "id", label)

    require_text(clients, "name", "clients")
    require_text(institutions, "name", "institutions")
    require_text(lines, "name", "commercial_lines")
    require_text(products, "name", "products")
    require_text(products, "lineId", "products")
    require_text(comodatos, "code", "comodatos")
    require_text(comodatos, "name", "comodatos")

    line_ids = {item["id"] for item in lines}
    client_ids = {item["id"] for item in clients}
    for product in products:
        if product.get("lineId") not in line_ids:
            raise CatalogValidationError(
                f"products: lineId invalido para {product.get('id', '<sin id>')}."
            )
    for comodato in comodatos:
        line_id = comodato.get("lineId")
        if line_id is not None and line_id not in line_ids:
            raise CatalogValidationError(
                f"comodatos: lineId invalido para {comodato.get('id', '<sin id>')}."
            )
        client_id = comodato.get("clientId")
        if client_id is not None and client_id not in client_ids:
            raise CatalogValidationError(
                f"comodatos: clientId invalido para {comodato.get('id', '<sin id>')}."
            )
        if "isGeneral" in comodato and not isinstance(comodato["isGeneral"], bool):
            raise CatalogValidationError(
                f"comodatos: isGeneral invalido para {comodato.get('id', '<sin id>')}."
            )

    return {
        "clients": len(clients),
        "institutions": len(institutions),
        "lines": len(lines),
        "products": len(products),
        "comodatos": len(comodatos),
    }
