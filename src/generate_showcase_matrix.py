#!/usr/bin/env python3
"""Generate light/dark showcase SVG matrices for every configured AFIO weight.

Renders PNGs inside a Docker container (debian:trixie-slim + librsvg) to ensure
identical output across macOS, Linux, and CI.

Usage:
    python3 src/generate_showcase_matrix.py --font-dir _output/fonts

Optional arguments:
    python3 src/generate_showcase_matrix.py --output-dir docs/imgs/generated
    python3 src/generate_showcase_matrix.py --plan private-build-plans.toml --family afio
    python3 src/generate_showcase_matrix.py --png-scale 2

Requires: docker
"""
from __future__ import annotations

import argparse
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

TEMPLATE = DEFAULT_TEMPLATE_DIR / "afio-showcase.svg"
DOCKER_IMAGE = "debian:trixie-slim"

THEMES: dict[str, dict[str, str]] = {
    "dark": {
        "TITLE": "AFIO dark theme showcase",
        "DESC": "Dark theme code showcase for JSON, Python, and Rust using the AFIO font.",
        "BG": "#23272c",
        "SEP": "#363a3e",
        "PANE_TITLE": "#808080",
        "LINE_NO": "#7f7f7f",
        "FG": "#a9b7c6",
        "COMMENT": "#808080",
        "KEY": "#bf93d8",
        "KW": "#db7e32",
        "STRING": "#7cb961",
        "NUMBER": "#9cc3ff",
        "TYPE": "#bf93d8",
        "DECOR": "#9cc3ff",
        "CALL": "#e5c07b",
        "FIELD": "#a9b7c6",
    },
    "light": {
        "TITLE": "AFIO light theme showcase",
        "DESC": "Light theme code showcase for JSON, Python, and Rust using the AFIO font.",
        "BG": "#ffffff",
        "SEP": "#e3e3e3",
        "PANE_TITLE": "#6a737d",
        "LINE_NO": "#c3c5cb",
        "FG": "#1a1a00",
        "COMMENT": "#6a737d",
        "KEY": "#d73a49",
        "KW": "#d73a49",
        "STRING": "#22863a",
        "NUMBER": "#005cc5",
        "TYPE": "#6f42c1",
        "DECOR": "#005cc5",
        "CALL": "#6f42c1",
        "FIELD": "#1a1a00",
    },
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
        "--font-dir",
        type=Path,
        required=True,
        help="Directory containing .ttf/.otf font files to install in the render container",
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


def apply_theme(svg: str, theme: dict[str, str]) -> str:
    for key, value in theme.items():
        svg = svg.replace(f"${key}$", value)
    return svg


def patch_weight(svg: str, css_weight: int) -> str:
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


def render_pngs(svg_paths: list[Path], scale: float, font_dir: Path) -> None:
    if not shutil.which("docker"):
        raise SystemExit("docker is required but not found")

    output_dir = svg_paths[0].parent

    render_cmds = " && ".join(
        f"rsvg-convert --zoom {scale} /work/{p.name} -o /work/{p.with_suffix('.png').name}"
        for p in svg_paths
    )

    subprocess.run(
        [
            "docker", "run", "--rm",
            "--platform", "linux/amd64",
            "-v", f"{output_dir.resolve()}:/work",
            "-v", f"{font_dir.resolve()}:/fonts:ro",
            DOCKER_IMAGE, "bash", "-c",
            "apt-get update -qq >/dev/null 2>&1 && "
            "apt-get install -yqq --no-install-recommends librsvg2-bin fontconfig >/dev/null 2>&1 && "
            "cp /fonts/*.ttf /fonts/*.otf /usr/local/share/fonts/ 2>/dev/null; "
            "fc-cache -f && "
            f"{render_cmds}",
        ],
        check=True,
    )


def generate_showcase_matrix(
    weights: list[WeightSpec],
    output_dir: Path,
    font_dir: Path,
    png_scale: float,
) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    generated: list[Path] = []
    template = TEMPLATE.read_text(encoding="utf-8")

    svg_paths: list[Path] = []
    for theme_name, theme_colors in THEMES.items():
        themed = apply_theme(template, theme_colors)
        for weight in weights:
            patched = patch_weight(themed, weight.css)
            svg_path = output_dir / f"afio-showcase-{theme_name}-{weight.css}.svg"
            png_path = output_dir / f"afio-showcase-{theme_name}-{weight.css}.png"
            svg_path.write_text(patched, encoding="utf-8")
            svg_paths.append(svg_path)
            generated.extend([svg_path, png_path])

    render_pngs(svg_paths, png_scale, font_dir)

    return generated


def main() -> int:
    args = parse_args()
    weights = load_weights(args.plan, args.family)
    generated = generate_showcase_matrix(
        weights, args.output_dir.resolve(), args.font_dir.resolve(), args.png_scale,
    )

    for path in generated:
        try:
            print(path.relative_to(ROOT))
        except ValueError:
            print(path)

    return 0


if __name__ == "__main__":
    sys.exit(main())
