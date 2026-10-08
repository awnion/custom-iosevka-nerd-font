# Updating AFIO and its upstream inputs

Last upstream refresh: **2026-10-08** — Nerd Fonts **3.5.1**, Iosevka **34.9.0**, Bun **1.4.2**.

1. Check releases of [Iosevka](https://github.com/be5invis/Iosevka/releases), [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts/releases), and [Bun](https://github.com/oven-sh/bun/releases). Update Iosevka and Bun versions in the root `Dockerfile`; keep the custom design in `private-build-plans.toml`.
2. From the repository root, run `./nerd/download_glyphs.sh 3.5.1` (replace with the chosen Nerd Fonts version). This imports the official `FontPatcher.zip`: patcher, Python helpers, glyph names, and icon sets together. Keep upstream code unchanged; project-specific behavior belongs in `src/nerd-patcher.py`. This maintenance guide stays in `nerd/README.md`; the refresh replaces `nerd/glyphs/README.md` with the upstream documentation.
3. Build the local image with `docker buildx build --load -t afio-builder:local .`, then run `IMAGE_REF=afio-builder:local VERDA_CACHE=.verda-cache ./build.sh`. Check OpenType features with `python3 src/check_opentype_features.py --build-plan private-build-plans.toml _output/*.ttf` and generate previews with `python3 src/generate_showcase_matrix.py --font-dir _output`. Review visual changes before accepting new reference PNGs.
4. Keep bulk glyph/mapping updates in a separate commit from reviewable code and CI changes. Update the date and versions above. See [release instructions](../docs/RELEASING.md) for publishing.

The [icon-set inventory](glyphs/README.md) is supplied by Nerd Fonts; its individual versions follow that release, not necessarily each icon project's newest release.
