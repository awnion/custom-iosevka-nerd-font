import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from zipfile import ZipFile


WRAPPER = Path(__file__).resolve().parents[1] / "src" / "nerd-patcher.py"


class PatcherTests(unittest.TestCase):
    def run_wrapper(self, patcher, inputs):
        temporary = tempfile.TemporaryDirectory(prefix="font patcher ")
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        output = root / "output"
        output.mkdir()
        fonts = root / "iosevka" / "dist" / "custom" / "TTF"
        fonts.mkdir(parents=True)
        for name in inputs:
            (fonts / name).write_bytes(b"test font")
        (root / "font-patcher").write_text(patcher)
        result = subprocess.run(
            [sys.executable, str(WRAPPER)],
            cwd=root,
            env={**os.environ, "BUILD_DIR": str(root), "OUTPUT_DIR": str(output),
                 "FONT_NAME": "custom"},
            capture_output=True, text=True,
        )
        return result, output

    def test_failed_patch_does_not_create_archive(self):
        result, output = self.run_wrapper(
            "print('patch failed', flush=True)\nraise SystemExit(23)\n", ["Regular.ttf"]
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(output.glob("*.zip")), [])
        self.assertIn("patch failed", (output / "patch.0.log").read_text())

    def test_no_inputs_does_not_create_archive(self):
        result, output = self.run_wrapper("raise SystemExit(99)\n", [])
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(output.glob("*.zip")), [])

    def test_success_with_spaces_in_paths(self):
        result, output = self.run_wrapper(
            "import pathlib, shutil, sys\n"
            "source = pathlib.Path(sys.argv[-1])\n"
            "destination = pathlib.Path(sys.argv[sys.argv.index('-out') + 1])\n"
            "shutil.copyfile(source, destination / source.name)\n",
            ["Regular font.ttf", "Bold.ttf"],
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        archives = list(output.glob("custom-*.zip"))
        self.assertEqual(len(archives), 1)
        with ZipFile(archives[0]) as archive:
            self.assertEqual(sorted(archive.namelist()), ["Bold.ttf", "Regular font.ttf"])


if __name__ == "__main__":
    unittest.main()
