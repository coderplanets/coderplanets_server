
we use
[standard-version](https://github.com/conventional-changelog/standard-version)
to handle project versioning, changelog generation and git tagging **without**
automatic pushing to Github.

### how it works

1. bumps the version in based on _package.json_ (according to commit history)
2. uses [conventional-changelog](https://github.com/conventional-changelog/conventional-changelog) to update _CHANGELOG.md_
3. tags a new release

### cmd
```text
  [valid release commands]
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  release        : release version by automatic CHANGELOG generation
                 | link: https://github.com/conventional-changelog/standard-version
                 | more:
                    | npm run release -- --prerelease
                    | npm run release -- --prerelease alpha
  .................................................................................
  release.master : release master branch
  .................................................................................
  release.dev    : release dev branch
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
> e.p: make release.master

