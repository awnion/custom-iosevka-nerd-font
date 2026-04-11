# Release process

## Steps

1. **Bump version** - update the `VERSION` file (e.g. `0.0.17` to `0.0.18`)

2. **Create an RC branch** - branch name must match the version: `v0.0.18-rc`

3. **Open a PR** - the `pr.yaml` workflow runs automatically:
   - `rc-checks` validates that `VERSION` matches the branch name
   - `build-image` builds the Docker image (tagged with commit SHA)
   - `build-font` compiles the font inside the container
   - `visual-check` generates showcase PNGs and compares them pixel-by-pixel against reference images
   - `prerelease` creates a pre-release tag `v0.0.18-rc.{run_number}` and publishes artifacts to GitHub Releases

4. **Merge the PR into main** - the `release.yaml` workflow runs automatically:
   - Finds the RC pre-release matching the merge commit SHA
   - Downloads artifacts from the pre-release
   - Creates a final tag `v0.0.18` on the merge commit
   - Renames the ZIP to `afio-v0.0.18.zip` and publishes a GitHub Release
   - Re-tags the Docker image with the version and `latest`

No rebuild happens on merge. All artifacts are reused from the pre-release.

## Fork builds

A separate `fork-release.yaml` workflow handles forks. When `private-build-plans.toml` changes on `main` in a forked repo, it automatically builds the font and publishes a `latest` pre-release.
