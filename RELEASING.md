# Releasing Tamatar

## 1. Publish the GitHub repo (first time)

```bash
gh repo create 101v/tamatar --public --source=. --remote=origin --push
```

If the remote already exists:

```bash
git remote add origin https://github.com/101v/tamatar.git
git push -u origin main
```

## 2. Tag a release

```bash
git tag -a v1.0.0 -m "Tamatar v1.0.0"
git push origin v1.0.0
gh release create v1.0.0 --title "v1.0.0" --notes "First Homebrew-ready release."
```

## 3. Point the Homebrew formula at the stable tag

```bash
curl -sL "https://github.com/101v/tamatar/archive/refs/tags/v1.0.0.tar.gz" | shasum -a 256
```

In `Formula/tamatar.rb`, uncomment the `url` / `sha256` lines and set the digest.
Homebrew infers the version from the tag in the URL.

Commit and push the formula update.

For later versions, bump both the `url` tag and the `sha256`.

## 4. Install via Homebrew

**From this repo (tap), before the first stable formula:**

```bash
brew tap 101v/tamatar https://github.com/101v/tamatar
brew install --HEAD tamatar
```

**After the stable `url` / `sha256` are set:**

```bash
brew tap 101v/tamatar https://github.com/101v/tamatar
brew install tamatar
```

**Local formula (development):**

```bash
brew install --HEAD --formula ./Formula/tamatar.rb
```

## 5. Optional: dedicated tap

Homebrew short taps use the `homebrew-*` naming convention. If you want
`brew tap 101v/tamatar` without a full URL, rename or mirror this formula into a
repo named `homebrew-tamatar` with `Formula/tamatar.rb` at the root.
