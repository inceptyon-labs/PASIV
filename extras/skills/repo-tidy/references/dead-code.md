# Dead files and clutter (Phase 10b)

Three parts: dead source files (removed when proven), unused assets and dependencies (report
only), and untracked clutter (kept out of the commit). Everything removed goes through `git rm`,
so the commit is the undo.

## 1. Dead source files

### 1a. Baseline build

Find the project's check command, in this order:
1. `verify.command` in `.pasiv.yml`
2. JS/TS: the `package.json` scripts `typecheck`, `check` (SvelteKit's `svelte-check`), `build`,
   then `test` if present, run with the lockfile's package manager (`pnpm`, `bun`, `yarn`, `npm`)
3. Swift package: `swift build`. Xcode project:
   `xcodebuild -scheme <scheme> -destination 'generic/platform=iOS Simulator' -quiet CODE_SIGNING_ALLOWED=NO build`
   (scheme from `xcodebuild -list -json`; use the macOS destination for Mac apps)
4. Flutter/Dart: `flutter analyze` (or `dart analyze`)
5. Rust/Tauri: `cargo check --all-targets` (in `src-tauri/` for Tauri, plus the JS check above)
6. Python: `pytest -q` if tests exist

Dependencies missing (`node_modules/` absent and so on): install with the frozen lockfile
(`npm ci`, `pnpm install --frozen-lockfile`, `bun install --frozen-lockfile`,
`yarn install --immutable`), which doesn't change the lockfile.

Run it **before deleting anything**. If it fails or no command exists, nothing is deleted in
this pass. Every candidate goes in the review list, and the summary says why.

### 1b. Find candidates with the stack's analyzer

Record each analyzer with `RUNLOG ran dead-code <rc> "<tool>"`. Exit 127 records as couldn't
run. Then fall back to the grep method in 1c and say so.

| Stack | Command | What it finds |
|-------|---------|---------------|
| JS/TS (React, Vite, Hono, SvelteKit, Workers) | `npx -y knip --no-progress` | unused files, dependencies, exports, unlisted deps. Exit 1 = issues |
| Swift | `periphery scan --strict --quiet --relative-results --format json` (uses `.periphery.yml` if present; otherwise add `--project <X>.xcodeproj --schemes <S>`; an SPM package needs neither). Add `--retain-public` for framework-only packages | unused declarations. A file is dead only if every top-level declaration in it is reported. Install: `brew install periphery`. Builds the project, so it's slow |
| Python | `uvx vulture <src dirs> --min-confidence 80 --exclude .venv,venv,node_modules,build,dist` | unused functions, classes, variables (not files) |
| Rust | `cargo machete` (`cargo install cargo-machete`) | unused crate dependencies |
| Flutter/Dart, Rust files, Python modules, anything else | grep method in 1c | unreferenced files |

### 1c. Grep method (also the cross-check for every analyzer hit)

A file is a candidate when nothing imports it:
- Dart: `git grep -n -E "(import|export|part) ['\"][^'\"]*<file name>['\"]"` finds nothing
- Rust: no `mod <name>;` in the parent module (the compiler never sees the file, so
  `cargo check` stays quiet about it)
- Python: no `import <module>` or `from <pkg>.<module>`, and it isn't an entry point
- Swift without Periphery: list only (extensions, previews and `@main` make grep unreliable)

knip's most common false positive is a server or worker entry it doesn't know about (started from
a `package.json` script or a Dockerfile `CMD`, e.g. `tsx server/index.ts`). That entry and
everything it imports show up as "unused files". The cross-check below catches them. Also
list "add `entry` to knip config" as a follow-up.

Before any candidate counts, also run `git grep -n -F '<basename without extension>'`
across the whole repo. A hit in a config file, route table, storyboard, Info.plist,
Dockerfile, compose file, workflow, script, `package.json` or docs means it's used dynamically
or by tooling. Drop it from the candidates.

### 1d. Never delete

- Entry points and framework conventions: `main.*`, `index.*` at a package root, `App.swift` /
  `@main`, `AppDelegate`, `SceneDelegate`, app extensions, `lib/main*.dart`,
  `src-tauri/src/{main,lib}.rs`, `build.rs`, `src/bin/*`, SvelteKit `+page`/`+layout`/`+server`/
  `+error` and `hooks.*`, file-based routes (`routes/`, `pages/`, `app/`), the Worker `main` in
  `wrangler.toml`, service workers, `vite.config.*` and other tool configs
- Database migrations (`migrations/`, `drizzle/`), seeds, fixtures, snapshots, test files and
  test helpers
- Generated code (`*.g.dart`, `*.freezed.dart`, `firebase_options.dart`,
  `generated_plugin_registrant.*`, `*.pb.*`, anything under `generated/`), `*.d.ts` in `types/`
- Anything AGENTS.md says not to touch, and files changed in the last 14 days (likely in-progress
  work): `git log -1 --format=%cr -- <file>`
- Swift files listed in `project.pbxproj` (`grep -F '<file name>' *.xcodeproj/project.pbxproj`).
  Deleting them leaves a dangling project reference. List them; removal is an Xcode edit.
  Folder-synchronized groups (Xcode 16+) and XcodeGen projects have no per-file entries, so
  those files are fine

### 1e. Remove and verify

1. `git rm` every candidate that survived 1c and 1d, as one batch.
2. Rerun the baseline command.
3. Passes → keep the deletions. Fails → `git restore --staged --worktree -- <files>` to bring
   the batch back, then retry by halves to find the file the build needs. Keep the deletions
   that pass and move the rest to the review list. Stop bisecting after three rounds and restore
   anything left.
4. Unused exports, unused declarations inside live files, and vulture hits are **report only**.
   Editing inside files is a refactor, not a tidy.

## 2. Unused dependencies and assets (report only)

- **Dependencies:** knip's dependencies/unlisted sections, `cargo machete`. List them; don't edit
  manifests or lockfiles. Runtime-only packages (CLI tools used in scripts, plugins named in
  config files) cause false positives, and removal is a separate change.
- **Assets:** images, fonts, audio, and video under `assets/`, `public/`, `static/`,
  `src/assets/`, Flutter assets declared in `pubspec.yaml`, and `Assets.xcassets/*.imageset` /
  `*.colorset` (match on the set name). For each, `git grep -n -F '<name without extension>'`
  across source, HTML, CSS, config, `Info.plist`, `pubspec.yaml`, manifests and docs. No hit → list it.
  Never delete assets. Dynamic names (`Image("level\(n)")`, `` `/img/${slug}.png` ``) only fail at
  runtime, and `public/` files can be linked from outside the repo. Always skip app icons,
  favicons, `apple-touch-icon*`, `og-image*`, `unraid-icon.png`, logos, `robots.txt`, and manifest icons.

Record with `RUNLOG done unused-assets "<n assets, n deps listed>"`.

## 3. Untracked clutter

The final `/acp` runs `git add -A`, so anything untracked gets committed. Check it here:

```bash
git status --porcelain --untracked-files=all | grep '^??'
```

- **Junk patterns** (`*.log`, `*.tmp`, `*.swp`, `*~`, `*.orig`, `*.rej`, `*.bak`, `.DS_Store`,
  `Screenshot*.png`, `Screen Recording*`, `*.xcresult`, `coverage/`, `*.profraw`, `tmp/`,
  `scratch/`, stray `*.zip` or `*.tar.gz`): add the pattern to `.gitignore` so the commit skips
  them. Never delete untracked files. They're not in git, so there's no undo.
- **Large files** (over 5 MB) and **untracked source files** (`.swift`, `.ts`, `.dart`, `.rs`,
  `.py`, ...) that look like someone's work: ask with AskUserQuestion before the commit:
  commit them, gitignore them, or leave them for the user to handle.

Record with `RUNLOG done clutter "<n patterns ignored, n asked>"`.

Under `--report`: run the analyzers and the baseline build, list what would be removed,
ignored, and asked, and change nothing.

## Summary lines

- `**Removed (dead code):** src/legacy/OldChart.tsx, lib/utils/unused_helper.dart (build passed)`
- Follow-up: `Unused (review): 2 files (kept: build broke / in pbxproj), 6 exports, 3 deps, 4 assets`
- `**Ignored:** *.log, Screenshot*.png (untracked clutter)`
