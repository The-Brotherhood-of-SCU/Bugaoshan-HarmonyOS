"""Tests for release artifact preparation."""

import tempfile
import unittest
from pathlib import Path

import release_prepare


class ReleasePrepareTest(unittest.TestCase):
    def test_names_unsigned_hap_for_release(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            hap_dir = root / "ohos-hap"
            hap_dir.mkdir()
            (hap_dir / "entry-default-unsigned.hap").write_bytes(b"hap")

            result = release_prepare.prepare_release_files("v2.2.0", root=root)

            self.assertEqual(result, root / "bugaoshan_2.2.0_ohos_unsigned.hap")
            self.assertEqual(result.read_bytes(), b"hap")

    def test_requires_exactly_one_unsigned_hap(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            hap_dir = root / "ohos-hap"
            hap_dir.mkdir()

            with self.assertRaises(FileNotFoundError):
                release_prepare.prepare_release_files("v2.2.0", root=root)

            (hap_dir / "entry-default-unsigned.hap").write_bytes(b"first")
            (hap_dir / "widget-default-unsigned.hap").write_bytes(b"second")
            with self.assertRaises(FileNotFoundError):
                release_prepare.prepare_release_files("v2.2.0", root=root)


if __name__ == "__main__":
    unittest.main()
