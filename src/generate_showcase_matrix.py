#!/usr/bin/env python3
"""Generate light/dark showcase SVG matrices for every configured AFIO weight.

Usage:
    uv run src/generate_showcase_matrix.py

Optional arguments:
    uv run src/generate_showcase_matrix.py --output-dir docs/imgs/generated
    uv run src/generate_showcase_matrix.py --plan private-build-plans.toml --family afio
    uv run src/generate_showcase_matrix.py --png-scale 2
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tomllib
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_PLAN = ROOT / "private-build-plans.toml"
DEFAULT_TEMPLATE_DIR = ROOT / "docs" / "imgs"
DEFAULT_OUTPUT_DIR = DEFAULT_TEMPLATE_DIR / "generated"
DEFAULT_UV_CACHE_DIR = ROOT / ".uv-cache"
DEFAULT_XDG_CACHE_HOME = ROOT / ".cache"
DEFAULT_XDG_DATA_HOME = ROOT / ".local" / "share"

TEMPLATES = {
    "light": DEFAULT_TEMPLATE_DIR / "afio-showcase-light.svg",
    "dark": DEFAULT_TEMPLATE_DIR / "afio-showcase-dark.svg",
}


@dataclass(frozen=True)
class WeightSpec:
    name: str
    css: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate light/dark AFIO showcase SVGs for all configured font weights."
    )
    parser.add_argument(
        "--plan",
        type=Path,
        default=DEFAULT_PLAN,
        help=f"Path to build plan TOML. Default: {DEFAULT_PLAN}",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Directory for generated SVGs. Default: {DEFAULT_OUTPUT_DIR}",
    )
    parser.add_argument(
        "--family",
        default="afio",
        help="Build plan family to read from [buildPlans.<family>]. Default: afio",
    )
    parser.add_argument(
        "--png-scale",
        type=float,
        default=2.0,
        help="Scale factor for generated PNG previews. Default: 2.0",
    )
    return parser.parse_args()


def load_weights(plan_path: Path, family: str) -> list[WeightSpec]:
    with plan_path.open("rb") as handle:
        data = tomllib.load(handle)

    try:
        weights = data["buildPlans"][family]["weights"]
    except KeyError as exc:
        raise SystemExit(
            f"Could not find [buildPlans.{family}.weights] in {plan_path}"
        ) from exc

    specs: list[WeightSpec] = []
    for name, config in weights.items():
        css = config.get("css")
        if not isinstance(css, int):
            raise SystemExit(
                f"Weight '{name}' in {plan_path} does not define an integer css value"
            )
        specs.append(WeightSpec(name=name, css=css))

    specs.sort(key=lambda item: item.css)
    return specs


def harden_spaces(svg: str) -> str:
    """Replace regular spaces with non-breaking spaces inside <text>/<tspan> text content.

    This ensures consistent rendering across all SVG renderers, some of which
    collapse regular spaces even when xml:space="preserve" is set.
    """
    return re.sub(
        r"(<(?:text|tspan)[^>]*>)([^<]*)",
        lambda m: m.group(1) + m.group(2).replace(" ", "\u00a0"),
        svg,
    )


def patch_svg(svg: str, css_weight: int) -> str:
    svg, style_count = re.subn(
        r"(font-weight:\s*)\d+(;)",
        rf"\g<1>{css_weight}\2",
        svg,
        count=1,
    )
    if style_count != 1:
        raise ValueError("Could not patch the top-level font-weight in the SVG template")

    svg, text_count = re.subn(
        r'("editor\.fontWeight"</tspan><tspan class="fg">:\xa0</tspan><tspan class="string">")\d+(")',
        rf"\g<1>{css_weight}\2",
        svg,
        count=1,
    )
    if text_count != 1:
        raise ValueError("Could not patch the editor.fontWeight text in the SVG template")

    return svg


def render_png(svg_path: Path, png_path: Path, scale: float) -> None:
    rsvg_convert = shutil.which("rsvg-convert")
    if rsvg_convert:
        subprocess.run(
            [
                rsvg_convert,
                "--zoom",
                str(scale),
                str(svg_path),
                "-o",
                str(png_path),
            ],
            check=True,
        )
        return

    env = os.environ.copy()
    env.setdefault("UV_CACHE_DIR", str(DEFAULT_UV_CACHE_DIR))
    env.setdefault("XDG_CACHE_HOME", str(DEFAULT_XDG_CACHE_HOME))
    env.setdefault("XDG_DATA_HOME", str(DEFAULT_XDG_DATA_HOME))
    subprocess.run(
        [
            "uvx",
            "--from",
            "cairosvg",
            "cairosvg",
            "-s",
            str(scale),
            str(svg_path),
            "-o",
            str(png_path),
        ],
        check=True,
        env=env,
    )


def generate_showcase_matrix(
    weights: list[WeightSpec],
    output_dir: Path,
    png_scale: float,
) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    generated: list[Path] = []

    for theme, template_path in TEMPLATES.items():
        template = template_path.read_text(encoding="utf-8")
        for weight in weights:
            patched = harden_spaces(patch_svg(template, weight.css))
            svg_path = output_dir / f"afio-showcase-{theme}-{weight.css}.svg"
            png_path = output_dir / f"afio-showcase-{theme}-{weight.css}.png"
            svg_path.write_text(patched, encoding="utf-8")
            render_png(svg_path, png_path, png_scale)
            generated.extend([svg_path, png_path])

    return generated


def main() -> int:
    args = parse_args()
    weights = load_weights(args.plan, args.family)
    generated = generate_showcase_matrix(weights, args.output_dir.resolve(), args.png_scale)

    for path in generated:
        print(path.relative_to(ROOT))

    return 0


if __name__ == "__main__":
    sys.exit(main())
