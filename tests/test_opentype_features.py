from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest


CHECKER = Path(__file__).resolve().parents[1] / "src" / "check_opentype_features.py"


class OpenTypeFeatureTests(unittest.TestCase):
    def check(self, features, setting, *options, plan_contents=None):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            # Minimal sfnt containing the GSUB feature records consumed by the checker.
            records = b"".join(tag.encode("ascii") + b"\0\0" for tag in features)
            gsub = struct.pack(">5H", 1, 0, 0, 10, 0) + struct.pack(">H", len(features)) + records
            font = root / "font.ttf"
            font.write_bytes(
                struct.pack(">I4H", 0x10000, 1, 0, 0, 0)
                + struct.pack(">4sIII", b"GSUB", 0, 28, len(gsub)) + gsub
            )
            plan = root / "plan.toml"
            plan.write_text(plan_contents if plan_contents is not None
                            else f"[buildPlans.custom]\n{setting}\n")
            return subprocess.run(
                [sys.executable, str(CHECKER), "--build-plan", str(plan),
                 "--plan", "custom", *options, str(font)],
                capture_output=True, text=True,
            )

    def test_disabled_variants_allow_ligatures(self):
        result = self.check(["calt", "liga"], "noCvSs = true")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_disabled_variants_reject_any_cv_or_ss_tag(self):
        for tag in ["cv01", "ss20"]:
            with self.subTest(tag=tag):
                result = self.check(["calt", tag], "noCvSs = true")
                self.assertEqual(result.returncode, 1)
                self.assertIn(f"unexpected GSUB feature(s) with noCvSs=true: {tag}", result.stderr)

    def test_enabled_variants_require_default_tags(self):
        for setting in ["noCvSs = false", ""]:
            with self.subTest(setting=setting):
                result = self.check(["cv42", "ss05"], setting)
                self.assertEqual(result.returncode, 0, result.stderr)
                result = self.check(["cv42"], setting)
                self.assertEqual(result.returncode, 1)
                self.assertIn("missing GSUB feature(s): ss05", result.stderr)

    def test_explicit_required_features_still_checked(self):
        result = self.check(["calt"], "noCvSs = true", "--feature", "liga")
        self.assertEqual(result.returncode, 1)
        self.assertIn("missing GSUB feature(s): liga", result.stderr)

    def test_invalid_plan_fails(self):
        result = self.check([], 'noCvSs = "true"')
        self.assertEqual(result.returncode, 1)
        self.assertIn("noCvSs must be a boolean", result.stderr)

    def test_selected_plan_must_be_a_table(self):
        result = self.check([], "", plan_contents="[buildPlans]\ncustom = true\n")
        self.assertEqual(result.returncode, 1)
        self.assertIn("buildPlans.custom must be a table", result.stderr)
        self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
