# Release process

## Steps

1. **Bump version** - update the `VERSION` file (e.g. `0.0.17` to `0.0.18`)

2. **Create an RC branch** - branch name must match the version: `v0.0.18-rc`

3. **Open a PR** - the `pr.yaml` workflow runs automatically:
   - `rc-checks` validates that `VERSION` matches the branch name
   - `build-font` builds the Docker image (tagged with commit SHA) and compiles the font inside it
   - `visual-check` generates showcase PNGs and compares them pixel-by-pixel against reference images
   - `prerelease` creates a pre-release tag `v0.0.18-rc.{run_number}` and publishes artifacts to GitHub Releases

4. **Merge the PR into main** - the `release.yaml` workflow runs automatically:
   - Finds the RC pre-release matching the PR head commit SHA
   - Downloads artifacts from the pre-release
   - Creates a final tag `v0.0.18` on the merge commit
   - Renames the ZIP to `afio-0.0.18.zip` and publishes a GitHub Release
   - Re-tags the Docker image with the version and `latest`

No rebuild happens on merge. All artifacts are reused from the pre-release.

## Release notes

The PR body is used as release notes throughout the pipeline:

1. The `prerelease` job takes the PR body and passes it as `--notes` to `gh release create`
2. When the PR is merged, the `release` job reads the body from the pre-release via `gh release view` and copies it into the final release via `--notes-file`

**PR body -> pre-release notes -> release notes.** Write the changelog in the PR description.

## Fork builds

Every push to `main` in a fork runs `fork-release.yaml` and publishes a numbered build (e.g. `build-42.1`) marked **Latest**, with `afio-latest.zip` attached. Edit the config in GitHub and commit to `main`; no PR or registry setup is needed. Enable Actions in the fork if prompted. The original repository skips this workflow.
