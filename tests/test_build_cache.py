import os
from pathlib import Path
import subprocess
import tempfile
import unittest


BUILD_SCRIPT = Path(__file__).resolve().parents[1] / "build.sh"


class BuildCacheTests(unittest.TestCase):
    def test_dist_cache_is_reused_only_for_identical_plan_contents(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            docker = root / "docker"
            docker.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$DOCKER_ARGS"\n')
            docker.chmod(0o755)
            arguments = root / "arguments"
            # A leading dash must be treated as a filename, not a checksum option.
            plan = root / "-custom-plan.toml"
            env = {
                **os.environ,
                "PATH": f"{root}:{os.environ['PATH']}",
                "IMAGE_REF": "test-image",
                "BUILD_PLAN": plan.name,
                "VERDA_CACHE": str(root / "cache"),
                "DOCKER_ARGS": str(arguments),
            }

            def run_plan(contents):
                plan.write_text(contents)
                subprocess.run(["bash", str(BUILD_SCRIPT)], cwd=root, env=env,
                               check=True, capture_output=True, text=True)
                mounts = arguments.read_text().splitlines()
                return next(value.removesuffix(":/build/iosevka/dist")
                            for value in mounts if value.endswith(":/build/iosevka/dist"))

            first = run_plan('[buildPlans.afio.weights.Regular]\nshape = 400\n')
            # Simulate an output that must not leak after a plan changes.
            (Path(first) / "obsolete.ttf").touch()
            repeated = run_plan('[buildPlans.afio.weights.Regular]\nshape = 400\n')
            changed = run_plan('[buildPlans.afio.weights.Bold]\nshape = 700\n')
            self.assertEqual(first, repeated)
            self.assertNotEqual(first, changed)
            self.assertFalse((Path(changed) / "obsolete.ttf").exists())


if __name__ == "__main__":
    unittest.main()
