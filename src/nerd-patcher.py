#!/usr/bin/env python3

import glob
import os
import subprocess
import sys

from datetime import date
from multiprocessing import Pool
from os import path, environ
from zipfile import ZipFile, ZIP_DEFLATED


def patch_fonts(index, ttf_file):
    output_dir = environ.get("OUTPUT_DIR", "/output")
    log_file = f"{output_dir}/patch.{index}.log"
    command = [
        sys.executable, "font-patcher", "-q",
        "-s",
        "-l",
        "-c",
        "--careful",
        "--makegroups", "-1",  # don't rename font
        ## optional
        # f'--fontawesome',
        # f'--fontawesomeextension',
        # f'--fontlinux',
        # f'--octicons',
        # f'--powersymbols',
        # f'--pomicons',
        # f'--powerline',
        # f'--powerlineextra',
        # f'--material',
        # f'--weather',
        "-out", output_dir, ttf_file,
    ]
    print("Run command:", command)
    with open(log_file, "a") as log:
        try:
            subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True)
        except subprocess.CalledProcessError as exc:
            raise RuntimeError(
                f"Patching {ttf_file} failed with exit code {exc.returncode}; see {log_file}"
            ) from exc
    print("Finish command:", command)


def main():
    build_dir = environ.get("BUILD_DIR", "/build")
    output_dir = environ.get("OUTPUT_DIR", "/output")
    font_name = environ.get("FONT_NAME", "afio")

    ttf_dir = path.join(build_dir, f"iosevka/dist/{font_name}/TTF")
    ttf_files = glob.glob(f"{ttf_dir}/*.ttf", recursive=True)
    if not ttf_files:
        raise RuntimeError(f"No TTF files found in {ttf_dir}")

    workers = int(environ.get("PATCH_JOBS", os.cpu_count() or 1))
    if workers < 1:
        raise ValueError("PATCH_JOBS must be positive")
    with Pool(min(workers, len(ttf_files))) as pool:
        pool.starmap(patch_fonts, enumerate(ttf_files))

    today = date.today().strftime("%Y-%m-%d")
    zip_filename = f"{output_dir}/{font_name}-{today}.zip"

    print("Make archive:", zip_filename)
    with ZipFile(
        zip_filename, "w", compression=ZIP_DEFLATED, compresslevel=6
    ) as archive:
        for filename in glob.glob(f"{output_dir}/*.ttf"):
            print(filename, "-->", zip_filename)
            archive.write(filename, path.basename(filename))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("...")
        print("KeyboardInterrupt detected")
        exit(1)
