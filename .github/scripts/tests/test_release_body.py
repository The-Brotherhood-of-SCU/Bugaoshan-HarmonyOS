import sys
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

from release_body import build_release_body


class ReleaseBodyTest(unittest.TestCase):
    def test_harmonyos_download_and_changelog(self):
        body = build_release_body(
            "v2.5.2",
            "https://github.com/example/bugaoshan",
            "- 修复课表问题",
            "v2.5.1",
        )

        self.assertIn("bugaoshan_2.5.2_ohos_unsigned.hap", body)
        self.assertIn("安装前需要自行签名", body)
        self.assertIn("- 修复课表问题", body)
        self.assertIn("/compare/v2.5.1...v2.5.2", body)

    def test_initial_release_uses_commit_as_comparison_base(self):
        body = build_release_body("v2.5.2", "https://example.com/repo", "Notes", "abc1234 (initial commit)")
        self.assertIn("/compare/abc1234...v2.5.2", body)


if __name__ == "__main__":
    unittest.main()
