#!/usr/bin/env python3

import argparse
import re
import struct
import sys
import tomllib
from pathlib import Path


DEFAULT_FEATURES = ("cv42", "ss05")


def read_u16(data, offset):
    return struct.unpack_from(">H", data, offset)[0]


def table_slice(font_data, tag):
    if len(font_data) < 12:
        raise ValueError("file is too small to be a TrueType/OpenType font")

    num_tables = read_u16(font_data, 4)
    directory_end = 12 + num_tables * 16
    if len(font_data) < directory_end:
        raise ValueError("font table directory is truncated")

    for offset in range(12, directory_end, 16):
        table_tag = font_data[offset : offset + 4].decode("ascii", errors="replace")
        table_offset, table_length = struct.unpack_from(">II", font_data, offset + 8)
        if table_tag != tag:
            continue
        table_end = table_offset + table_length
        if table_end > len(font_data):
            raise ValueError(f"{tag} table is truncated")
        return font_data[table_offset:table_end]

    raise ValueError(f"{tag} table is missing")


def gsub_features(font_path):
    font_data = font_path.read_bytes()
    gsub = table_slice(font_data, "GSUB")

    if len(gsub) < 10:
        raise ValueError("GSUB table is truncated")

    major = read_u16(gsub, 0)
    feature_list_offset = read_u16(gsub, 6)
    if major != 1:
        raise ValueError(f"unsupported GSUB major version: {major}")
    if feature_list_offset + 2 > len(gsub):
        raise ValueError("GSUB feature list is truncated")

    feature_count = read_u16(gsub, feature_list_offset)
    records_start = feature_list_offset + 2
    records_end = records_start + feature_count * 6
    if records_end > len(gsub):
        raise ValueError("GSUB feature records are truncated")

    features = set()
    for offset in range(records_start, records_end, 6):
        features.add(gsub[offset : offset + 4].decode("ascii", errors="replace"))
    return features


def parse_args():
    parser = argparse.ArgumentParser(
        description="Verify TrueType/OpenType GSUB features against a build plan."
    )
    parser.add_argument("fonts", nargs="+", type=Path)
    parser.add_argument("--build-plan", type=Path, help="Iosevka build plan TOML file.")
    parser.add_argument("--plan", default="afio", help="Build plan key (default: afio).")
    parser.add_argument(
        "--feature",
        action="append",
        dest="features",
        default=[],
        help="Required GSUB feature tag. Defaults to cv42 and ss05 unless noCvSs=true.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    no_cv_ss = False
    if args.build_plan:
        try:
            with args.build_plan.open("rb") as source:
                plan = tomllib.load(source)["buildPlans"][args.plan]
            if not isinstance(plan, dict):
                raise ValueError(f"buildPlans.{args.plan} must be a table")
            no_cv_ss = plan.get("noCvSs", False)
            if not isinstance(no_cv_ss, bool):
                raise ValueError("noCvSs must be a boolean")
        except (OSError, ValueError, KeyError) as exc:
            print(f"{args.build_plan}: {exc}", file=sys.stderr)
            return 1
    required_features = set(args.features or (() if no_cv_ss else DEFAULT_FEATURES))
    failed = False

    for font in args.fonts:
        try:
            available_features = gsub_features(font)
        except Exception as exc:
            print(f"{font}: {exc}", file=sys.stderr)
            failed = True
            continue

        missing_features = sorted(required_features - available_features)
        if missing_features:
            print(
                f"{font}: missing GSUB feature(s): {', '.join(missing_features)}",
                file=sys.stderr,
            )
            failed = True

        if no_cv_ss:
            unexpected = sorted(
                tag for tag in available_features if re.fullmatch(r"(?:cv|ss)[0-9]{2}", tag)
            )
            if unexpected:
                print(
                    f"{font}: unexpected GSUB feature(s) with noCvSs=true: "
                    + ", ".join(unexpected),
                    file=sys.stderr,
                )
                failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
