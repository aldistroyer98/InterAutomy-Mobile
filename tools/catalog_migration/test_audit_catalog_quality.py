from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.catalog_migration.audit_catalog_quality import (
    DEFAULT_CATALOG_DIR,
    build_report,
    write_reports,
)


class CatalogQualityAuditTest(unittest.TestCase):
    def test_real_ia1_report_is_explicit_about_missing_execution_data(self) -> None:
        report = build_report(DEFAULT_CATALOG_DIR)

        self.assertEqual(report["clients"]["total"], 3128)
        self.assertEqual(report["products"]["total"], 8838)
        self.assertEqual(report["lines"]["total"], 62)
        self.assertEqual(report["products"]["readyForOrder"], 8838)
        self.assertEqual(report["products"]["readyForExecution"], 0)
        self.assertEqual(report["products"]["withPrice"], 0)
        self.assertEqual(report["products"]["withCommercialCode"], 0)
        self.assertEqual(report["institutions"]["total"], 0)
        self.assertEqual(report["comodatos"]["total"], 0)
        self.assertEqual(report["manifest"]["mismatches"], {})

    def test_writes_both_machine_and_human_readable_reports(self) -> None:
        report = build_report(DEFAULT_CATALOG_DIR)
        with tempfile.TemporaryDirectory() as temporary:
            json_path, markdown_path = write_reports(report, Path(temporary))
            self.assertTrue(json_path.is_file())
            self.assertTrue(markdown_path.is_file())
            self.assertIn("readyForExecution", json_path.read_text(encoding="utf-8"))
            self.assertIn("## Productos", markdown_path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
